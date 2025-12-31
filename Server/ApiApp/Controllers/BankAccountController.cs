// =============================
// Controllers/BankAccountController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Helpers;
namespace ApiApp.Controllers;


[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BankAccountController : ControllerBase
{
    private readonly AppDbContext _db;
    public BankAccountController(AppDbContext db) { _db = db; }


    [HttpGet]
    public async Task<IResult> List([FromQuery] string userId)
    {
        Guid? guidUserId = Guid.TryParse(userId, out Guid userGuid)? userGuid: null;
        if (string.IsNullOrEmpty(userId)) return Results.BadRequest("userId is required!");

        var accounts = await _db.BankAccounts.AsNoTracking().Where(account => account.UserId == guidUserId).ToListAsync();
        return Results.Ok(accounts);
    }

    [HttpPost]
    public async Task<IResult> Create([FromBody] BankAccount b)
    {
        b.BankAccountId = Guid.NewGuid();
        ModelTouch.Touch(b); // ⬅️ replace b.last_update =
        _db.BankAccounts.Add(b);
        await _db.SaveChangesAsync();
        return Results.Created($"/api/bankaccount/{b.BankAccountId}", b);
    }
}