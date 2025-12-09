// File: ApiApp/Controllers/ProviderController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Helpers;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] 
public class ProviderController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ICryptoService _crypto;

    public ProviderController(AppDbContext db, ICryptoService crypto)
    {
        _db = db;
        _crypto = crypto;
    }

    public record ProviderListDto(
        Guid provider_id,
        string name,
        string api_url,
        bool enabled,
        bool has_keys
    );

    [HttpGet("{id:guid}")]
    public async Task<IResult> Get(Guid id)
    {
        var p = await _db.Providers.AsNoTracking()
            .FirstOrDefaultAsync(x => x.ProviderId == id);
        if (p is null) return Results.NotFound("provider not found");

        string? publicKey = null;
        try
        {
            publicKey = string.IsNullOrWhiteSpace(p.PublicKeyEnc)
                ? null
                : _crypto.Decrypt(p.PublicKeyEnc);
        }
        catch (Exception ex)
        {
            return Results.BadRequest(new
            {
                message = "Failed to decrypt provider keys",
                error = ex.Message
            });
        }

        return Results.Ok(new
        {
            provider_id = p.ProviderId,
            name = p.Name,
            api_url = p.ApiUrl,
            enabled = p.Enabled,
            public_key = publicKey,
            has_private_key = !string.IsNullOrWhiteSpace(p.PrivateKeyEnc),
        });
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProviderListDto>>> List(CancellationToken ct)
    {
        var data = await _db.Providers.AsNoTracking()
            .Select(p => new ProviderListDto(
                p.ProviderId,
                p.Name,
                p.ApiUrl,
                p.Enabled,
                !string.IsNullOrEmpty(p.PublicKeyEnc) && !string.IsNullOrEmpty(p.PrivateKeyEnc)
            ))
            .ToListAsync(ct);

        return Ok(data);
    }

    public record UpdateSecretsDto(string? api_url, string? public_key, string? private_key);

    [HttpPut("{id:guid}/secrets")]
public async Task<IResult> UpdateSecrets(Guid id, [FromBody] UpdateSecretsDto dto)
{
    var p = await _db.Providers.FirstOrDefaultAsync(x => x.ProviderId == id);
    if (p is null) return Results.NotFound("provider not found");

    
    if (string.IsNullOrWhiteSpace(dto.api_url) &&
        string.IsNullOrWhiteSpace(dto.public_key) &&
        string.IsNullOrWhiteSpace(dto.private_key))
    {
        return Results.BadRequest("Provide at least one of api_url, public_key, private_key");
    }

    
    if (!string.IsNullOrWhiteSpace(dto.api_url))
        p.ApiUrl = dto.api_url.Trim();

    
    if (!string.IsNullOrWhiteSpace(dto.public_key))
    {
        var pk = dto.public_key.Trim();

        if (!pk.StartsWith("pk_"))
            return Results.BadRequest("Public key must start with 'pk_'");

        if (pk.Contains("sk_"))
            return Results.BadRequest("Public key must NOT contain secret key");

        p.PublicKeyEnc = _crypto.Encrypt(pk);
    }

    
    if (!string.IsNullOrWhiteSpace(dto.private_key))
    {
        var sk = dto.private_key.Trim();

        if (!sk.StartsWith("sk_"))
            return Results.BadRequest("Private key must start with 'sk_'");

        if (sk.Contains("pk_"))
            return Results.BadRequest("Private key must NOT contain publishable key");

        p.PrivateKeyEnc = _crypto.Encrypt(sk);
    }

    await _db.SaveChangesAsync();
    return Results.Ok(new {
        ProviderId = p.ProviderId,
        p.Name,
        message = "Provider keys updated safely"
    });
}

}
