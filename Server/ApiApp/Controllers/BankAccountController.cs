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

    // =============================
    // Dynamic provider endpoints
    // =============================

    public record LinkProviderRequest(string Provider, string BankType, string Username, string Password);
    public record ProviderTokenRequest(string Provider, string AccessToken);
    public record ProviderTransferRequest(string Provider, string AccessToken, decimal Amount, string? Note);
    public record LinkIdRequest(Guid LinkId);
    public record LinkIdTransferRequest(Guid LinkId, decimal Amount, string? Note);

    // POST /api/bankaccount/link-provider
    [HttpPost("link-provider")]
    public async Task<IResult> LinkProvider(
        [FromBody] LinkProviderRequest req,
        [FromServices] ProviderRegistry registry
    )
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? User.FindFirstValue("user_id")
            ?? User.FindFirstValue("id");

        if (string.IsNullOrEmpty(userIdStr) || !Guid.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        // load provider row from DB
        var provider = await _db.Providers.FirstOrDefaultAsync(p =>
            p.Name == req.Provider && p.Enabled && !p.IsDeleted);

        if (provider == null)
            return Results.BadRequest($"Provider '{req.Provider}' not found/enabled");

        var client = registry.Resolve(req.Provider);

        // ✅ always login to get a fresh token
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

        // ✅ upsert BankLink (create if not exists, else update token)
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
                DisplayName = $"{req.BankType} ({req.Username})",
            };
            _db.BankLinks.Add(link);
        }

        // ✅ store token + raw payload (later encrypt token)
        link.ExternalAccessTokenEnc = login.AccessToken;
        link.ExternalRawJson = JsonDocument.Parse(login.Raw.GetRawText());

        ModelTouch.Touch(link);
        await _db.SaveChangesAsync();

        return Results.Ok(new
        {
            message = "Linked / Updated",
            provider = req.Provider,
            bank_type = req.BankType,
            external_account_ref = link.ExternalAccountRef
            // do NOT return token in production
            // access_token = login.AccessToken
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
        // 1) find link
        var link = await _db.BankLinks.AsNoTracking()
            .FirstOrDefaultAsync(x => x.LinkId == req.LinkId && !x.IsDeleted);

        if (link == null) return Results.NotFound("Bank link not found");

        // 2) find provider
        var provider = await _db.Providers.AsNoTracking()
            .FirstOrDefaultAsync(p => p.ProviderId == link.ProviderId && p.Enabled && !p.IsDeleted);

        if (provider == null) return Results.BadRequest("Provider not found/enabled");

        // 3) read token from DB
        var tokenEnc = link.ExternalAccessTokenEnc;
        if (string.IsNullOrWhiteSpace(tokenEnc))
            return Results.BadRequest("No access token stored for this link. Call link-provider again.");

        // TODO: when you implement AES:
        // var token = _crypto.Decrypt(tokenEnc);
        var token = tokenEnc; // currently plaintext

        // 4) call provider client
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
    // POST /api/bankaccount/provider/transfer
    // Body: { "linkId": "...", "amount": 1.00, "note": "test" }
    [HttpPost("provider/transfer")]
    public async Task<IResult> ProviderTransferByLinkId(
        [FromBody] LinkIdTransferRequest req,
        [FromServices] ProviderRegistry registry
    )
    {
        // 1) find link
        var link = await _db.BankLinks
            .FirstOrDefaultAsync(x => x.LinkId == req.LinkId && !x.IsDeleted);

        if (link == null) return Results.NotFound("Bank link not found");

        // 2) find provider
        var provider = await _db.Providers.AsNoTracking()
            .FirstOrDefaultAsync(p => p.ProviderId == link.ProviderId && p.Enabled && !p.IsDeleted);

        if (provider == null) return Results.BadRequest("Provider not found/enabled");

        // 3) token from DB
        var tokenEnc = link.ExternalAccessTokenEnc;
        if (string.IsNullOrWhiteSpace(tokenEnc))
            return Results.BadRequest("No access token stored for this link. Call link-provider again.");

        // TODO AES decrypt later:
        var token = tokenEnc;

        // 4) call provider
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

    // =============================
    // Old mockbank-only endpoints
    // =============================
    // You can DELETE these once link-provider works:
    // - link-mock-bank
    // - mockbank/balance
    // - mockbank/transfer
}
