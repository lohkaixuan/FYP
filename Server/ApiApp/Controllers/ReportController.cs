using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

[ApiController]
[Route("api/report")]
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
        // Role auth (adjust to your JWT)
        var callerRole = User.FindFirstValue("role") ?? "user";
        if (!IsAllowedToGenerate(callerRole, req.Role))
            return Forbid();

        // ---- Auto-scope by claims if missing ----
        static Guid? TryGuid(string? v) => Guid.TryParse(v, out var g) ? g : null;

        if (req.Role.Equals("user", StringComparison.OrdinalIgnoreCase) && req.UserId is null)
            req = req with { UserId = TryGuid(User.FindFirstValue("sub")) };

        if (req.Role.Equals("merchant", StringComparison.OrdinalIgnoreCase) && req.MerchantId is null)
            req = req with {
                MerchantId = TryGuid(User.FindFirstValue("merchant_id")) ?? TryGuid(User.FindFirstValue("sub"))
            };

        if (req.Role.Equals("thirdparty", StringComparison.OrdinalIgnoreCase) && req.ProviderId is null)
            req = req with {
                ProviderId = TryGuid(User.FindFirstValue("provider_id")) ?? TryGuid(User.FindFirstValue("sub"))
            };

        await using var conn = await _ds.OpenConnectionAsync(ct);
        await using var tx = await conn.BeginTransactionAsync(ct);

        // 1) Build chart from Neon
        var chart = await _repo.BuildMonthlyChartAsync(conn, req, ct);

        // 2) Render PDF
        var pdfBytes = _pdf.Render(chart, req.Role, req.Month);

        // 3) Upsert metadata + file into DB
        var createdBy = TryGuid(User.FindFirstValue("sub"));
        var reportId = await _repo.UpsertReportAndFileAsync(conn, req, chart, pdfBytes, createdBy, ct);

        await tx.CommitAsync(ct);

        // 4) Return API download URL
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

        var (contentType, bytes) = file.Value;
        return File(bytes, contentType, $"report-{id}.pdf");
    }

    private static bool IsAllowedToGenerate(string callerRole, string requestedRole) => callerRole switch
    {
        "admin"      => true,
        "merchant"   => requestedRole.Equals("merchant", StringComparison.OrdinalIgnoreCase),
        "user"       => requestedRole.Equals("user", StringComparison.OrdinalIgnoreCase),
        "thirdparty" => requestedRole.Equals("thirdparty", StringComparison.OrdinalIgnoreCase),
        _            => false
    };
}
/*// Server/ApiApp/Controllers/ReportController.cs
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;   // <-- your DbContext & entities
using ApiApp.AI;       // not required; here in case you reuse Category enum

namespace ApiApp.Controllers;

[ApiController]
[Route("api/report")]
[Authorize] // remove if you want to call it without token
public sealed class ReportController : ControllerBase
{
    private readonly AppDbContext _db;
    public ReportController(AppDbContext db) => _db = db;

    // Matches your Swagger body:
    // {
    //   "role":  "11111111-1111-1111-1111-111111111001",
    //   "month": "2025-10-23",
    //   "userId":"11111111-1111-1111-1111-000000000003"
    // }
    public sealed class MonthlyGenerateRequest
    {
        public string? role { get; set; }      // optional (guid string)
        public string? month { get; set; }     // any ISO date string
        public string? userId { get; set; }    // required (guid string)
    }

    public sealed class MonthlyReportResponse
    {
        public string month { get; set; } = "";
        public Guid userId { get; set; }
        public decimal totalSpend { get; set; }
        public decimal totalIncome { get; set; }
        public decimal net { get; set; }
        public int txCount { get; set; }
        public object byCategory { get; set; } = Array.Empty<object>();
    }

    [HttpPost("monthly/generate")]
    public async Task<ActionResult<MonthlyReportResponse>> GenerateMonthly([FromBody] MonthlyGenerateRequest req, CancellationToken ct)
    {
        // ---- Validate inputs with friendly messages
        if (string.IsNullOrWhiteSpace(req.userId) || !Guid.TryParse(req.userId, out var userId))
            return BadRequest(new { ok = false, message = "Invalid or missing userId (must be a GUID string)." });

        Guid? roleId = null;
        if (!string.IsNullOrWhiteSpace(req.role))
        {
            if (!Guid.TryParse(req.role, out var rid))
                return BadRequest(new { ok = false, message = "Invalid role (must be a GUID string)." });
            roleId = rid;
        }

        // Month handling: accept any date; normalize to first day (UTC)
        DateTime monthDate;
        if (string.IsNullOrWhiteSpace(req.month))
            monthDate = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        else if (!DateTime.TryParse(req.month, out monthDate))
            return BadRequest(new { ok = false, message = "Invalid month (use ISO date like 2025-10 or 2025-10-01)." });

        var monthStart = new DateTime(monthDate.Year, monthDate.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd   = monthStart.AddMonths(1);

        // ---- Check user exists
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == userId, ct);
        if (user is null)
            return NotFound(new { ok = false, message = $"User {userId} not found." });

        // (Optional) If caller provided roleId, ensure user has this role
        if (roleId.HasValue)
        {
            var hasRole = await _db.Roles.AsNoTracking()
                             .AnyAsync(r => r.RoleId == roleId.Value, ct);
            if (!hasRole)
                return NotFound(new { ok = false, message = $"Role {roleId} not found." });
        }

        // ---- Pull this user's transactions for the month
        // Your table uses multiple “from/to” fields; include all where the user participated.
        var q = _db.Transactions.AsNoTracking()
                 .Where(t => t.transaction_timestamp >= monthStart && t.transaction_timestamp < monthEnd)
                 .Where(t => t.from_user_id == userId || t.to_user_id == userId);

        var list = await q.ToListAsync(ct);

        if (list.Count == 0)
        {
            return Ok(new MonthlyReportResponse
            {
                month = monthStart.ToString("yyyy-MM"),
                userId = userId,
                totalSpend = 0,
                totalIncome = 0,
                net = 0,
                txCount = 0,
                byCategory = Array.Empty<object>()
            });
        }

        // Spend/Income rule:
        // - if user is payer (from_user_id == userId) → spend (amount negative direction)
        // - if user is payee (to_user_id == userId)   → income
        decimal spend = 0, income = 0;
        foreach (var t in list)
        {
            var amt = t.transaction_amount;
            if (t.from_user_id == userId) spend += amt;
            if (t.to_user_id == userId)   income += amt;
        }

        // Aggregate by final category (fallback to predicted, then string)
        var byCat = list
            .GroupBy(t => (t.FinalCategory?.ToString() ??
                           t.PredictedCategory?.ToString() ??
                           (t.category ?? "Other")))
            .Select(g => new {
                category = g.Key,
                spend    = g.Where(t => t.from_user_id == userId).Sum(t => t.transaction_amount),
                income   = g.Where(t => t.to_user_id   == userId).Sum(t => t.transaction_amount),
                count    = g.Count()
            })
            .OrderByDescending(x => x.spend + x.income)
            .ToList<object>();

        var resp = new MonthlyReportResponse
        {
            month = monthStart.ToString("yyyy-MM"),
            userId = userId,
            totalSpend = spend,
            totalIncome = income,
            net = income - spend,
            txCount = list.Count,
            byCategory = byCat
        };

        return Ok(resp);
    }
}
*/