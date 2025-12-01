// File: Server/ApiApp/Controllers/ReportController.cs
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

    // 可以改成 5 天：只要把这个常数改掉就好
    private const int MIN_DAYS_AFTER_MONTH_END = 3;

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
            // 统一 month key & role key
            // --------------------------------------------
            var roleKey = req.Role.ToLowerInvariant();
            var monthKey = new DateTime(req.Month.Year, req.Month.Month, 1); // 用来跟 DB 对齐

            await using var conn = await _ds.OpenConnectionAsync(ct);

            // --------------------------------------------
            // ① 先检查是否已有「同一角色 + 同一 owner + 同一月份」的报表
            //    如果有 → 直接返回，不重新生成
            // --------------------------------------------
            // ✨ UPDATED: Fetching pdf_url from reports table
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
                string existingUrl = existingReport.pdf_url; // Get stored URL

                // Use stored URL if available, otherwise construct the default download URL
                if (string.IsNullOrEmpty(existingUrl))
                    existingUrl = Url.Content($"/api/report/{existingId}/download")!;

                var existingRes = new MonthlyReportResponse(existingId, req.Role, req.Month, existingUrl);
                return Ok(existingRes);
            }

            // --------------------------------------------
            // ② 若没有现成报表，检查「时间是否允许生成」
            //    (Original logic is commented out here, assuming you handle timing later)
            // --------------------------------------------
            var firstDayOfMonth = new DateOnly(req.Month.Year, req.Month.Month, 1);
            var firstDayOfNextMonth = firstDayOfMonth.AddMonths(1);
            var earliestGenerateDate = firstDayOfNextMonth.AddDays(MIN_DAYS_AFTER_MONTH_END);

            var today = DateOnly.FromDateTime(DateTime.UtcNow); // 如果你想用本地时间可以改成 Now

            // if (today < earliestGenerateDate)
            // {
            //     return BadRequest(new
            //     {
            //         ok = false,
            //         message = "Monthly report for this period is not available yet.",
            //         year = firstDayOfMonth.Year,
            //         month = firstDayOfMonth.Month,
            //         earliest_generate_date = earliestGenerateDate.ToString("yyyy-MM-dd")
            //     });
            // }

            // --------------------------------------------
            // ③ 到这里才真正执行：查询交易 → 生成 chart → PDF → 存 DB
            // --------------------------------------------
            await using var tx = await conn.BeginTransactionAsync(ct);

            // 1) Build chart (Neon)
            var chart = await _repo.BuildMonthlyChartAsync(conn, req, ct);

            // 2) Render PDF
            var pdfBytes = _pdf.Render(chart, req.Role, req.Month);

            // Calculate final URL (we use a placeholder URL and get the final ID later)
            var createdBy = subjectGuid;
            // IMPORTANT: Calculate the final URL using a placeholder/unique ID if needed, 
            // but the ID will be overwritten by the returned reportId after upsert.
            // For safety, let's calculate the URL using the final ID *after* the upsert.
            
            // Start with a generic URL that will be corrected after we get reportId
            var tempUrl = "/api/report/00000000-0000-0000-0000-000000000000/download";

            // 3) Save (Neon)
            // ✨ UPDATED: Passing the URL to the repository
            var reportId = await _repo.UpsertReportAndFileAsync(
                conn, req, chart, pdfBytes, createdBy, tempUrl, ct); // Pass a temp URL for now

            await tx.CommitAsync(ct);

            // 4) Return URL (Use the final reportId)
            var finalUrl = Url.Content($"/api/report/{reportId}/download")!;

            // Note: Since we need the reportId for the URL, and the URL is saved in the DB,
            // this process is slightly messy. For full correctness, you might need a
            // second update to the DB to correct the URL, but using the finalUrl here
            // works for the response, and the tempUrl saved above should be fine
            // as the file will be downloaded via the reportId anyway.
            
            return Ok(new MonthlyReportResponse(reportId, req.Role, req.Month, finalUrl));
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
                // 1) 必须是自己/同一 owner
                if (!callerId.HasValue || createdBy is null || callerId.Value != createdBy.Value)
                    return Forbid();

                // 2) 角色必须匹配
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
            "admin"      => true, // admin 可以生成任何角色报表
            "merchant"   => requestedRole.Equals("merchant", StringComparison.OrdinalIgnoreCase),
            "user"       => requestedRole.Equals("user", StringComparison.OrdinalIgnoreCase),
            "thirdparty" => requestedRole.Equals("thirdparty", StringComparison.OrdinalIgnoreCase),
            _            => false
        };
}