using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using ApiApp.Helpers;
using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;
using System.Text;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly INeonCrud _db;
    private readonly string _jwtKey;

    public AuthController(INeonCrud db)
    {
        _db = db;
        _jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
                  ?? throw new InvalidOperationException("JWT_KEY is not set");
    }

    [HttpPost("register")]
    public async Task<IResult> Register([FromBody] RegisterDto dto)
    {
        var hash = Sha256(dto.Passcode);

        // simple duplicate check by any provided identifier
        var where = new List<string>();
        var p = new Dictionary<string, object>();
        if (!string.IsNullOrWhiteSpace(dto.Email))        { where.Add("email=@e");         p["@e"] = dto.Email!; }
        if (!string.IsNullOrWhiteSpace(dto.PhoneNumber))  { where.Add("phone_number=@p");  p["@p"] = dto.PhoneNumber!; }
        if (!string.IsNullOrWhiteSpace(dto.UserCode))     { where.Add("user_code=@u");     p["@u"] = dto.UserCode!; }

        if (where.Count > 0)
        {
            var dup = await _db.Read("users", string.Join(" OR ", where), p, 1);
            if (dup.Count > 0) return ResponseHelper.BadRequest("User already exists");
        }

        var id = Guid.NewGuid();
        var row = new Dictionary<string, object>
        {
            ["user_id"] = id,
            ["user_code"] = dto.UserCode ?? $"U{Random.Shared.Next(100000,999999)}",
            ["user_name"] = dto.UserName ?? "User",
            ["email"] = dto.Email,
            ["phone_number"] = dto.PhoneNumber,
            ["ic_number"] = dto.ICNumber ?? "",
            ["role_id"] = dto.RoleId ?? Guid.Empty,
            ["is_merchant"] = dto.IsMerchant,
            ["merchant_name"] = dto.MerchantName,
            ["merchant_docs_url"] = dto.MerchantDocsUrl,
            ["password_hash"] = hash
        };
        var n = await _db.Add("users", row);
        if (n <= 0) return ResponseHelper.BadRequest("Failed to register user");

        var token = JwtHelper.IssueToken(id, _jwtKey);
        return ResponseHelper.Created($"/api/users/{id}", new { token, user_id = id }, "Registered");
    }

    [HttpPost("login")]
    public async Task<IResult> Login([FromBody] LoginDto dto)
    {
        var p = new Dictionary<string, object>();
        string where;
        if (!string.IsNullOrWhiteSpace(dto.UserCode))      { where = "user_code=@x";     p["@x"] = dto.UserCode!; }
        else if (!string.IsNullOrWhiteSpace(dto.Email))    { where = "email=@x";         p["@x"] = dto.Email!; }
        else if (!string.IsNullOrWhiteSpace(dto.PhoneNumber)) { where = "phone_number=@x"; p["@x"] = dto.PhoneNumber!; }
        else return ResponseHelper.BadRequest("Provide user_code or email or phone");

        var rows = await _db.Read("users", where, p, 1);
        if (rows.Count == 0) return ResponseHelper.NotFound("User not found");

        var ok = rows[0].TryGetValue("password_hash", out var saved) && (string?)saved == Sha256(dto.Passcode);
        if (!ok) return ResponseHelper.Unauthorized("Invalid passcode");

        var id = Guid.Parse(rows[0]["user_id"].ToString()!);
        var token = JwtHelper.IssueToken(id, _jwtKey);
        return ResponseHelper.Ok(new { token, user_id = id }, "Logged in");
    }

    [Authorize]
    [HttpPost("logout")]
    public IResult Logout() => ResponseHelper.Ok<object?>(null, "Logged out");

    // ---------- DTOs & helpers ----------
    public record RegisterDto(
        string? UserCode,
        string? UserName,
        string? Email,
        string? PhoneNumber,
        string? ICNumber,
        Guid? RoleId,
        bool IsMerchant,
        string? MerchantName,
        string? MerchantDocsUrl,
        [property: Required] string Passcode
    );
    public record LoginDto(string? UserCode, string? Email, string? PhoneNumber, [property: Required] string Passcode);

    private static string Sha256(string input)
    {
        using var sha = SHA256.Create();
        var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes);
    }
}
