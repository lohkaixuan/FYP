// File: Server/ApiApp/Controllers/ReportController.cs
using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Npgsql;
using Dapper;  // 👈 用来查现有报表

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
    // - 如果同一角色 + 同一 owner + 同一月份已经有报表：
    //      直接返回旧的 report_id，不重新生成
    // - 如果该月份太早（还没到月底后 N 天）：
    //      返回 400，不允许生成
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
            var existingId = await conn.QuerySingleOrDefaultAsync<Guid?>(
                @"select id
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

            if (existingId.HasValue)
            {
                var existingUrl = Url.Content($"/api/report/{existingId.Value}/download")!;
                var existingRes = new MonthlyReportResponse(existingId.Value, req.Role, req.Month, existingUrl);
                return Ok(existingRes);
            }

            // --------------------------------------------
            // ② 若没有现成报表，检查「时间是否允许生成」
            //    规则：必须在该月结束后的 N 天之后才可以生成
            //    例如：Month=2025-11-01，最早可生成日期为 2025-12-04（N=3）
            // --------------------------------------------
            var firstDayOfMonth = new DateOnly(req.Month.Year, req.Month.Month, 1);
            var firstDayOfNextMonth = firstDayOfMonth.AddMonths(1);
            var earliestGenerateDate = firstDayOfNextMonth.AddDays(MIN_DAYS_AFTER_MONTH_END);

            var today = DateOnly.FromDateTime(DateTime.UtcNow); // 如果你想用本地时间可以改成 Now

            if (today < earliestGenerateDate)
            {
                return BadRequest(new
                {
                    ok = false,
                    message = "Monthly report for this period is not available yet.",
                    year = firstDayOfMonth.Year,
                    month = firstDayOfMonth.Month,
                    earliest_generate_date = earliestGenerateDate.ToString("yyyy-MM-dd")
                });
            }

            // --------------------------------------------
            // ③ 到这里才真正执行：查询交易 → 生成 chart → PDF → 存 DB
            // --------------------------------------------
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
