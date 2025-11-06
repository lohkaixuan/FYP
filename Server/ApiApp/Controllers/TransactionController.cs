// File: ApiApp/Controllers/TransactionsController.cs
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.AI;                 // ICategorizer, TxInput, Category, CategoryParser
using ApiApp.Helpers;            // ModelTouch
using Category = ApiApp.AI.Category;

namespace ApiApp.Controllers;

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

        var entity = new Transaction
        {
            transaction_type = dto.transaction_type,
            transaction_from = dto.transaction_from,
            transaction_to = dto.transaction_to,
            transaction_amount = dto.transaction_amount,
            transaction_timestamp = dto.transaction_timestamp ?? DateTime.UtcNow,
            transaction_item = dto.transaction_item,
            transaction_detail = dto.transaction_detail,
            payment_method = dto.payment_method,

            PredictedCategory = guess.category,
            PredictedConfidence = guess.confidence,
            FinalCategory = finalCat,
            category = (finalCat ?? guess.category).ToString(),
            MlText = mlText
        };
        ModelTouch.Touch(entity); // ⬅️

        _db.Add(entity);
        await _db.SaveChangesAsync(ct);

        return CreatedAtAction(nameof(GetById), new { id = entity.transaction_id }, entity);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<Transaction>> GetById(Guid id, CancellationToken ct)
    {
        var tx = await _db.Transactions.AsNoTracking()
            .FirstOrDefaultAsync(x => x.transaction_id == id, ct);
        return tx is null ? NotFound() : Ok(tx);
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] string? userId, [FromQuery] string? merchantId,
        [FromQuery] string? bankId, [FromQuery] string? walletId, CancellationToken ct)
    {
        var query = _db.Transactions.AsNoTracking();
        Guid? user = Guid.TryParse(userId, out Guid convertedUserId) ? convertedUserId : null;
        Guid? merchant = Guid.TryParse(merchantId, out Guid convertedMerchantId) ? convertedMerchantId : null;
        Guid? bank = Guid.TryParse(bankId, out Guid convertedBankId) ? convertedBankId : null;
        Guid? wallet = Guid.TryParse(walletId, out Guid convertedWalletId) ? convertedWalletId : null;

        if (user != null || merchant != null || bank != null || wallet != null)
        {
            query = query.Where((transaction) =>
                (user != null && ((transaction.from_user_id.HasValue && transaction.from_user_id.Value == user.Value) ||
                    (transaction.to_user_id.HasValue && transaction.to_user_id.Value == user.Value))) ||
                (merchant != null && ((transaction.from_merchant_id.HasValue && transaction.from_merchant_id.Value == merchant.Value) ||
                    (transaction.to_merchant_id.HasValue && transaction.to_merchant_id.Value == merchant.Value))) ||
                (bank != null && ((transaction.from_bank_id.HasValue && transaction.from_bank_id.Value == bank.Value) ||
                    (transaction.to_bank_id.HasValue && transaction.to_bank_id.Value == bank.Value))) ||
                (wallet != null && ((transaction.from_wallet_id.HasValue && transaction.from_wallet_id.Value == wallet.Value) ||
                    (transaction.to_wallet_id.HasValue && transaction.to_wallet_id.Value == wallet.Value)))
            );
        }
        var sql = query.ToQueryString();
        Console.WriteLine(sql);
        var rows = await query
            .OrderByDescending(transaction => transaction.transaction_timestamp)
            .Take(200)
            .ToListAsync(ct);
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
        ModelTouch.Touch(tx); // ⬅️

        await _db.SaveChangesAsync(ct);
        return NoContent();
    }
}
