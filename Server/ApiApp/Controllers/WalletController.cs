// =============================
// Controllers/WalletController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Helpers;     // ModelTouch
using ApiApp.AI;         // ICategorizer, TxInput, Category, CategoryParser
using Category = ApiApp.AI.Category;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ICategorizer _cat;

    public WalletController(AppDbContext db, ICategorizer cat)
    {
        _db = db;
        _cat = cat;
    }

    // ---------- helpers ----------
    private async Task SyncUserBalanceAsync(Guid walletId)
    {
        var w = await _db.Wallets.AsNoTracking().FirstOrDefaultAsync(x => x.wallet_id == walletId);
        if (w?.user_id is Guid uid)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.UserId == uid);
            if (user is not null)
            {
                var latest = await _db.Wallets.AsNoTracking()
                                  .Where(x => x.wallet_id == walletId)
                                  .Select(x => x.wallet_balance)
                                  .FirstAsync();
                user.Balance = latest;
                user.LastUpdate = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }
        }
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Wallet>> Get(Guid id, CancellationToken ct)
    {
        var wallet = await _db.Wallets.AsNoTracking()
            .FirstOrDefaultAsync(x => x.wallet_id == id, ct);
        return wallet is null ? NotFound() : Ok(wallet);
    }

    [HttpGet("lookup")]
    public async Task<IResult> Lookup([FromQuery] string? phone, [FromQuery] string? email, [FromQuery] string? username, CancellationToken ct)
    {
        static string? Normalize(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

        phone = Normalize(phone);
        email = Normalize(email);
        username = Normalize(username);

        if (phone is null && email is null && username is null)
            return Results.BadRequest(new { message = "Provide phone, email or username." });

        var query = _db.Users.AsNoTracking();
        User? user = null;

        if (phone is not null)
        {
            user = await query.FirstOrDefaultAsync(u => u.PhoneNumber != null && u.PhoneNumber == phone, ct);
        }

        if (user is null && email is not null)
        {
            var emailFold = email.ToLowerInvariant();
            user = await query.FirstOrDefaultAsync(u => u.Email != null && u.Email.ToLower() == emailFold, ct);
        }

        if (user is null && username is not null)
        {
            var usernameFold = username.ToLowerInvariant();
            user = await query.FirstOrDefaultAsync(u => u.UserName != null && u.UserName.ToLower() == usernameFold, ct);
        }

        if (user is null)
            return Results.NotFound(new { message = "User not found" });

        if (phone is not null && !string.Equals(user.PhoneNumber ?? string.Empty, phone, StringComparison.Ordinal))
            return Results.NotFound(new { message = "User not found" });
        if (email is not null && !string.Equals(user.Email ?? string.Empty, email, StringComparison.OrdinalIgnoreCase))
            return Results.NotFound(new { message = "User not found" });
        if (username is not null && !string.Equals(user.UserName ?? string.Empty, username, StringComparison.OrdinalIgnoreCase))
            return Results.NotFound(new { message = "User not found" });

        var wallet = await _db.Wallets.AsNoTracking()
            .FirstOrDefaultAsync(w => w.user_id == user.UserId && w.merchant_id == null, ct);

        if (wallet is null)
            return Results.NotFound(new { message = "Wallet not found for user" });

        var merchant = await _db.Merchants.AsNoTracking()
            .FirstOrDefaultAsync(m => m.OwnerUserId == user.UserId, ct);

        Wallet? merchantWallet = null;
        if (merchant is not null)
        {
            merchantWallet = await _db.Wallets.AsNoTracking()
                .FirstOrDefaultAsync(w => w.merchant_id == merchant.MerchantId, ct);
        }

        object? merchantPayload = null;
        if (merchant is not null && merchantWallet is not null)
        {
            merchantPayload = new
            {
                merchant_id = merchant.MerchantId,
                merchant_name = merchant.MerchantName,
                merchant_phone_number = merchant.MerchantPhoneNumber,
                wallet_id = merchantWallet.wallet_id,
                wallet_number = merchantWallet.wallet_number,
                wallet_balance = merchantWallet.wallet_balance,
                last_update = merchantWallet.last_update
            };
        }

        return Results.Ok(new
        {
            user = new
            {
                user_id = user.UserId,
                user_name = user.UserName,
                user_username = user.UserName,
                user_email = user.Email,
                user_phone_number = user.PhoneNumber
            },
            user_wallet = new
            {
                wallet_id = wallet.wallet_id,
                wallet_number = wallet.wallet_number,
                wallet_balance = wallet.wallet_balance,
                last_update = wallet.last_update
            },
            merchant_wallet = merchantPayload,
            // flat fields for convenience/back-compat
            wallet_id = wallet.wallet_id,
            wallet_number = wallet.wallet_number,
            wallet_balance = wallet.wallet_balance,
            last_update = wallet.last_update,
            merchant_wallet_id = merchantWallet?.wallet_id,
            merchant_wallet_number = merchantWallet?.wallet_number,
            merchant_wallet_balance = merchantWallet?.wallet_balance
        });
    }
    // ==========================================================
    // 1) TOP UP  (bank -> wallet)
    // ==========================================================
    public record TopUpDto(Guid wallet_id, decimal amount, Guid from_bank_account_id);

    [HttpPost("topup")]
    public async Task<IResult> TopUp([FromBody] TopUpDto dto)
    {
        if (dto.amount <= 0) return Results.BadRequest("amount must be > 0");
        using var tx = await _db.Database.BeginTransactionAsync();

        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.wallet_id);
        var bank   = await _db.BankAccounts.FirstOrDefaultAsync(b => b.BankAccountId == dto.from_bank_account_id);
        if (wallet is null || bank is null) return Results.NotFound("wallet/bank not found");
        if (bank.BankUserBalance < dto.amount) return Results.BadRequest("insufficient bank balance");

        bank.BankUserBalance -= dto.amount;
        wallet.wallet_balance += dto.amount;
        ModelTouch.Touch(bank); ModelTouch.Touch(wallet);

        // Categorizer text
        var mlText = "Wallet top-up";
        var guess  = await _cat.CategorizeAsync(new TxInput(
            merchant: "TopUp",
            description: mlText,
            mcc: null,
            amount: dto.amount,
            currency: "MYR",
            country: "MY"
        ), HttpContext.RequestAborted);

        var t = new Transaction
        {
            transaction_type      = "topup",
            transaction_from      = bank.BankAccountNumber,
            transaction_to        = wallet.wallet_id.ToString(),
            from_bank_id          = bank.BankAccountId,
            to_wallet_id          = wallet.wallet_id,
            transaction_amount    = dto.amount,
            payment_method        = "bank",
            transaction_status    = "success",
            transaction_detail    = mlText,
            // ML fields
            PredictedCategory     = guess.category,
            PredictedConfidence   = guess.confidence,
            FinalCategory         = null,
            category              = (guess.category).ToString(),
            MlText                = mlText,
            transaction_timestamp = DateTime.UtcNow
        };
        ModelTouch.Touch(t);
        _db.Transactions.Add(t);

        await _db.SaveChangesAsync();
        await tx.CommitAsync();
        await SyncUserBalanceAsync(wallet.wallet_id);

        return Results.Ok(new { wallet.wallet_id, wallet.wallet_balance, transaction_id = t.transaction_id });
    }

    // ==========================================================
    // 2) PAY (wallet -> wallet): supports standard / NFC / QR
    // ==========================================================
    public enum PayMode { standard, nfc, qr }

    public sealed class PayDto
    {
        public PayMode mode            { get; set; } = PayMode.standard;

        // Common (standard/NFC)
        public Guid?   from_wallet_id  { get; set; }
        public Guid?   to_wallet_id    { get; set; }
        public decimal? amount         { get; set; }
        public string? item            { get; set; }     // line item (optional)
        public string? detail          { get; set; }     // note/remark (optional)
        public string? category_csv    { get; set; }     // optional final override (CSV label)
        public string? nonce           { get; set; }     // reserved for future anti-replay

        // QR-specific
        public string? qr_data         { get; set; }     // JSON from QR (frontend-generated)
    }

    private sealed class QrPayload
    {
        public string? type         { get; set; }        // "wallet"
        public Guid?   to_wallet_id { get; set; }
        public decimal? amount      { get; set; }
        public string? memo         { get; set; }
        public long?   exp          { get; set; }        // unix seconds expiry (optional)
    }

    [HttpPost("pay")]
    public async Task<IResult> Pay([FromBody] PayDto dto)
    {
        // ---- resolve inputs for all 3 modes
        Guid fromId, toId;
        decimal amt;
        string? memo = dto.detail;

        if (dto.mode == PayMode.qr)
        {
            if (string.IsNullOrWhiteSpace(dto.qr_data))
                return Results.BadRequest("qr_data required");

            QrPayload payload;
            try { payload = System.Text.Json.JsonSerializer.Deserialize<QrPayload>(dto.qr_data)!; }
            catch { return Results.BadRequest("invalid qr_data json"); }

            if (!string.Equals(payload.type, "wallet", StringComparison.OrdinalIgnoreCase))
                return Results.BadRequest("unsupported qr type");

            if (payload.to_wallet_id is null) return Results.BadRequest("qr missing to_wallet_id");
            if (payload.exp is not null)
            {
                var expUtc = DateTimeOffset.FromUnixTimeSeconds(payload.exp.Value).UtcDateTime;
                if (DateTime.UtcNow > expUtc) return Results.BadRequest("qr expired");
            }

            if (dto.from_wallet_id is null) return Results.BadRequest("from_wallet_id required");
            fromId = dto.from_wallet_id.Value;
            toId   = payload.to_wallet_id.Value;
            amt    = dto.amount ?? payload.amount ?? 0m;
            if (amt <= 0) return Results.BadRequest("amount must be > 0");
            memo ??= payload.memo;
        }
        else
        {
            // standard & nfc
            if (dto.from_wallet_id is null || dto.to_wallet_id is null)
                return Results.BadRequest("from_wallet_id and to_wallet_id required");

            fromId = dto.from_wallet_id.Value;
            toId   = dto.to_wallet_id.Value;
            if (dto.amount is null || dto.amount <= 0) return Results.BadRequest("amount must be > 0");
            amt = dto.amount.Value;
        }

        if (fromId == toId) return Results.BadRequest("cannot pay self");

        using var tx = await _db.Database.BeginTransactionAsync();

        var from = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == fromId);
        var to   = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == toId);
        if (from is null || to is null) return Results.NotFound("wallet not found");
        if (from.wallet_balance < amt) return Results.BadRequest("insufficient balance");

        from.wallet_balance -= amt;
        to.wallet_balance   += amt;
        ModelTouch.Touch(from); ModelTouch.Touch(to);

        // ---- Auto-categorize (ML-first, allow override)
        var merchantLabel = to.wallet_id.ToString(); // you can map to merchant name if available
        var mlText = string.Join(" | ", new[] { merchantLabel, dto.item, memo }
                                  .Where(s => !string.IsNullOrWhiteSpace(s)));

        var guess = await _cat.CategorizeAsync(new TxInput(
            merchant: merchantLabel,
            description: mlText,
            mcc: null,
            amount: amt,
            currency: "MYR",
            country: "MY"
        ), HttpContext.RequestAborted);

        Category? finalCat = null;
        if (!string.IsNullOrWhiteSpace(dto.category_csv) &&
            CategoryParser.TryParse(dto.category_csv, out var parsed))
        {
            finalCat = parsed;
        }

        // ---- Persist transaction
        var methodTag = "wallet";
        var kindTag   = dto.mode switch {
            PayMode.nfc => "NFCPay",
            PayMode.qr  => "QRPay",
            _           => "pay"
        };

        var t = new Transaction
        {
            transaction_type      = "pay",
            transaction_from      = from.wallet_id.ToString(),
            transaction_to        = to.wallet_id.ToString(),
            from_wallet_id        = from.wallet_id,
            to_wallet_id          = to.wallet_id,
            transaction_amount    = amt,
            transaction_item      = dto.item,
            transaction_detail    = memo,
            payment_method        = methodTag,
            transaction_status    = "success",
            PredictedCategory     = guess.category,
            PredictedConfidence   = guess.confidence,
            FinalCategory         = finalCat,
            category              = (finalCat ?? guess.category).ToString(), // single canonical field for clients
            MlText                = mlText,
            transaction_timestamp = DateTime.UtcNow
        };
        ModelTouch.Touch(t);
        _db.Transactions.Add(t);

        await _db.SaveChangesAsync();
        await tx.CommitAsync();

        await SyncUserBalanceAsync(from.wallet_id);
        await SyncUserBalanceAsync(to.wallet_id);

        return Results.Ok(new
        {
            mode = dto.mode.ToString(),
            from_wallet_id = from.wallet_id,
            from_balance   = from.wallet_balance,
            to_wallet_id   = to.wallet_id,
            to_balance     = to.wallet_balance,
            transaction_id = t.transaction_id,
            category       = t.category,
            predicted      = new { cat = t.PredictedCategory?.ToString(), conf = t.PredictedConfidence }
        });
    }

    // ==========================================================
    // 3) TRANSFER (wallet -> wallet)   [A2A]
    // ==========================================================
    public record TransferDto(Guid from_wallet_id, Guid to_wallet_id, decimal amount, string? detail = null, string? category_csv = null);

    [HttpPost("transfer")]
    public async Task<IResult> Transfer([FromBody] TransferDto dto)
    {
        if (dto.amount <= 0) return Results.BadRequest("amount must be > 0");
        if (dto.from_wallet_id == dto.to_wallet_id) return Results.BadRequest("cannot transfer to self");

        using var tx = await _db.Database.BeginTransactionAsync();

        var from = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.from_wallet_id);
        var to   = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.to_wallet_id);
        if (from is null || to is null) return Results.NotFound("wallet not found");
        if (from.wallet_balance < dto.amount) return Results.BadRequest("insufficient balance");

        from.wallet_balance -= dto.amount;
        to.wallet_balance   += dto.amount;
        ModelTouch.Touch(from); ModelTouch.Touch(to);

        // ML categorize
        var merchantLabel = to.wallet_id.ToString();
        var mlText = string.Join(" | ", new[] { merchantLabel, dto.detail }
                                  .Where(s => !string.IsNullOrWhiteSpace(s)));

        var guess = await _cat.CategorizeAsync(new TxInput(
            merchant: merchantLabel,
            description: mlText,
            mcc: null,
            amount: dto.amount,
            currency: "MYR",
            country: "MY"
        ), HttpContext.RequestAborted);

        Category? finalCat = null;
        if (!string.IsNullOrWhiteSpace(dto.category_csv) &&
            CategoryParser.TryParse(dto.category_csv, out var parsed))
        {
            finalCat = parsed;
        }

        var t = new Transaction
        {
            transaction_type      = "transfer",
            transaction_from      = from.wallet_id.ToString(),
            transaction_to        = to.wallet_id.ToString(),
            from_wallet_id        = from.wallet_id,
            to_wallet_id          = to.wallet_id,
            transaction_amount    = dto.amount,
            payment_method        = "wallet",
            transaction_status    = "success",
            transaction_detail    = dto.detail,
            PredictedCategory     = guess.category,
            PredictedConfidence   = guess.confidence,
            FinalCategory         = finalCat,
            category              = (finalCat ?? guess.category).ToString(),
            MlText                = mlText,
            transaction_timestamp = DateTime.UtcNow
        };
        ModelTouch.Touch(t);
        _db.Transactions.Add(t);

        await _db.SaveChangesAsync();
        await tx.CommitAsync();

        await SyncUserBalanceAsync(from.wallet_id);
        await SyncUserBalanceAsync(to.wallet_id);

        return Results.Ok(new
        {
            from_wallet_id = from.wallet_id,
            from_balance   = from.wallet_balance,
            to_wallet_id   = to.wallet_id,
            to_balance     = to.wallet_balance,
            transaction_id = t.transaction_id,
            category       = t.category,
            predicted      = new { cat = t.PredictedCategory?.ToString(), conf = t.PredictedConfidence }
        });
    }
}
