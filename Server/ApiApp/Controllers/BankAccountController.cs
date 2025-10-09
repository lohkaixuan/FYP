using Microsoft.AspNetCore.Mvc;
using ApiApp.Helpers;
using System.ComponentModel.DataAnnotations;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BankAccountsController : ControllerBase
{
    private readonly INeonCrud _db;
    public BankAccountsController(INeonCrud db) => _db = db;

    private const string Table = "bank_accounts";
    private static class Col
    {
        public const string BankAccountId = "bank_account_id";
        public const string AccountNumber = "account_number";
        public const string Balance = "balance";
        public const string UserId = "user_id";
        public const string BankName = "bank_name";
        public const string BankCode = "bank_code";
        public const string AccountType = "account_type";
        public const string Currency = "currency";
        public const string IsMerchantAccount = "is_merchant_account";
        public const string MerchantId = "merchant_id";
    }

    // GET /api/bankaccounts?userId=...&limit=100
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

    // GET /api/bankaccounts/{id}
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetOne(Guid id)
    {
        var rows = await _db.Read(Table, $"{Col.BankAccountId}=@id", new Dictionary<string, object> { ["@id"] = id }, 1);
        return rows.Count == 0 ? NotFound() : Ok(rows[0]);
    }

    public record CreateBankAccountDto(
        [property: Required] string AccountNumber,
        [property: Required] Guid UserId,
        decimal Balance,
        string? BankName,
        string? BankCode,
        string? AccountType,
        string? Currency,
        bool IsMerchantAccount = false,
        Guid? MerchantId = null
    );

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBankAccountDto dto)
    {
        var row = new Dictionary<string, object>
        {
            [Col.BankAccountId] = Guid.NewGuid(),
            [Col.AccountNumber] = dto.AccountNumber,
            [Col.UserId] = dto.UserId,
            [Col.Balance] = dto.Balance,
            [Col.BankName] = dto.BankName,
            [Col.BankCode] = dto.BankCode,
            [Col.AccountType] = dto.AccountType,
            [Col.Currency] = dto.Currency ?? "MYR",
            [Col.IsMerchantAccount] = dto.IsMerchantAccount,
            [Col.MerchantId] = dto.MerchantId
        };
        var n = await _db.Add(Table, row);
        return n > 0 ? CreatedAtAction(nameof(GetOne), new { id = row[Col.BankAccountId] }, row) : BadRequest();
    }

    public record UpdateBankAccountDto(
        string? AccountNumber,
        decimal? Balance,
        string? BankName,
        string? BankCode,
        string? AccountType,
        string? Currency,
        bool? IsMerchantAccount,
        Guid? MerchantId
    );

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpdateBankAccountDto dto)
    {
        var patch = new Dictionary<string, object>();
        void Set(string c, object? v) { if (v is not null) patch[c] = v; }

        Set(Col.AccountNumber, dto.AccountNumber);
        Set(Col.Balance, dto.Balance);
        Set(Col.BankName, dto.BankName);
        Set(Col.BankCode, dto.BankCode);
        Set(Col.AccountType, dto.AccountType);
        Set(Col.Currency, dto.Currency);
        Set(Col.IsMerchantAccount, dto.IsMerchantAccount);
        Set(Col.MerchantId, dto.MerchantId);

        if (patch.Count == 0) return BadRequest("No fields to update");
        var n = await _db.Update(Table, id, patch, Col.BankAccountId);
        return n > 0 ? NoContent() : NotFound();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete([FromRoute] Guid id)
    {
        var n = await _db.Delete(Table, id, Col.BankAccountId);
        return n > 0 ? NoContent() : NotFound();
    }
}
