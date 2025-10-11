// =============================
// Controllers/WalletController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;

namespace ApiApp.Controllers;


[ApiController]
[Route("api/[controller]")]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly AppDbContext _db;
    public WalletController(AppDbContext db) { _db = db; }


    private async Task SyncUserBalanceAsync(Guid walletId)
    {
        var w = await _db.Wallets.AsNoTracking().FirstOrDefaultAsync(x => x.wallet_id == walletId);
        if (w?.user_id is Guid uid)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == uid);
            if (user is not null)
            {
                var latest = await _db.Wallets.AsNoTracking().Where(x => x.wallet_id == walletId).Select(x => x.wallet_balance).FirstAsync();
                user.Balance = latest; user.LastUpdate = DateTime.UtcNow; await _db.SaveChangesAsync();
            }
        }
    }


    public record TopUpDto(Guid wallet_id, decimal amount, Guid from_bank_account_id);
    public record PayDto(Guid from_wallet_id, Guid to_wallet_id, decimal amount, string? item = null, string? detail = null, string? category = null);
    public record TransferDto(Guid from_wallet_id, Guid to_wallet_id, decimal amount, string? detail = null, string? category = null);


    [HttpPost("topup")]
    public async Task<IResult> TopUp([FromBody] TopUpDto dto)
    {
        if (dto.amount <= 0) return Results.BadRequest("amount must be > 0");
        using var tx = await _db.Database.BeginTransactionAsync();
        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.wallet_id);
        var bank = await _db.BankAccounts.FirstOrDefaultAsync(b => b.BankAccountId == dto.from_bank_account_id);
        if (wallet is null || bank is null) return Results.NotFound("wallet/bank not found");
        if (bank.BankUserBalance < dto.amount) return Results.BadRequest("insufficient bank balance");
        bank.BankUserBalance -= dto.amount; wallet.wallet_balance += dto.amount; bank.last_update = wallet.last_update = DateTime.UtcNow;
        _db.Transactions.Add(new Transaction
        {
            transaction_type = "topup",
            transaction_from = bank.BankAccountNumber,
            transaction_to = wallet.wallet_id.ToString(),
            from_bank_id = bank.BankAccountId,
            to_wallet_id = wallet.wallet_id,
            transaction_amount = dto.amount,
            payment_method = "bank",
            transaction_status = "success",
            transaction_detail = "Wallet top-up",
            category = "TopUp",
            transaction_timestamp = DateTime.UtcNow,
            last_update = DateTime.UtcNow
        });
        await _db.SaveChangesAsync(); await tx.CommitAsync();
        await SyncUserBalanceAsync(wallet.wallet_id);
        return Results.Ok(new { wallet.wallet_id, wallet.wallet_balance });
    }


    [HttpPost("pay")]
    public async Task<IResult> Pay([FromBody] PayDto dto)
    {
        if (dto.amount <= 0) return Results.BadRequest("amount must be > 0");
        if (dto.from_wallet_id == dto.to_wallet_id) return Results.BadRequest("cannot pay self");
        using var tx = await _db.Database.BeginTransactionAsync();
        var from = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.from_wallet_id);
        var to = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.to_wallet_id);
    }
}
