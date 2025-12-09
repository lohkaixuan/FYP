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

        
        _webhookSecret = cfg["Stripe:WebhookSecret"]
                      ?? Environment.GetEnvironmentVariable("STRIPE_WEBHOOK_SECRET")
                      ?? throw new InvalidOperationException("Stripe webhook secret is not configured");

        
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

    
    private async Task<string> ResolveStripeSecretAsync(CancellationToken ct)
    {
        
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

        
        var fallback = _cfg["Stripe:SecretKey"]
                       ?? Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");

        if (string.IsNullOrWhiteSpace(fallback))
            throw new InvalidOperationException("Stripe secret key is not configured in provider or env");

        return fallback;
    }

    // ==========================================================
    
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
                        UnitAmountDecimal = dto.amount * 100m, 
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

            
            wallet.wallet_balance += amount;
            wallet.last_update = DateTime.UtcNow;

            
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
            
        }
    }

    
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
