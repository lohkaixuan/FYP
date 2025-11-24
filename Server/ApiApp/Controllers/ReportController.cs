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

    // ============================================================
    // POST /api/report/monthly/generate
    // ============================================================
    [HttpPost("monthly/generate")]
    public async Task<IActionResult> Generate([FromBody] MonthlyReportRequest req, CancellationToken ct)
    {
        try
        {
            // 🔐 caller role (from JWT)
            var callerRole = User.FindFirstValue(ClaimTypes.Role) ?? "user";
            if (!IsAllowedToGenerate(callerRole, req.Role))
                return Forbid();

            static Guid? TryGuid(string? v) => Guid.TryParse(v, out var g) ? g : null;

            // 🔥 Unified subject — ALWAYS use NameIdentifier first
            var subject = User.FindFirstValue(ClaimTypes.NameIdentifier)
                        ?? User.FindFirstValue("sub");

            var subjectGuid = TryGuid(subject);

            // --------------------------------------------
            // Auto-scope for missing fields
            // --------------------------------------------

            // user report
            if (req.Role.Equals("user", StringComparison.OrdinalIgnoreCase) && req.UserId is null)
                req = req with { UserId = subjectGuid };

            // merchant report
            if (req.Role.Equals("merchant", StringComparison.OrdinalIgnoreCase) && req.MerchantId is null)
            {
                var merchantId =
                    TryGuid(User.FindFirstValue("merchant_id")) ??
                    subjectGuid;
                req = req with { MerchantId = merchantId };
            }

            // third-party provider report
            if (req.Role.Equals("thirdparty", StringComparison.OrdinalIgnoreCase) && req.ProviderId is null)
            {
                var providerId =
                    TryGuid(User.FindFirstValue("provider_id")) ??
                    subjectGuid;
                req = req with { ProviderId = providerId };
            }

            // --------------------------------------------
            // DB operations
            // --------------------------------------------
            await using var conn = await _ds.OpenConnectionAsync(ct);
            await using var tx = await conn.BeginTransactionAsync(ct);

            // 1) Build chart (Neon)
            var chart = await _repo.BuildMonthlyChartAsync(conn, req, ct);

            // 2) Render PDF
            var pdfBytes = _pdf.Render(chart, req.Role, req.Month);

            // 3) Save (Neon)
            var createdBy = subjectGuid;
            var reportId = await _repo.UpsertReportAndFileAsync(
                conn, req, chart, pdfBytes, createdBy, ct);

            await tx.CommitAsync(ct);

            // 4) Return URL
            var url = Url.Content($"/api/report/{reportId}/download")!;
            return Ok(new MonthlyReportResponse(reportId, req.Role, req.Month, url));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                ok = false,
                message = "Report generate failed",
                error = ex.Message,
                detail = ex.ToString()
            });
        }
    }

    // ============================================================
    // GET /api/report/{id}/download
    // ============================================================
    [HttpGet("{id:guid}/download")]
    public async Task<IActionResult> Download([FromRoute] Guid id, CancellationToken ct)
    {
        try
        {
            await using var conn = await _ds.OpenConnectionAsync(ct);
            var file = await _repo.GetPdfAsync(conn, id, ct);
            if (file is null) return NotFound();

            var (contentType, bytes, createdBy, reportRole) = file.Value;

            // 🔐 Caller identity
            var callerRole = User.FindFirstValue(ClaimTypes.Role) ?? "user";
            var callerIdStr =
                User.FindFirstValue(ClaimTypes.NameIdentifier) ??
                User.FindFirstValue("sub");

            Guid? callerId = Guid.TryParse(callerIdStr, out var g) ? g : null;

            // admin = full access
            if (!callerRole.Equals("admin", StringComparison.OrdinalIgnoreCase))
            {
                // 1) Must be same owner
                if (!callerId.HasValue || createdBy is null || callerId.Value != createdBy.Value)
                    return Forbid();

                // 2) Role must match
                if (!callerRole.Equals(reportRole, StringComparison.OrdinalIgnoreCase))
                    return Forbid();
            }

            return File(bytes, contentType, $"report-{id}.pdf");
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                ok = false,
                message = "Report download failed",
                error = ex.Message,
                detail = ex.ToString()
            });
        }
    }

    // ============================================================
    // RULE: which role can generate which report
    // ============================================================
    private static bool IsAllowedToGenerate(string callerRole, string requestedRole) =>
        callerRole.ToLowerInvariant() switch
        {
            "admin"      => true, // admin can generate everything
            "merchant"   => requestedRole.Equals("merchant", StringComparison.OrdinalIgnoreCase),
            "user"       => requestedRole.Equals("user", StringComparison.OrdinalIgnoreCase),
            "thirdparty" => requestedRole.Equals("thirdparty", StringComparison.OrdinalIgnoreCase),
            _            => false
        };
}
