// =============================
// Controllers/WalletController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;
using Stripe;

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
    private readonly ICryptoService _crypto;
    private readonly ICategorizer _cat;

    public WalletController(AppDbContext db, ICategorizer cat, ICryptoService crypto)
    {
        _db = db;
        _cat = cat;
        _crypto = crypto;
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

    /// <summary>
    /// 真正打外部 Provider（Stripe / MockBank）的地方
    /// </summary>
    private async Task<(bool success, string? error, string? providerRef)> ChargeViaProviderAsync(
        Guid providerId,
        string externalSourceId,
        decimal amount,
        Guid walletId,
        CancellationToken ct = default)
    {
        // --- basic validation ---
        if (string.IsNullOrWhiteSpace(externalSourceId))
            return (false, "external_source_id is required", null);

        if (amount <= 0)
            return (false, "amount must be greater than zero", null);

        // --- load provider from DB ---
        var provider = await _db.Providers
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.ProviderId == providerId && p.Enabled, ct);

        if (provider is null)
            return (false, "provider not found or disabled", null);

        // --- decrypt Stripe secret key (for providers that have one) ---
        string secretKey;
        try
        {
            secretKey = _crypto.Decrypt(provider.PrivateKeyEnc);
        }
        catch (Exception ex)
        {
            return (false, $"Failed to decrypt provider key: {ex.Message}", null);
        }

        // =======================
        //  Stripe implementation
        // =======================
        if (string.Equals(provider.Name, "Stripe", StringComparison.OrdinalIgnoreCase))
        {
            // 1) configure Stripe with provider's secret key
            StripeConfiguration.ApiKey = secretKey;

            // 2) convert to cents
            var amountInCents = (long)Math.Round(amount * 100m, MidpointRounding.AwayFromZero);
            if (amountInCents <= 0)
                return (false, "amount too small after currency conversion", null);

            var service = new PaymentIntentService();

            try
            {
                var options = new PaymentIntentCreateOptions
                {
                    Amount = amountInCents,
                    Currency = "myr",
                    PaymentMethod = externalSourceId,   // id from createPaymentMethod
                    Confirm = true,
                    ConfirmationMethod = "automatic",
                    Description = "Wallet reload",

                    // 只启用 card，避免 Dashboard 里那些 redirect payment method 要求 return_url
                    PaymentMethodTypes = new List<string> { "card" },

                    Metadata = new Dictionary<string, string>
                    {
                        ["provider_id"] = providerId.ToString(),
                        ["wallet_id"]   = walletId.ToString(),
                        ["amount"]      = amount.ToString("F2")
                    }
                };

                var intent = await service.CreateAsync(
                    options,
                    requestOptions: null,
                    cancellationToken: ct
                );

                // 3) decide success/failure by PaymentIntent status
                if (intent.Status == "succeeded" || intent.Status == "requires_capture")
                {
                    // providerRef = PaymentIntent.Id (for webhook / reconciliation)
                    return (true, null, intent.Id);
                }

                if (intent.Status == "requires_action")
                {
                    return (false, "Payment requires further action (3DS)", intent.Id);
                }

                return (false, $"Stripe payment failed with status {intent.Status}", intent.Id);
            }
            catch (StripeException sx)
            {
                return (false, sx.Message, null);
            }
            catch (Exception ex)
            {
                return (false, $"Stripe payment error: {ex.Message}", null);
            }
        }
        // =======================
        //  Mock provider example
        // =======================
        else if (string.Equals(provider.Name, "MockBank", StringComparison.OrdinalIgnoreCase))
        {
            await Task.Delay(1, ct);   // fake latency
            return (true, null, null);
        }

        return (false, "unsupported provider", null);
    }

    // ---------- basic endpoints ----------

    [HttpGet("{id}")]
    public async Task<ActionResult<Wallet>> Get(Guid id, CancellationToken ct)
    {
        var wallet = await _db.Wallets.AsNoTracking()
            .FirstOrDefaultAsync(x => x.wallet_id == id, ct);

        return wallet is null ? NotFound() : Ok(wallet);
    }

    // ==========================================================
    // Lookup：通过 phone/email/username/merchant name/wallet_id 找钱包
    // ==========================================================
    [HttpGet("lookup")]
    public async Task<IResult> Lookup(
        [FromQuery] Guid? wallet_id,
        [FromQuery] string? search,
        [FromQuery] string? phone,
        [FromQuery] string? email,
        [FromQuery] string? username,
        CancellationToken ct)
    {
        static string? Normalize(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
        static bool LooksLikeEmail(string value) => value.Contains('@');
        static bool LooksLikePhone(string value) => Regex.IsMatch(value, @"^[0-9+\s\-]+$");
        static string NormalizePhone(string value) => Regex.Replace(value, @"[\s\-]", "");

        User? user = null;
        Merchant? merchant = null;
        Wallet? forcedWallet = null;
        var matchType = "user";

        var normalizedSearch = Normalize(search);
        var normalizedPhone = Normalize(phone);
        var normalizedEmail = Normalize(email);
        var normalizedUsername = Normalize(username);
        var baseTerm = normalizedSearch ?? normalizedPhone ?? normalizedEmail ?? normalizedUsername;

        if (wallet_id.HasValue)
        {
            forcedWallet = await _db.Wallets.AsNoTracking()
                .FirstOrDefaultAsync(w => w.wallet_id == wallet_id.Value, ct);
            if (forcedWallet is null)
                return Results.NotFound(new { message = "Wallet not found" });

            if (forcedWallet.user_id is Guid uid)
            {
                user = await _db.Users.AsNoTracking()
                    .FirstOrDefaultAsync(u => u.UserId == uid, ct);
                matchType = "user";
            }
            else if (forcedWallet.merchant_id is Guid mid)
            {
                merchant = await _db.Merchants.AsNoTracking()
                    .Include(m => m.OwnerUser)
                    .FirstOrDefaultAsync(m => m.MerchantId == mid, ct);
                if (merchant?.OwnerUserId is Guid ownerId)
                {
                    user = await _db.Users.AsNoTracking()
                        .FirstOrDefaultAsync(u => u.UserId == ownerId, ct);
                    matchType = "merchant";
                }
            }

            if (user is null)
                return Results.NotFound(new { message = "Wallet owner not found" });
        }
        else
        {
            if (string.IsNullOrEmpty(baseTerm))
                return Results.BadRequest(new { message = "Provide a phone, email, username, merchant name or wallet id." });

            string? phoneCandidate = normalizedPhone;
            string? emailCandidate = normalizedEmail;
            string? usernameCandidate = normalizedUsername;

            if (phoneCandidate is null && emailCandidate is null && usernameCandidate is null)
            {
                if (LooksLikeEmail(baseTerm))
                {
                    emailCandidate = baseTerm;
                }
                else if (LooksLikePhone(baseTerm))
                {
                    phoneCandidate = baseTerm;
                }
                else
                {
                    usernameCandidate = baseTerm;
                }
            }

            if (phoneCandidate is not null)
            {
                var phoneExact = NormalizePhone(phoneCandidate);
                user = await _db.Users.AsNoTracking()
                    .FirstOrDefaultAsync(u => u.PhoneNumber != null && u.PhoneNumber == phoneExact, ct);
            }

            if (user is null && emailCandidate is not null)
            {
                var emailFold = emailCandidate.ToLowerInvariant();
                user = await _db.Users.AsNoTracking()
                    .FirstOrDefaultAsync(u => u.Email != null && u.Email.ToLower() == emailFold, ct);
            }

            if (user is null && usernameCandidate is not null)
            {
                var usernameFold = usernameCandidate.ToLowerInvariant();
                user = await _db.Users.AsNoTracking()
                    .FirstOrDefaultAsync(u => u.UserName != null && u.UserName.ToLower() == usernameFold, ct);
            }

            if (user is null)
            {
                var merchantTerm = (baseTerm ?? string.Empty).ToLowerInvariant();
                merchant = await _db.Merchants.AsNoTracking()
                    .Include(m => m.OwnerUser)
                    .FirstOrDefaultAsync(m => m.MerchantName.ToLower() == merchantTerm, ct);

                if (merchant is null)
                {
                    merchant = await _db.Merchants.AsNoTracking()
                        .Include(m => m.OwnerUser)
                        .FirstOrDefaultAsync(m => m.MerchantName.ToLower().Contains(merchantTerm), ct);
                }

                if (merchant is not null && merchant.OwnerUserId is Guid ownerId)
                {
                    user = await _db.Users.AsNoTracking()
                        .FirstOrDefaultAsync(u => u.UserId == ownerId, ct);
                    matchType = "merchant";
                }
            }
        }

        if (user is null)
            return Results.NotFound(new { message = "User or merchant not found" });

        var userWallet = await _db.Wallets.AsNoTracking()
            .FirstOrDefaultAsync(w => w.user_id == user.UserId && w.merchant_id == null, ct);
        if (userWallet is null)
            return Results.NotFound(new { message = "Wallet not found for user" });

        merchant ??= await _db.Merchants.AsNoTracking()
            .FirstOrDefaultAsync(m => m.OwnerUserId == user.UserId, ct);

        Wallet? merchantWallet = null;
        if (merchant is not null)
        {
            merchantWallet = await _db.Wallets.AsNoTracking()
                .FirstOrDefaultAsync(w => w.merchant_id == merchant.MerchantId, ct);
        }

        var preferredType = matchType == "merchant" && merchantWallet is not null ? "merchant" : "user";

        if (forcedWallet is not null)
        {
            if (forcedWallet.merchant_id.HasValue && merchantWallet is not null &&
                forcedWallet.wallet_id == merchantWallet.wallet_id)
            {
                preferredType = "merchant";
            }
            else
            {
                preferredType = "user";
            }
        }

        var preferredWallet = preferredType == "merchant" ? merchantWallet : userWallet;
        if (preferredWallet is null)
        {
            preferredType = "user";
            preferredWallet = userWallet;
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
            match_type = matchType,
            preferred_wallet_type = preferredType,
            preferred_wallet_id = preferredWallet?.wallet_id,
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
                wallet_id = userWallet.wallet_id,
                wallet_number = userWallet.wallet_number,
                wallet_balance = userWallet.wallet_balance,
                last_update = userWallet.last_update
            },
            merchant_wallet = merchantPayload,
            wallet_id = preferredWallet?.wallet_id ?? userWallet.wallet_id,
            wallet_number = preferredWallet?.wallet_number ?? userWallet.wallet_number,
            wallet_balance = preferredWallet?.wallet_balance ?? userWallet.wallet_balance,
            last_update = preferredWallet?.last_update ?? userWallet.last_update,
            merchant_wallet_id = merchantWallet?.wallet_id,
            merchant_wallet_number = merchantWallet?.wallet_number,
            merchant_wallet_balance = merchantWallet?.wallet_balance,
            user_wallet_id = userWallet.wallet_id
        });
    }

    // ==========================================================
    // 1) RELOAD (via bank/stripe provider -> wallet)
    // ==========================================================
    public record ReloadDto(Guid wallet_id, decimal amount, Guid provider_id, string external_source_id);

    [HttpPost("reload")]
    public async Task<IResult> Reload([FromBody] ReloadDto dto)
    {
        if (dto.amount <= 0) return Results.BadRequest("amount must be > 0");

        // 调用外部 Provider（Stripe / MockBank）
        var providerCharge = await ChargeViaProviderAsync(
            dto.provider_id, dto.external_source_id, dto.amount, dto.wallet_id, HttpContext.RequestAborted);

        if (!providerCharge.success)
        {
            return Results.BadRequest(providerCharge.error
                                      ?? "External provider (e.g., Stripe) failed to process the transaction.");
        }

        using var tx = await _db.Database.BeginTransactionAsync();

        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.wallet_id);
        if (wallet is null) return Results.NotFound("wallet not found");

        // 钱已经从 Provider 进来，这里只负责加余额 + 写 Transaction
        wallet.wallet_balance += dto.amount;
        ModelTouch.Touch(wallet);

        var mlText = "Wallet reload (via Provider)";
        var guess = await _cat.CategorizeAsync(new TxInput(
            merchant: "Reload",
            description: mlText,
            mcc: null,
            amount: dto.amount,
            currency: "MYR",
            country: "MY"
        ), HttpContext.RequestAborted);

        var t = new Transaction
        {
            transaction_type = "reload",
            transaction_from = $"PROVIDER:{dto.provider_id}:{providerCharge.providerRef ?? dto.external_source_id}",
            transaction_to = wallet.wallet_id.ToString(),
            to_wallet_id = wallet.wallet_id,
            transaction_amount = dto.amount,
            payment_method = "provider",
            transaction_status = "success",
            transaction_detail = mlText,
            PredictedCategory = guess.category,
            PredictedConfidence = guess.confidence,
            FinalCategory = null,
            category = (guess.category).ToString(),
            MlText = mlText,
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
        public PayMode mode { get; set; } = PayMode.standard;

        // Common (standard/NFC)
        public Guid? from_wallet_id { get; set; }
        public Guid? to_wallet_id { get; set; }
        public decimal? amount { get; set; }
        public string? item { get; set; }        // line item (optional)
        public string? detail { get; set; }      // note/remark (optional)
        public string? category_csv { get; set; } // optional final override (CSV label)
        public string? nonce { get; set; }       // reserved for future anti-replay

        // QR-specific
        public string? qr_data { get; set; }     // JSON from QR (frontend-generated)
    }

    private sealed class QrPayload
    {
        public string? type { get; set; }        // "wallet"
        public Guid? to_wallet_id { get; set; }
        public decimal? amount { get; set; }
        public string? memo { get; set; }
        public long? exp { get; set; }           // unix seconds expiry (optional)
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
            toId = payload.to_wallet_id.Value;
            amt = dto.amount ?? payload.amount ?? 0m;
            if (amt <= 0) return Results.BadRequest("amount must be > 0");
            memo ??= payload.memo;
        }
        else
        {
            // standard & nfc
            if (dto.from_wallet_id is null || dto.to_wallet_id is null)
                return Results.BadRequest("from_wallet_id and to_wallet_id required");

            fromId = dto.from_wallet_id.Value;
            toId = dto.to_wallet_id.Value;
            if (dto.amount is null || dto.amount <= 0) return Results.BadRequest("amount must be > 0");
            amt = dto.amount.Value;
        }

        if (fromId == toId) return Results.BadRequest("cannot pay self");

        using var tx = await _db.Database.BeginTransactionAsync();

        var from = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == fromId);
        var to = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == toId);
        if (from is null || to is null) return Results.NotFound("wallet not found");
        if (from.wallet_balance < amt) return Results.BadRequest("insufficient balance");

        from.wallet_balance -= amt;
        to.wallet_balance += amt;
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
        var kindTag = dto.mode switch
        {
            PayMode.nfc => "NFCPay",
            PayMode.qr => "QRPay",
            _ => "pay"
        };

        var t = new Transaction
        {
            transaction_type = "pay",
            transaction_from = from.wallet_id.ToString(),
            transaction_to = to.wallet_id.ToString(),
            from_wallet_id = from.wallet_id,
            to_wallet_id = to.wallet_id,
            transaction_amount = amt,
            transaction_item = dto.item,
            transaction_detail = memo,
            payment_method = methodTag,
            transaction_status = "success",
            PredictedCategory = guess.category,
            PredictedConfidence = guess.confidence,
            FinalCategory = finalCat,
            category = (finalCat ?? guess.category).ToString(), // single canonical field for clients
            MlText = mlText,
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
            from_balance = from.wallet_balance,
            to_wallet_id = to.wallet_id,
            to_balance = to.wallet_balance,
            transaction_id = t.transaction_id,
            category = t.category,
            predicted = new { cat = t.PredictedCategory?.ToString(), conf = t.PredictedConfidence }
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
        var to = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == dto.to_wallet_id);
        if (from is null || to is null) return Results.NotFound("wallet not found");
        if (from.wallet_balance < dto.amount) return Results.BadRequest("insufficient balance");

        from.wallet_balance -= dto.amount;
        to.wallet_balance += dto.amount;
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
            transaction_type = "transfer",
            transaction_from = from.wallet_id.ToString(),
            transaction_to = to.wallet_id.ToString(),
            from_wallet_id = from.wallet_id,
            to_wallet_id = to.wallet_id,
            transaction_amount = dto.amount,
            payment_method = "wallet",
            transaction_status = "success",
            transaction_detail = dto.detail,
            PredictedCategory = guess.category,
            PredictedConfidence = guess.confidence,
            FinalCategory = finalCat,
            category = (finalCat ?? guess.category).ToString(),
            MlText = mlText,
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
            from_balance = from.wallet_balance,
            to_wallet_id = to.wallet_id,
            to_balance = to.wallet_balance,
            transaction_id = t.transaction_id,
            category = t.category,
            predicted = new { cat = t.PredictedCategory?.ToString(), conf = t.PredictedConfidence }
        });
    }
}
