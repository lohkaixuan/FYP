// Controllers/BankAccountController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Helpers;
using ApiApp.Providers;
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

    // -----------------------------
    // Helpers
    // -----------------------------
    private bool TryGetUserId(out Guid userId)
    {
        userId = Guid.Empty;

        var userIdStr =
            User.FindFirstValue(ClaimTypes.NameIdentifier) ??
            User.FindFirstValue("sub") ??
            User.FindFirstValue("user_id") ??
            User.FindFirstValue("id");

        return !string.IsNullOrWhiteSpace(userIdStr) && Guid.TryParse(userIdStr, out userId);
    }

    // GET /api/bankaccount?userId=...
    // NOTE: Better security is to ignore query userId and always use token userId,
    // but keeping your current signature for now.
    [HttpGet]
    public async Task<IResult> List([FromQuery] string userId)
    {
        if (string.IsNullOrEmpty(userId))
            return Results.BadRequest("userId is required!");

        if (!Guid.TryParse(userId, out var guidUserId))
            return Results.BadRequest("Invalid userId!");

        var accounts = await _db.BankAccounts
            .AsNoTracking()
            .Where(a => a.UserId == guidUserId && !a.IsDeleted)
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

    // =============================
    // Dynamic provider endpoints
    // =============================
    public record LinkProviderRequest(string Provider, string BankType, string Username, string Password);
    public record LinkIdRequest(Guid LinkId);
    public record LinkIdTransferRequest(Guid LinkId, decimal Amount, string? Note);

    // POST /api/bankaccount/link-provider
    [HttpPost("link-provider")]
    public async Task<IResult> LinkProvider(
        [FromBody] LinkProviderRequest req,
        [FromServices] ProviderRegistry registry
    )
    {
        if (!TryGetUserId(out var userId))
            return Results.Unauthorized();

        if (string.IsNullOrWhiteSpace(req.Provider))
            return Results.BadRequest("Provider is required");

        // 1) load provider row from DB
        var provider = await _db.Providers.FirstOrDefaultAsync(p =>
            p.Name == req.Provider && p.Enabled && !p.IsDeleted);

        if (provider == null)
            return Results.BadRequest($"Provider '{req.Provider}' not found/enabled");

        // 2) call provider login
        var client = registry.Resolve(req.Provider);

        LoginResult login;
        try
        {
            login = await client.LoginAsync(provider, req.BankType, req.Username, req.Password);
        }
        catch (Exception ex)
        {
            return Results.BadRequest($"Provider login failed: {ex.Message}");
        }

        if (string.IsNullOrWhiteSpace(login.ExternalAccountId))
            return Results.BadRequest("Missing external account id");

        // 3) upsert BankLink
        var link = await _db.BankLinks.FirstOrDefaultAsync(x =>
            x.UserId == userId &&
            x.ProviderId == provider.ProviderId &&
            x.ExternalAccountRef == login.ExternalAccountId &&
            !x.IsDeleted);

        if (link == null)
        {
            link = new BankLink
            {
                LinkId = Guid.NewGuid(),
                UserId = userId,
                ProviderId = provider.ProviderId,
                ExternalAccountRef = login.ExternalAccountId,
                DisplayName = $"{req.BankType} ({req.Username})"
            };
            _db.BankLinks.Add(link);
        }

        // 4) store token + raw json
        link.ExternalAccessTokenEnc = login.AccessToken;

        // IMPORTANT: store as JsonDocument (ensure column is jsonb in model config)
        if (login.Raw.ValueKind != JsonValueKind.Undefined && login.Raw.ValueKind != JsonValueKind.Null)
        {
            link.ExternalRawJson = JsonDocument.Parse(login.Raw.GetRawText());
        }
        else
        {
            link.ExternalRawJson = null;
        }

        ModelTouch.Touch(link);

        // 5) bind related BankAccount.BankLinkId
        // FIX: ExternalAccountId might be:
        // - a GUID that equals bank_account_id (your current screenshots)
        // - OR a bank_account_number string (some providers)
        BankAccount? account = null;

        if (Guid.TryParse(login.ExternalAccountId, out var externalGuid))
        {
            // Case A: external id is UUID -> match bank_account_id
            account = await _db.BankAccounts.FirstOrDefaultAsync(b =>
                b.UserId == userId &&
                b.BankAccountId == externalGuid &&
                !b.IsDeleted);
        }

        if (account == null)
        {
            // Case B: external id is account number -> match bank_account_number
            account = await _db.BankAccounts.FirstOrDefaultAsync(b =>
                b.UserId == userId &&
                b.BankAccountNumber == login.ExternalAccountId &&
                !b.IsDeleted);
        }

        if (account != null)
        {
            account.BankLinkId = link.LinkId;
            ModelTouch.Touch(account);
        }

        await _db.SaveChangesAsync();

        // 6) return linkId so UI can flip to "Linked"
        return Results.Ok(new
        {
            message = "Linked / Updated",
            provider = req.Provider,
            bank_type = req.BankType,
            external_account_ref = link.ExternalAccountRef,
            display_name = link.DisplayName,
            linkId = link.LinkId,
            bankAccountId = account?.BankAccountId
        });
    }

    // POST /api/bankaccount/provider/balance
    // Body: { "linkId": "..." }
    [HttpPost("provider/balance")]
    public async Task<IResult> ProviderBalanceByLinkId(
        [FromBody] LinkIdRequest req,
        [FromServices] ProviderRegistry registry
    )
    {
        if (!TryGetUserId(out var userId))
            return Results.Unauthorized();

        var link = await _db.BankLinks.AsNoTracking()
            .FirstOrDefaultAsync(x => x.LinkId == req.LinkId && !x.IsDeleted);

        if (link == null) return Results.NotFound("Bank link not found");
        if (link.UserId != userId) return Results.Forbid();

        var provider = await _db.Providers.AsNoTracking()
            .FirstOrDefaultAsync(p => p.ProviderId == link.ProviderId && p.Enabled && !p.IsDeleted);

        if (provider == null) return Results.BadRequest("Provider not found/enabled");

        var tokenEnc = link.ExternalAccessTokenEnc;
        if (string.IsNullOrWhiteSpace(tokenEnc))
            return Results.BadRequest("No access token stored for this link. Call link-provider again.");

        var token = tokenEnc; // TODO AES decrypt later
        var client = registry.Resolve(provider.Name);

        try
        {
            var json = await client.GetBalanceAsync(provider, token);
            return Results.Ok(json);
        }
        catch (Exception ex)
        {
            return Results.BadRequest($"Balance failed: {ex.Message}");
        }
    }

    // POST /api/bankaccount/provider/transfer
    // Body: { "linkId": "...", "amount": 1.00, "note": "test" }
    [HttpPost("provider/transfer")]
    public async Task<IResult> ProviderTransferByLinkId(
        [FromBody] LinkIdTransferRequest req,
        [FromServices] ProviderRegistry registry
    )
    {
        if (!TryGetUserId(out var userId))
            return Results.Unauthorized();

        if (req.Amount <= 0) return Results.BadRequest("Amount must be > 0");

        var link = await _db.BankLinks
            .FirstOrDefaultAsync(x => x.LinkId == req.LinkId && !x.IsDeleted);

        if (link == null) return Results.NotFound("Bank link not found");
        if (link.UserId != userId) return Results.Forbid();

        var provider = await _db.Providers.AsNoTracking()
            .FirstOrDefaultAsync(p => p.ProviderId == link.ProviderId && p.Enabled && !p.IsDeleted);

        if (provider == null) return Results.BadRequest("Provider not found/enabled");

        var tokenEnc = link.ExternalAccessTokenEnc;
        if (string.IsNullOrWhiteSpace(tokenEnc))
            return Results.BadRequest("No access token stored for this link. Call link-provider again.");

        var token = tokenEnc; // TODO AES decrypt later
        var client = registry.Resolve(provider.Name);

        try
        {
            var json = await client.TransferAsync(provider, token, req.Amount, req.Note);
            return Results.Ok(json);
        }
        catch (Exception ex)
        {
            return Results.BadRequest($"Transfer failed: {ex.Message}");
        }
    }
}
