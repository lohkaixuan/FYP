// =============================
// Controllers/TransactionController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;


namespace ApiApp.Controllers;


[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TransactionController : ControllerBase
{
    private readonly AppDbContext _db;
    public TransactionController(AppDbContext db) { _db = db; }


    [HttpGet]
    public async Task<IResult> List() => Results.Ok(await _db.Transactions.AsNoTracking().OrderByDescending(t => t.transaction_timestamp).Take(200).ToListAsync());


    [HttpGet("by-wallet/{walletId:guid}")]
    public async Task<IResult> ByWallet(Guid walletId)
    {
        var rows = await _db.Transactions.AsNoTracking()
        .Where(t => t.from_wallet_id == walletId || t.to_wallet_id == walletId)
        .OrderByDescending(t => t.transaction_timestamp)
        .ToListAsync();
        return Results.Ok(rows);
    }
}