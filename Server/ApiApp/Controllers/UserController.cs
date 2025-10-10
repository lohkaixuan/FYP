using Microsoft.AspNetCore.Mvc;
using ApiApp.Helpers;
using System.ComponentModel.DataAnnotations;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly INeonCrud _db;

    // Table & column names (snake_case, common in Postgres)
    private const string Table = "users";
    private static class Col
    {
        public const string UserId = "user_id";
        public const string UserCode = "user_code";
        public const string UserName = "user_name";
        public const string Email = "email";
        public const string PhoneNumber = "phone_number";
        public const string ICNumber = "ic_number";
        public const string RoleId = "role_id";
        public const string IsMerchant = "is_merchant";
        public const string MerchantDocsUrl = "merchant_docs_url";
        public const string MerchantName = "merchant_name";
        public const string PasswordHash = "password_hash";
    }

    public UsersController(INeonCrud db) => _db = db;

    // GET /api/users?limit=100
    [HttpGet]
    public async Task<IActionResult> GetMany([FromQuery] int? limit = 100)
    {
        var rows = await _db.Read(Table, limit: limit);
        return Ok(rows);
    }

    // GET /api/users/{id}
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetOne([FromRoute] Guid id)
    {
        var rows = await _db.Read(Table, $"{Col.UserId}=@id", new Dictionary<string, object> { ["@id"] = id }, 1);
        return rows.Count == 0 ? NotFound() : Ok(rows[0]);
    }

    public record CreateUserDto(
        [property: Required] string UserCode,
        [property: Required] string UserName,
        string? Email,
        string? PhoneNumber,
        [property: Required] string ICNumber,
        [property: Required] Guid RoleId,
        bool IsMerchant,
        string? MerchantDocsUrl,
        string? MerchantName,
        [property: Required] string PasswordHash
    );

    // POST /api/users
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateUserDto dto)
    {
        var data = new Dictionary<string, object>
        {
            [Col.UserId] = Guid.NewGuid(),
            [Col.UserCode] = dto.UserCode,
            [Col.UserName] = dto.UserName,
            [Col.Email] = dto.Email,
            [Col.PhoneNumber] = dto.PhoneNumber,
            [Col.ICNumber] = dto.ICNumber,
            [Col.RoleId] = dto.RoleId,
            [Col.IsMerchant] = dto.IsMerchant,
            [Col.MerchantDocsUrl] = dto.MerchantDocsUrl,
            [Col.MerchantName] = dto.MerchantName,
            [Col.PasswordHash] = dto.PasswordHash
        };
        var n = await _db.Add(Table, data);
        return n > 0 ? CreatedAtAction(nameof(GetOne), new { id = data[Col.UserId] }, data) : BadRequest();
    }

    public record UpdateUserDto(
        string? UserCode,
        string? UserName,
        string? Email,
        string? PhoneNumber,
        string? ICNumber,
        Guid? RoleId,
        bool? IsMerchant,
        string? MerchantDocsUrl,
        string? MerchantName,
        string? PasswordHash
    );

    // PUT /api/users/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpdateUserDto dto)
    {
        var patch = new Dictionary<string, object>();
        void Set(string col, object? val) { if (val is not null) patch[col] = val; }

        Set(Col.UserCode, dto.UserCode);
        Set(Col.UserName, dto.UserName);
        Set(Col.Email, dto.Email);
        Set(Col.PhoneNumber, dto.PhoneNumber);
        Set(Col.ICNumber, dto.ICNumber);
        Set(Col.RoleId, dto.RoleId);
        Set(Col.IsMerchant, dto.IsMerchant);
        Set(Col.MerchantDocsUrl, dto.MerchantDocsUrl);
        Set(Col.MerchantName, dto.MerchantName);
        Set(Col.PasswordHash, dto.PasswordHash);

        if (patch.Count == 0) return BadRequest("No fields to update");

        var n = await _db.Update(Table, id: 0, patch, idColumn: Col.UserId); // idColumn is user_id, value passed via parameters below

        // since Update() signature in helper expects id separately, call it like:
        // return (await _db.Update(Table, id, patch, Col.UserId)) > 0 ? NoContent() : NotFound();
        // (keep the line above if your helper signature matches)

        // Using the correct call:
        var rows = await _db.Read(Table, $"{Col.UserId}=@id", new Dictionary<string, object> { ["@id"] = id }, 1);
        if (rows.Count == 0) return NotFound();
        var n2 = await _db.Update(Table, id, patch, Col.UserId);
        return n2 > 0 ? NoContent() : NotFound();
    }

    // DELETE /api/users/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete([FromRoute] Guid id)
    {
        var n = await _db.Delete(Table, id, Col.UserId);
        return n > 0 ? NoContent() : NotFound();
    }
}
