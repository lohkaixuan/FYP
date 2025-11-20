// =============================
// Controllers/UsersController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using System.Security.Claims;

namespace ApiApp.Controllers;


[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly AppDbContext _db;
    public UsersController(AppDbContext db) { _db = db; }


    [HttpGet("me")]
    public async Task<IResult> Me()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (sub is null || !Guid.TryParse(sub, out var uid)) return Results.Unauthorized();
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == uid);
        if (user is null) return Results.NotFound();

        // Ensure personal wallet
        var userWallet = await _db.Wallets.FirstOrDefaultAsync(w => w.user_id == uid && w.merchant_id == null);
        if (userWallet is null)
        {
            userWallet = new Wallet
            {
                wallet_id = Guid.NewGuid(),
                user_id = uid,
                merchant_id = null,
                wallet_balance = 0m,
                last_update = DateTime.UtcNow
            };
            _db.Wallets.Add(userWallet);
            await _db.SaveChangesAsync();
        }

        // If this user owns a merchant, ensure merchant wallet
        Guid? merchantWalletId = null;
        Wallet? merchantWallet = null;
        var merchant = await _db.Merchants.AsNoTracking().FirstOrDefaultAsync(m => m.OwnerUserId == uid);
        if (merchant is not null)
        {
            merchantWallet = await _db.Wallets.FirstOrDefaultAsync(w => w.merchant_id == merchant.MerchantId);
            if (merchantWallet is null)
            {
                merchantWallet = new Wallet
                {
                    wallet_id = Guid.NewGuid(),
                    user_id = null,
                    merchant_id = merchant.MerchantId,
                    wallet_balance = 0m,
                    last_update = DateTime.UtcNow
                };
                _db.Wallets.Add(merchantWallet);
                await _db.SaveChangesAsync();
            }
            merchantWalletId = merchantWallet.wallet_id;
        }

        // Return a safe, client-friendly projection including wallet_id
        return Results.Ok(new
        {
            user_id = user.UserId,
            user_name = user.UserName,
            user_email = user.Email,
            user_phone_number = user.PhoneNumber,
            user_balance = user.Balance,
            last_login = user.LastLogin,
            // Back-compat: wallet_id = personal wallet
            wallet_id = userWallet.wallet_id,
            user_wallet_id = userWallet.wallet_id,
            user_wallet_balance = userWallet.wallet_balance,
            merchant_wallet_id = merchantWalletId,
            merchant_wallet_balance = merchantWallet?.wallet_balance,
            merchant_name = merchant?.MerchantName
        });
    }


    [HttpGet]
    public async Task<IResult> List() => Results.Ok(await _db.Users.AsNoTracking().ToListAsync());


    [HttpGet("{id:guid}")]
    public async Task<IResult> Get(Guid id)
    {
        var u = await _db.Users.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == id);
        return u is null ? Results.NotFound() : Results.Ok(u);
    }
}
