// File: ApiApp/Controllers/StripeController.cs
using System.Globalization;
using System.IO;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;
using Stripe.Checkout;
using ApiApp.Models;
using ApiApp.AI;       // ICategorizer, TxInput
using ApiApp.Helpers;  // ICryptoService, ModelTouch

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StripeController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ICategorizer _cat;
    private readonly ICryptoService _crypto;
    private readonly ILogger<StripeController> _logger;
    private readonly IConfiguration _cfg;
    private readonly string _webhookSecret;
    private readonly string _successUrl;
    private readonly string _cancelUrl;

    public StripeController(
        AppDbContext db,
        ICategorizer cat,
        ICryptoService crypto,
        ILogger<StripeController> logger,
        IConfiguration cfg)
    {
        _db = db;
        _cat = cat;
        _crypto = crypto;
        _logger = logger;
        _cfg = cfg;

        // Webhook secret 仍然直接用 env / appsettings，不需要进 DB
        _webhookSecret = cfg["Stripe:WebhookSecret"]
                      ?? Environment.GetEnvironmentVariable("STRIPE_WEBHOOK_SECRET")
                      ?? throw new InvalidOperationException("Stripe webhook secret is not configured");

        // 前端成功、取消页面（你可以放在 appsettings.json）
        _successUrl = cfg["Stripe:SuccessUrl"]
                   ?? "https://your-frontend.example.com/topup/success?session_id={CHECKOUT_SESSION_ID}";
        _cancelUrl = cfg["Stripe:CancelUrl"]
                   ?? "https://your-frontend.example.com/topup/cancelled";
    }

    // ===== DTO =====
    public sealed class CreateCheckoutDto
    {
        public Guid wallet_id { get; set; }
        public decimal amount { get; set; }
    }

    // ===== 私有方法：从 providers + AES 拿 Stripe secret，必要时回退到 env =====
    private async Task<string> ResolveStripeSecretAsync(CancellationToken ct)
    {
        // 1) 优先从 providers 表读取 Name == "Stripe" 的记录
        var provider = await _db.Providers.AsNoTracking()
            .Where(p => p.Name == "Stripe")
            .FirstOrDefaultAsync(ct);

        if (provider is not null && !string.IsNullOrWhiteSpace(provider.PrivateKeyEnc))
        {
            try
            {
                var secret = _crypto.Decrypt(provider.PrivateKeyEnc);
                if (!string.IsNullOrWhiteSpace(secret))
                    return secret;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to decrypt Stripe provider secret from DB");
            }
        }

        // 2) Fallback：环境变量 / 配置，方便初始 seed 没配好也能跑
        var fallback = _cfg["Stripe:SecretKey"]
                       ?? Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");

        if (string.IsNullOrWhiteSpace(fallback))
            throw new InvalidOperationException("Stripe secret key is not configured in provider or env");

        return fallback;
    }

    // ==========================================================
    // 1) 创建 Stripe Checkout Session
    // ==========================================================
    [Authorize]
    [HttpPost("create-checkout")]
    public async Task<IResult> CreateCheckout(
        [FromBody] CreateCheckoutDto dto,
        CancellationToken ct)
    {
        if (dto.wallet_id == Guid.Empty)
            return Results.BadRequest("wallet_id is required");

        if (dto.amount <= 0)
            return Results.BadRequest("amount must be > 0");

        var wallet = await _db.Wallets.AsNoTracking()
            .FirstOrDefaultAsync(w => w.wallet_id == dto.wallet_id, ct);

        if (wallet is null)
            return Results.NotFound("wallet not found");

        // 🔐 每次请求动态拿 Stripe secret：优先 DB + AES 解密，其次 env
        var secretKey = await ResolveStripeSecretAsync(ct);
        StripeConfiguration.ApiKey = secretKey;

        var options = new SessionCreateOptions
        {
            Mode = "payment",
            SuccessUrl = _successUrl,
            CancelUrl = _cancelUrl,
            LineItems = new List<SessionLineItemOptions>
            {
                new()
                {
                    Quantity = 1,
                    PriceData = new SessionLineItemPriceDataOptions
                    {
                        Currency         = "myr",
                        UnitAmountDecimal = dto.amount * 100m, // Stripe 用分
                        ProductData = new SessionLineItemPriceDataProductDataOptions
                        {
                            Name = "Wallet top-up"
                        }
                    }
                }
            },
            Metadata = new Dictionary<string, string>
            {
                ["wallet_id"] = dto.wallet_id.ToString(),
                ["amount"] = dto.amount.ToString("F2", CultureInfo.InvariantCulture),
                ["kind"] = "wallet_topup"
            }
        };

        var service = new SessionService();
        var session = await service.CreateAsync(options, cancellationToken: ct);

        return Results.Ok(new
        {
            session_id = session.Id,
            url = session.Url
        });
    }

    // ==========================================================
    // 2) Stripe Webhook（付款成功后回调）
    // ==========================================================
    [AllowAnonymous]
    [HttpPost("webhook")]

    public async Task<IActionResult> Webhook()
    {
        var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
        var sigHeader = Request.Headers["Stripe-Signature"];

        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(json, sigHeader, _webhookSecret);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Stripe webhook signature verification failed");
            return BadRequest();
        }

        // 🔥 使用字符串匹配，最稳定写法
        if (stripeEvent.Type == "checkout.session.completed")
        {
            if (stripeEvent.Data.Object is Session session)
            {
                await HandleCheckoutCompletedAsync(session);
            }
        }
        else
        {
            _logger.LogInformation("Unhandled Stripe event type: {Type}", stripeEvent.Type);
        }

        return Ok();
    }


    // ==========================================================
    // 3) 付款成功 -> 帮用户 top-up 钱包 + 写 transaction
    // ==========================================================
    private async Task HandleCheckoutCompletedAsync(Session session)
    {
        try
        {
            if (!session.Metadata.TryGetValue("kind", out var kind) ||
                !string.Equals(kind, "wallet_topup", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogInformation("Stripe session {Id} not wallet_topup, ignore", session.Id);
                return;
            }

            if (!session.Metadata.TryGetValue("wallet_id", out var walletIdStr) ||
                !Guid.TryParse(walletIdStr, out var walletId))
            {
                _logger.LogWarning("Stripe session {Id} missing wallet_id", session.Id);
                return;
            }

            if (!session.Metadata.TryGetValue("amount", out var amountStr) ||
                !decimal.TryParse(amountStr, NumberStyles.Number, CultureInfo.InvariantCulture, out var amount) ||
                amount <= 0)
            {
                _logger.LogWarning("Stripe session {Id} missing/invalid amount", session.Id);
                return;
            }

            using var tx = await _db.Database.BeginTransactionAsync();

            var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.wallet_id == walletId);
            if (wallet is null)
            {
                _logger.LogWarning("Wallet {WalletId} not found for Stripe session {SessionId}", walletId, session.Id);
                return;
            }

            // 1) 钱包余额 + amount
            wallet.wallet_balance += amount;
            wallet.last_update = DateTime.UtcNow;

            // 2) 用 AI categorizer 预测分类，和 WalletController reload 一致风格
            var mlText = "Wallet reload (via Stripe)";
            var guess = await _cat.CategorizeAsync(new TxInput(
                merchant: "Stripe",
                description: mlText,
                mcc: null,
                amount: amount,
                currency: "MYR",
                country: "MY"
            ), HttpContext.RequestAborted);

            var t = new Transaction
            {
                transaction_type = "reload",
                transaction_from = $"STRIPE:{session.Id}",
                transaction_to = wallet.wallet_id.ToString(),
                to_wallet_id = wallet.wallet_id,
                transaction_amount = amount,
                payment_method = "stripe",
                transaction_status = "success",
                transaction_detail = mlText,

                PredictedCategory = guess.category,
                PredictedConfidence = guess.confidence,
                FinalCategory = null,
                category = guess.category.ToString(),
                MlText = mlText,
                transaction_timestamp = DateTime.UtcNow
            };
            ModelTouch.Touch(t);
            _db.Transactions.Add(t);

            await _db.SaveChangesAsync();
            await tx.CommitAsync();

            await SyncUserBalanceAsync(wallet.wallet_id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error while handling Stripe checkout.session.completed");
            // 不 throw，避免 Stripe 一直重试；这里只 log
        }
    }

    // 和 WalletController 里的逻辑一样：同步 users.balance
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
}
