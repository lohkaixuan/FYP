// =============================
// Controllers/BankAccountController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using ApiApp.Models;
using ApiApp.Helpers;

using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Json;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BankAccountController : ControllerBase
{
    private readonly AppDbContext _db;

    public BankAccountController(AppDbContext db)
    {
        _db = db;
    }

    // GET /api/bankaccount?userId=...
    [HttpGet]
    public async Task<IResult> List([FromQuery] string userId)
    {
        if (string.IsNullOrEmpty(userId)) return Results.BadRequest("userId is required!");

        Guid? guidUserId = Guid.TryParse(userId, out var userGuid) ? userGuid : null;
        if (guidUserId == null) return Results.BadRequest("Invalid userId!");

        var accounts = await _db.BankAccounts
            .AsNoTracking()
            .Where(a => a.UserId == guidUserId)
            .ToListAsync();

        return Results.Ok(accounts);
    }

    // POST /api/bankaccount
    [HttpPost]
    public async Task<IResult> Create([FromBody] BankAccount b)
    {
        b.BankAccountId = Guid.NewGuid();
        ModelTouch.Touch(b);
        _db.BankAccounts.Add(b);
        await _db.SaveChangesAsync();
        return Results.Created($"/api/bankaccount/{b.BankAccountId}", b);
    }

    // ---------- LINK MOCK BANK ----------

    public record LinkBankRequest(
        string BankType,       // e.g. CIMB / Maybank
        string BankUsername,
        string BankPassword
    );

    // POST /api/bankaccount/link-mock-bank
    [HttpPost("link-mock-bank")]
    public async Task<IResult> LinkMockBank(
        [FromBody] LinkBankRequest req,
        [FromServices] IHttpClientFactory httpFactory
    )
    {
        // ✅ get user id from JWT
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdStr) || !Guid.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var baseUrl = Environment.GetEnvironmentVariable("MOCKBANK_BASE_URL");
        if (string.IsNullOrWhiteSpace(baseUrl))
            return Results.Problem("MOCKBANK_BASE_URL is not set");

        var client = httpFactory.CreateClient();
        client.BaseAddress = new Uri(baseUrl.TrimEnd('/'));

        // ✅ Node MockBank expects: bank_type, bank_username, bank_userpassword
        var resp = await client.PostAsJsonAsync("/auth/login", new
        {
            bank_type = req.BankType,
            bank_username = req.BankUsername,
            bank_userpassword = req.BankPassword
        });

        if (!resp.IsSuccessStatusCode)
        {
            var errText = await resp.Content.ReadAsStringAsync();
            return Results.BadRequest($"Mock bank login failed: {errText}");
        }

        var json = await resp.Content.ReadFromJsonAsync<JsonElement>();

        // ✅ Node returns: bank_account_id (snake_case)
        var externalAccountId = json.GetProperty("bank_account_id").GetString();
        if (string.IsNullOrWhiteSpace(externalAccountId))
            return Results.BadRequest("Mock bank response missing bank_account_id");

        // Optional: avoid duplicate links for same user + same external account
        var exists = await _db.BankLinks.AnyAsync(x =>
            x.UserId == userId &&
            x.ExternalAccountRef == externalAccountId &&
            x.IsDeleted == false);

        if (exists)
            return Results.Ok(new { message = "Bank already linked", external_account_ref = externalAccountId });

        // ✅ Save bank link locally
        var link = new BankLink
        {
            LinkId = Guid.NewGuid(),
            UserId = userId,
            ProviderId = Guid.Parse("11111111-1111-1111-1111-111111111111"), // your MockBank provider id
            ExternalAccountRef = externalAccountId,
            DisplayName = $"{req.BankType} ({req.BankUsername})",
        };

        ModelTouch.Touch(link);
        _db.BankLinks.Add(link);
        await _db.SaveChangesAsync();

        return Results.Ok(new
        {
            message = "Bank linked successfully",
            provider = "MockBank",
            bank_type = req.BankType,
            external_account_ref = externalAccountId
        });
    }
    
// 2) Get balance (Proxy to MockBank)
// POST /api/bankaccount/mockbank/balance
// Body: { "accessToken": "..." }
public record TokenRequest(string AccessToken);

[HttpPost("mockbank/balance")]
public async Task<IResult> MockBankBalance(
    [FromBody] TokenRequest req,
    [FromServices] IHttpClientFactory httpFactory)
{
    var baseUrl = Environment.GetEnvironmentVariable("MOCKBANK_BASE_URL");
    if (string.IsNullOrWhiteSpace(baseUrl))
        return Results.Problem("MOCKBANK_BASE_URL is not set");

    var client = httpFactory.CreateClient();
    client.BaseAddress = new Uri(baseUrl.TrimEnd('/'));
    client.DefaultRequestHeaders.Authorization =
        new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", req.AccessToken);

    var resp = await client.GetAsync("/accounts/balance");
    var text = await resp.Content.ReadAsStringAsync();

    if (!resp.IsSuccessStatusCode)
        return Results.BadRequest($"Mock bank balance failed: {text}");

    return Results.Ok(JsonSerializer.Deserialize<JsonElement>(text));
}


// 3) Transfer / Deduct (Proxy to MockBank)
// POST /api/bankaccount/mockbank/transfer
// Body: { "accessToken": "...", "amount": 10.5, "note": "reload" }
public record TransferRequest(string AccessToken, decimal Amount, string? Note);

[HttpPost("mockbank/transfer")]
public async Task<IResult> MockBankTransfer(
    [FromBody] TransferRequest req,
    [FromServices] IHttpClientFactory httpFactory)
{
    var baseUrl = Environment.GetEnvironmentVariable("MOCKBANK_BASE_URL");
    if (string.IsNullOrWhiteSpace(baseUrl))
        return Results.Problem("MOCKBANK_BASE_URL is not set");

    var client = httpFactory.CreateClient();
    client.BaseAddress = new Uri(baseUrl.TrimEnd('/'));
    client.DefaultRequestHeaders.Authorization =
        new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", req.AccessToken);

    var resp = await client.PostAsJsonAsync("/payments/transfer", new
    {
        amount = req.Amount,
        note = req.Note ?? "transfer"
    });

    var text = await resp.Content.ReadAsStringAsync();

    if (!resp.IsSuccessStatusCode)
        return Results.BadRequest($"Mock bank transfer failed: {text}");

    return Results.Ok(JsonSerializer.Deserialize<JsonElement>(text));
}
}

