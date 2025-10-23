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
