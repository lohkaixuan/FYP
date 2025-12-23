// File: ApiApp/Controllers/TransactionsController.cs
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.AI;                 // ICategorizer, TxInput, Category, CategoryParser
using ApiApp.Helpers;            // ModelTouch
using Category = ApiApp.AI.Category;

namespace ApiApp.Controllers;

// A transaction model after grouping.
public class GroupedTransactions
{
    public string Type { get; set; } = string.Empty;   // "debit" or "credit"
    public decimal TotalAmount { get; set; }
    public List<Transaction> Transactions { get; set; } = new();
}

[ApiController]
[Route("api/transactions")]
[Authorize]
public sealed class TransactionsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ICategorizer _cat;

    public TransactionsController(AppDbContext db, ICategorizer cat)
    {
        _db = db; _cat = cat;
    }

    private bool TryGetUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var raw =
            User.FindFirstValue(ClaimTypes.NameIdentifier) ??
            User.FindFirstValue("sub") ??
            User.FindFirstValue("user_id") ??
            User.FindFirstValue("id");
        return Guid.TryParse(raw, out userId);
    }

    // --------- moved from CategoryController ---------
    [HttpPost("categorize")]
    public async Task<ActionResult<TxOutput>> Categorize([FromBody] TxInput tx, CancellationToken ct)
        => Ok(await _cat.CategorizeAsync(tx, ct));

    // -------- DTO --------
    public sealed class CreateTransactionDto
    {
        public string transaction_type { get; set; } = "pay";
        public string transaction_from { get; set; } = string.Empty;
        public string transaction_to { get; set; } = string.Empty;
        public decimal transaction_amount { get; set; }
        public DateTime? transaction_timestamp { get; set; }
        public string? transaction_item { get; set; }
        public string? transaction_detail { get; set; }
        public string? mcc { get; set; }
        public string? payment_method { get; set; }
        public string? override_category_csv { get; set; }
    }

    [HttpPost]
    public async Task<ActionResult<Transaction>> Create([FromBody] CreateTransactionDto dto, CancellationToken ct)
    {
        try
        {
            if (!TryGetUserId(out var userId))
                return Unauthorized();

            IAccount? fromAccount =
                (IAccount?)await _db.BankAccounts
                    .FirstOrDefaultAsync(x => x.BankAccountNumber == dto.transaction_from, ct)
                ?? (IAccount?)await _db.Wallets
                    .FirstOrDefaultAsync(x => x.wallet_number == dto.transaction_from, ct);

            if (fromAccount == null)
                return BadRequest(new { ok = false, message = "Invalid 'from' account or wallet ID." });

            IAccount? toAccount =
                (IAccount?)await _db.BankAccounts
                    .FirstOrDefaultAsync(x => x.BankAccountNumber == dto.transaction_to, ct)
                ?? (IAccount?)await _db.Wallets
                    .FirstOrDefaultAsync(x => x.wallet_number == dto.transaction_to, ct);

            if (toAccount == null)
                return BadRequest(new { ok = false, message = "Invalid 'to' account or wallet ID." });

            if (fromAccount.Balance < dto.transaction_amount)
                return BadRequest(new { ok = false, message = "Insufficient balance." });

            fromAccount.Balance -= dto.transaction_amount;
            toAccount.Balance += dto.transaction_amount;

            var mlText = string.Join(" | ", new[] { dto.transaction_to, dto.transaction_item, dto.transaction_detail }
                .Where(s => !string.IsNullOrWhiteSpace(s)));

            var guess = await _cat.CategorizeAsync(new TxInput(
                merchant: dto.transaction_to,
                description: mlText,
                mcc: dto.mcc,
                amount: dto.transaction_amount,
                currency: "MYR",
                country: "MY"
            ), ct);

            Category? finalCat = null;
            if (!string.IsNullOrWhiteSpace(dto.override_category_csv) &&
                CategoryParser.TryParse(dto.override_category_csv, out var parsed))
            {
                finalCat = parsed;
            }

            var categoryString = (finalCat?.ToString() ?? guess.category.ToString()).ToLowerInvariant();

            var entity = new Transaction
            {
                transaction_type = dto.transaction_type,
                transaction_from = dto.transaction_from,
                transaction_to = dto.transaction_to,
                transaction_amount = dto.transaction_amount,
                transaction_timestamp = dto.transaction_timestamp?.ToUniversalTime() ?? DateTime.UtcNow,
                transaction_item = dto.transaction_item,
                transaction_detail = dto.transaction_detail,
                payment_method = dto.payment_method,
                transaction_status = "pending",
                last_update = DateTime.UtcNow,

                PredictedCategory = guess.category,
                PredictedConfidence = guess.confidence,
                FinalCategory = finalCat,
                category = categoryString,
                MlText = mlText,
                from_user_id = userId
            };
            ModelTouch.Touch(entity);

            _db.Add(entity);
            await _db.SaveChangesAsync(ct);

            var ts = entity.transaction_timestamp;
            var budget = await _db.Budgets
                .AsNoTracking()
                .FirstOrDefaultAsync(b =>
                    b.UserId == userId &&
                    b.Category == categoryString &&
                    b.CycleStart <= ts &&
                    b.CycleEnd >= ts, ct);

            object? alert = null;
            if (budget != null)
            {
                var spent = await _db.Transactions
                    .AsNoTracking()
                    .Where(t =>
                        t.from_user_id == userId &&
                        t.category != null &&
                        t.category.ToLower().Trim() == categoryString &&
                        t.transaction_timestamp >= budget.CycleStart &&
                        t.transaction_timestamp <= budget.CycleEnd)
                    .SumAsync(t => t.transaction_amount, ct);

                var remaining = budget.LimitAmount - spent;
                if (spent > budget.LimitAmount)
                {
                    alert = new
                    {
                        exceeded = true,
                        limitAmount = budget.LimitAmount,
                        spentAfter = spent,
                        remainingAfter = remaining,
                        message = $"Budget exceeded for {categoryString}. Over by {Math.Abs(remaining):0.00}."
                    };
                }
            }

            var payload = new
            {
                transaction = entity,
                budgetAlert = alert
            };

            return CreatedAtAction(nameof(GetById), new { id = entity.transaction_id }, payload);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { ok = false, message = ex.Message, inner = ex.InnerException?.Message, stack = ex.StackTrace });
        }
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<Transaction>> GetById(Guid id, CancellationToken ct)
    {
        var tx = await _db.Transactions.AsNoTracking()
            .FirstOrDefaultAsync(x => x.transaction_id == id, ct);
        return tx is null ? NotFound() : Ok(tx);
    }

    [HttpGet]
    public async Task<ActionResult> List(
        [FromQuery] string? userId,
        [FromQuery] string? merchantId,
        [FromQuery] string? bankId,
        [FromQuery] string? walletId,
        [FromQuery] string? type,
        [FromQuery] string? category,
        [FromQuery] int? year,
        [FromQuery] int? month,
        CancellationToken ct,
        [FromQuery] bool groupByCategory = false,
        [FromQuery] bool groupByType = false
        )
    {
        var query = _db.Transactions.AsNoTracking();

        Guid? user = Guid.TryParse(userId, out var gUser) ? gUser : null;
        Guid? merchant = Guid.TryParse(merchantId, out var gMerch) ? gMerch : null;
        Guid? bank = Guid.TryParse(bankId, out var gBank) ? gBank : null;
        Guid? wallet = Guid.TryParse(walletId, out var gWallet) ? gWallet : null;
        string? cleanedCategory = category?.ToLower().Trim();
        string? cleanedType = type?.ToLower().Trim();

        // Optional month filter (UTC)
        DateTime? periodStart = null;
        DateTime? periodEnd = null;
        if (month.HasValue)
        {
            if (month < 1 || month > 12)
                return BadRequest(new { message = "month must be 1-12" });

            var y = year ?? DateTime.UtcNow.Year;
            periodStart = new DateTime(y, month.Value, 1, 0, 0, 0, DateTimeKind.Utc);
            periodEnd = periodStart.Value.AddMonths(1).AddTicks(-1);
            query = query.Where(t =>
                t.transaction_timestamp >= periodStart.Value &&
                t.transaction_timestamp <= periodEnd.Value);
        }

        if (user != null || merchant != null || bank != null || wallet != null)
        {
            query = query.Where(t =>
                (user != null && (t.from_user_id == user || t.to_user_id == user)) ||
                (merchant != null && (t.from_merchant_id == merchant || t.to_merchant_id == merchant)) ||
                (bank != null && (t.from_bank_id == bank || t.to_bank_id == bank)) ||
                (wallet != null && (t.from_wallet_id == wallet || t.to_wallet_id == wallet))
            );

            if (cleanedCategory != null)
            {
                query = query
                    .Where(t => t.category != null && t.category.ToLower().Trim() == cleanedCategory
                );
            }
            if (cleanedType == "debit")
            {
                query = query.Where(t =>
                    t.transaction_type == "pay" ||
                    (t.transaction_type == "transfer" && (
                        (user != null && t.from_user_id == user) ||
                        (merchant != null && t.from_merchant_id == merchant) ||
                        (bank != null && t.from_bank_id == bank) ||
                        (wallet != null && t.from_wallet_id == wallet)
                    ))
                );
            }
            else if (cleanedType == "credit")
            {
                query = query.Where(t =>
                    t.transaction_type == "topup" ||
                    (t.transaction_type == "transfer" && (
                        (user != null && t.to_user_id == user) ||
                        (merchant != null && t.to_merchant_id == merchant) ||
                        (bank != null && t.to_bank_id == bank) ||
                        (wallet != null && t.to_wallet_id == wallet)
                    ))
                );
            }
        }

        // Group By Debit and Credit
        if (groupByType)
        {
            var grouped = await query
                .Where(t => t.transaction_type != null)
                .GroupBy(t =>
                    (t.transaction_type == "pay" ||
                    (t.transaction_type == "transfer" && t.from_user_id == user))
                        ? "debit"
                        : "credit")
                .Select(g => new GroupedTransactions
                {
                    Type = g.Key,
                    TotalAmount = g.Sum(t => t.transaction_amount),
                    Transactions = g.OrderByDescending(t => t.transaction_timestamp).Take(200).ToList()
                })
                .ToListAsync(ct);

            return Ok(grouped);
        }

        // Group By Category
        if (groupByCategory)
        {
            var grouped = await query
                .Where(t => t.category != null)
                .GroupBy(t => t.category!)
                .Select(g => new GroupedTransactions
                {
                    Type = g.Key,
                    TotalAmount = g.Sum(t => t.transaction_amount),
                    Transactions = g.OrderByDescending(t => t.transaction_timestamp).Take(200).ToList()
                })
                .ToListAsync(ct);

            return Ok(grouped);
        }

        var rows = await query
            .OrderByDescending(t => t.transaction_timestamp)
            .Take(200)
            .ToListAsync(ct);

        if (!string.IsNullOrEmpty(type) || !string.IsNullOrEmpty(category))
        {
            var singleGroup = new GroupedTransactions
            {
                Type = type ?? category ?? "all",
                TotalAmount = rows.Sum(t => t.transaction_amount),
                Transactions = rows
            };
            return Ok(new List<GroupedTransactions> { singleGroup });
        }
        return Ok(rows);
    }

    public sealed class SetFinalDto
    {
        public string? category_csv { get; set; }
        public Category? category_enum { get; set; }
    }

    [HttpPatch("{id:guid}/final-category")]
    public async Task<ActionResult> SetFinal(Guid id, [FromBody] SetFinalDto dto, CancellationToken ct)
    {
        var tx = await _db.Transactions.FirstOrDefaultAsync(x => x.transaction_id == id, ct);
        if (tx is null) return NotFound();

        Category? final = dto.category_enum;
        if (final is null && !string.IsNullOrWhiteSpace(dto.category_csv) &&
            CategoryParser.TryParse(dto.category_csv, out var parsed))
        {
            final = parsed;
        }
        if (final is null) return BadRequest(new { message = "No valid category provided." });

        tx.FinalCategory = final.Value;
        tx.category = final.Value.ToString();
        ModelTouch.Touch(tx); 

        await _db.SaveChangesAsync(ct);
        return NoContent();
    }
}
