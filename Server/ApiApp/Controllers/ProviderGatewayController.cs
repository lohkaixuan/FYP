// File: ApiApp/Controllers/ProviderGatewayController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Providers;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/providers")]
public class ProviderGatewayController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ProviderRegistry _registry;

    public ProviderGatewayController(AppDbContext db, ProviderRegistry registry)
    {
        _db = db; _registry = registry;
    }

    [HttpGet("balance/{linkId:guid}")]
    public async Task<IActionResult> GetBalance(Guid linkId)
    {
        var link = await _db.BankLinks.FirstOrDefaultAsync(x => x.LinkId == linkId);
        if (link == null) return NotFound("bank link not found");

        var client = await _registry.ResolveAsync(link.ProviderId);
        if (client == null) return BadRequest("provider disabled or unsupported");

        var bal = await client.GetBalanceAsync(link);
        return Ok(new { balance = bal, linkId });
    }
}
