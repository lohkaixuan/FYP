// File: ApiApp/Controllers/ProviderController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Helpers;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // 你可以加 [Authorize(Roles = "admin")] 之类
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

        var publicKey = string.IsNullOrWhiteSpace(p.PublicKeyEnc)
            ? null
            : _crypto.Decrypt(p.PublicKeyEnc);

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
        if (string.IsNullOrWhiteSpace(dto.api_url) &&
            string.IsNullOrWhiteSpace(dto.public_key) &&
            string.IsNullOrWhiteSpace(dto.private_key))
        {
            return Results.BadRequest("Provide at least one of api_url, public_key, private_key");
        }

        var p = await _db.Providers.FirstOrDefaultAsync(x => x.ProviderId == id);
        if (p is null) return Results.NotFound("provider not found");

        if (!string.IsNullOrWhiteSpace(dto.api_url))
        {
            p.ApiUrl = dto.api_url.Trim();
        }

        if (!string.IsNullOrWhiteSpace(dto.public_key))
        {
            p.PublicKeyEnc = _crypto.Encrypt(dto.public_key.Trim());
        }

        if (!string.IsNullOrWhiteSpace(dto.private_key))
        {
            p.PrivateKeyEnc = _crypto.Encrypt(dto.private_key.Trim());
        }

        await _db.SaveChangesAsync();
        return Results.Ok(new { p.ProviderId, p.Name });
    }
}
