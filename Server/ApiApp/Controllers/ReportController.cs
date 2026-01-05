// ==================================================
// Program Name   : ReportController.cs
// Purpose        : API endpoints for generating and retrieving reports
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Npgsql;
using Dapper;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/report")]
[Authorize]
public class ReportController : ControllerBase
{
    private readonly NpgsqlDataSource _ds;
    private readonly IReportRepository _repo;
    private readonly PdfRenderer _pdf;
    private const int MIN_DAYS_AFTER_MONTH_END = 3;
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
        try
        {
            var callerRole = User.FindFirstValue(ClaimTypes.Role) ?? "user";
            if (!IsAllowedToGenerate(callerRole, req.Role))
                return Forbid();
            static Guid? TryGuid(string? v) => Guid.TryParse(v, out var g) ? g : null;
            var subject = User.FindFirstValue(ClaimTypes.NameIdentifier)
                        ?? User.FindFirstValue("sub");
            var subjectGuid = TryGuid(subject);

            if (req.Role.Equals("user", StringComparison.OrdinalIgnoreCase) && req.UserId is null)
                req = req with { UserId = subjectGuid };
            if (req.Role.Equals("merchant", StringComparison.OrdinalIgnoreCase) && req.MerchantId is null)
            {
                var merchantId =
                    TryGuid(User.FindFirstValue("merchant_id")) ??
                    subjectGuid;
                req = req with { MerchantId = merchantId };
            }

            if (req.Role.Equals("thirdparty", StringComparison.OrdinalIgnoreCase) && req.ProviderId is null)
            {
                var providerId =
                    TryGuid(User.FindFirstValue("provider_id")) ??
                    subjectGuid;
                req = req with { ProviderId = providerId };
            }

            var roleKey = req.Role.ToLowerInvariant();
            var monthKey = new DateTime(req.Month.Year, req.Month.Month, 1); 
            await using var conn = await _ds.OpenConnectionAsync(ct);
            var existingReport = await conn.QuerySingleOrDefaultAsync<dynamic>(
                @"select id, pdf_url
                  from reports
                  where role = @role
                    and month = @month
                    and created_by is not distinct from @createdBy
                  limit 1;",
                new
                {
                    role = roleKey,
                    month = monthKey,
                    createdBy = (Guid?)subjectGuid
                });

            if (existingReport is not null)
            {
                Guid existingId = existingReport.id;
                string existingUrl = existingReport.pdf_url; 
                if (string.IsNullOrEmpty(existingUrl))
                    existingUrl = Url.Content($"/api/report/{existingId}/download")!;

                var existingRes = new MonthlyReportResponse(existingId, req.Role, req.Month, existingUrl);
                return Ok(existingRes);
            }
            var firstDayOfMonth = new DateOnly(req.Month.Year, req.Month.Month, 1);
            var firstDayOfNextMonth = firstDayOfMonth.AddMonths(1);
            var earliestGenerateDate = firstDayOfNextMonth.AddDays(MIN_DAYS_AFTER_MONTH_END);
            var today = DateOnly.FromDateTime(DateTime.UtcNow); 
            await using var tx = await conn.BeginTransactionAsync(ct);
            var chart = await _repo.BuildMonthlyChartAsync(conn, req, ct);
            var pdfBytes = _pdf.Render(chart, req.Role, req.Month);
            var createdBy = subjectGuid;
            var tempUrl = Url.Content("/api/report/pending/download")!
                          ?? "/api/report/pending/download";
            var upsert = await _repo.UpsertReportAndFileAsync(
                conn, req, chart, pdfBytes, createdBy, tempUrl, ct);
            var finalUrl = upsert.StoredInS3
                ? upsert.PdfUrl
                : Url.Content($"/api/report/{upsert.ReportId}/download")
                  ?? $"/api/report/{upsert.ReportId}/download";
            if (!upsert.StoredInS3 &&
                !string.Equals(upsert.PdfUrl, finalUrl, StringComparison.Ordinal))
            {
                await _repo.UpdatePdfUrlAsync(conn, upsert.ReportId, finalUrl, ct);
            }
            await tx.CommitAsync(ct);
            return Ok(new MonthlyReportResponse(upsert.ReportId, req.Role, req.Month, finalUrl));
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

    // GET /api/report/{id}/download
    [HttpGet("{id:guid}/download")]
    public async Task<IActionResult> Download([FromRoute] Guid id, CancellationToken ct)
    {
        try
        {
            await using var conn = await _ds.OpenConnectionAsync(ct);
            var file = await _repo.GetPdfAsync(conn, id, ct);
            if (file is null) return NotFound();
            var (contentType, bytes, createdBy, reportRole) = file.Value;
            var callerRole = User.FindFirstValue(ClaimTypes.Role) ?? "user";
            var callerIdStr =
                User.FindFirstValue(ClaimTypes.NameIdentifier) ??
                User.FindFirstValue("sub");
            Guid? callerId = Guid.TryParse(callerIdStr, out var g) ? g : null;
            if (!callerRole.Equals("admin", StringComparison.OrdinalIgnoreCase))
            {
                if (!callerId.HasValue || createdBy is null || callerId.Value != createdBy.Value)
                    return Forbid();

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

    // RULE: which role can generate which report
    private static bool IsAllowedToGenerate(string callerRole, string requestedRole) =>
        callerRole.ToLowerInvariant() switch
        {
            "admin"      => true, 
            "merchant"   => requestedRole.Equals("merchant", StringComparison.OrdinalIgnoreCase),
            "user"       => requestedRole.Equals("user", StringComparison.OrdinalIgnoreCase),
            "thirdparty" => requestedRole.Equals("thirdparty", StringComparison.OrdinalIgnoreCase),
            _            => false
        };
}
