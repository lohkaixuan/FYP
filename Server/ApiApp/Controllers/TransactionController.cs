using Microsoft.AspNetCore.Mvc;
using ApiApp.Helpers;
using System.ComponentModel.DataAnnotations;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TransactionsController : ControllerBase
{
    private readonly INeonCrud _db;
    public TransactionsController(INeonCrud db) => _db = db;

    private const string Table = "transactions";
    private static class Col
    {
        public const string TransactionId = "transaction_id";
        public const string UserId = "user_id";
        public const string BankAccountId = "bank_account_id";
        public const string MerchantId = "merchant_id";
        public const string Amount = "amount";
        public const string OccurredAt = "occurred_at";
    }

    // GET /api/transactions?userId=...&limit=100
    [HttpGet]
    public async Task<IActionResult> GetMany([FromQuery] Guid? userId, [FromQuery] int? limit = 100)
    {
        if (userId is Guid uid)
        {
            var rows = await _db.Read(Table, $"{Col.UserId}=@uid", new Dictionary<string, object> { ["@uid"] = uid }, limit);
            return Ok(rows);
        }
        return Ok(await _db.Read(Table, limit: limit));
    }

    // GET /api/transactions/{id}
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetOne([FromRoute] Guid id)
    {
        var rows = await _db.Read(Table, $"{Col.TransactionId}=@id", new Dictionary<string, object> { ["@id"] = id }, 1);
        return rows.Count == 0 ? NotFound() : Ok(rows[0]);
    }

    public record CreateTransactionDto(
        [property: Required] Guid UserId,
        [property: Required] Guid BankAccountId,
        Guid? MerchantId,
        [property: Required] decimal Amount,
        DateTime? OccurredAt
    );

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTransactionDto dto)
    {
        var row = new Dictionary<string, object>
        {
            [Col.TransactionId] = Guid.NewGuid(),
            [Col.UserId] = dto.UserId,
            [Col.BankAccountId] = dto.BankAccountId,
            [Col.MerchantId] = dto.MerchantId,
            [Col.Amount] = dto.Amount,
            [Col.OccurredAt] = dto.OccurredAt ?? DateTime.UtcNow
        };
        var n = await _db.Add(Table, row);
        return n > 0 ? CreatedAtAction(nameof(GetOne), new { id = row[Col.TransactionId] }, row) : BadRequest();
    }

    public record UpdateTransactionDto(
        Guid? UserId,
        Guid? BankAccountId,
        Guid? MerchantId,
        decimal? Amount,
        DateTime? OccurredAt
    );

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpdateTransactionDto dto)
    {
        var patch = new Dictionary<string, object>();
        void Set(string c, object? v) { if (v is not null) patch[c] = v; }

        Set(Col.UserId, dto.UserId);
        Set(Col.BankAccountId, dto.BankAccountId);
        Set(Col.MerchantId, dto.MerchantId);
        Set(Col.Amount, dto.Amount);
        Set(Col.OccurredAt, dto.OccurredAt);

        if (patch.Count == 0) return BadRequest("No fields to update");
        var n = await _db.Update(Table, id, patch, Col.TransactionId);
        return n > 0 ? NoContent() : NotFound();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete([FromRoute] Guid id)
    {
        var n = await _db.Delete(Table, id, Col.TransactionId);
        return n > 0 ? NoContent() : NotFound();
    }
}
