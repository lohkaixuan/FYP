// File: Server/ApiApp/Controllers/ReportController.cs
using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/report")]
[Authorize]
public class ReportController : ControllerBase
{
    private readonly NpgsqlDataSource _ds;
    private readonly IReportRepository _repo;
    private readonly PdfRenderer _pdf;

    public ReportController(NpgsqlDataSource ds, IReportRepository repo, PdfRenderer pdf)
    {
        _ds = ds;
        _repo = repo;
        _pdf = pdf;
    }

    // POST /api/report/monthly/generate
    [HttpPost("monthly/generate")]
    public async Task<IActionResult> Generate([FromBody] MonthlyReportRequest req, CancellationToken ct)
    {
        // 🔐 role from JWT
        var callerRole = User.FindFirstValue(ClaimTypes.Role) ?? "user";
        if (!IsAllowedToGenerate(callerRole, req.Role))
            return Forbid();

        // ---- Auto-scope by claims if missing ----
        static Guid? TryGuid(string? v) => Guid.TryParse(v, out var g) ? g : null;

        // normal user monthly report
        if (req.Role.Equals("user", StringComparison.OrdinalIgnoreCase) && req.UserId is null)
            req = req with { UserId = TryGuid(User.FindFirstValue("sub")) };

        // merchant monthly report
        if (req.Role.Equals("merchant", StringComparison.OrdinalIgnoreCase) && req.MerchantId is null)
        {
            var merchantId = TryGuid(User.FindFirstValue("merchant_id")) ?? TryGuid(User.FindFirstValue("sub"));
            req = req with { MerchantId = merchantId };
        }

        // third-party provider monthly report
        if (req.Role.Equals("thirdparty", StringComparison.OrdinalIgnoreCase) && req.ProviderId is null)
        {
            var providerId = TryGuid(User.FindFirstValue("provider_id")) ?? TryGuid(User.FindFirstValue("sub"));
            req = req with { ProviderId = providerId };
        }

        await using var conn = await _ds.OpenConnectionAsync(ct);
        await using var tx = await conn.BeginTransactionAsync(ct);

        // 1) build chart from Neon
        var chart = await _repo.BuildMonthlyChartAsync(conn, req, ct);

        // 2) render PDF
        var pdfBytes = _pdf.Render(chart, req.Role, req.Month);

        // 3) save metadata + file (Neon)
        var createdBy = TryGuid(User.FindFirstValue("sub"));
        var reportId = await _repo.UpsertReportAndFileAsync(conn, req, chart, pdfBytes, createdBy, ct);

        await tx.CommitAsync(ct);

        // 4) return download url
        var url = Url.Content($"/api/report/{reportId}/download")!;
        var res = new MonthlyReportResponse(reportId, req.Role, req.Month, url);
        return Ok(res);
    }

    // GET /api/report/{id}/download
    [HttpGet("{id:guid}/download")]
    public async Task<IActionResult> Download([FromRoute] Guid id, CancellationToken ct)
    {
        await using var conn = await _ds.OpenConnectionAsync(ct);
        var file = await _repo.GetPdfAsync(conn, id, ct);
        if (file is null) return NotFound();

        var (contentType, bytes, createdBy, reportRole) = file.Value;

        // 🔐 caller info
        var callerRole = User.FindFirstValue(ClaimTypes.Role) ?? "user";
        var callerIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        Guid? callerId = Guid.TryParse(callerIdStr, out var g) ? g : null;

        // admin can download everything
        if (!callerRole.Equals("admin", StringComparison.OrdinalIgnoreCase))
        {
            // 1) must be same owner
            if (!callerId.HasValue || createdBy is null || callerId.Value != createdBy.Value)
                return Forbid();

            // 2) role must match report role (user ↔ user, merchant ↔ merchant, etc.)
            if (!callerRole.Equals(reportRole, StringComparison.OrdinalIgnoreCase))
                return Forbid();
        }

        return File(bytes, contentType, $"report-{id}.pdf");
    }

    // 简单权限规则：谁可以生成哪种 role 的报表
    private static bool IsAllowedToGenerate(string callerRole, string requestedRole) =>
        callerRole.ToLowerInvariant() switch
        {
            "admin"      => true, // admin 可帮所有角色生成
            "merchant"   => requestedRole.Equals("merchant", StringComparison.OrdinalIgnoreCase),
            "user"       => requestedRole.Equals("user", StringComparison.OrdinalIgnoreCase),
            "thirdparty" => requestedRole.Equals("thirdparty", StringComparison.OrdinalIgnoreCase),
            _            => false
        };
}
