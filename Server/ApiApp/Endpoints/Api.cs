// Endpoints/Api.cs
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using ApiApp.Helpers;
using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;

namespace ApiApp.Endpoints;

public static class Api
{
    public static void MapApi(this WebApplication app, string port)
    {
        var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
                     ?? throw new InvalidOperationException("JWT_KEY is not set");

        // ===========================
        // AUTH  (/api/auth)
        // ===========================
        var auth = app.MapGroup("/api/auth");

        // Register (email/phone/user_code + passcode)
        auth.MapPost("/register", async (INeonCrud db, RegisterDto dto) =>
        {
            // very simple passcode hash (demo): SHA256; replace with PBKDF2/bcrypt in prod
            var hash = Sha256(dto.Passcode);

            // check duplicate by email/phone/user_code (whichever provided)
            var whereParts = new List<string>();
            var p = new Dictionary<string, object>();
            if (!string.IsNullOrWhiteSpace(dto.Email)) { whereParts.Add("email=@e"); p["@e"] = dto.Email!; }
            if (!string.IsNullOrWhiteSpace(dto.PhoneNumber)) { whereParts.Add("phone_number=@p"); p["@p"] = dto.PhoneNumber!; }
            if (!string.IsNullOrWhiteSpace(dto.UserCode)) { whereParts.Add("user_code=@u"); p["@u"] = dto.UserCode!; }

            if (whereParts.Count > 0)
            {
                var dup = await db.Read("users", string.Join(" OR ", whereParts), p, 1);
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
                ["merchant_docs_url"] = dto.MerchantDocsUrl,
                ["merchant_name"] = dto.MerchantName,
                ["password_hash"] = hash
            };
            var n = await db.Add("users", row);
            if (n <= 0) return ResponseHelper.BadRequest("Failed to register user");
            var token = JwtHelper.IssueToken(id, jwtKey);
            return ResponseHelper.Created($"/api/users/{id}", new { token, user_id = id }, "Registered");
        });

        // Login (by passcode + identifier: user_code or email or phone)
        auth.MapPost("/login", async (INeonCrud db, LoginDto dto) =>
        {
            var p = new Dictionary<string, object>();
            string where;
            if (!string.IsNullOrWhiteSpace(dto.UserCode)) { where = "user_code=@x"; p["@x"] = dto.UserCode!; }
            else if (!string.IsNullOrWhiteSpace(dto.Email)) { where = "email=@x"; p["@x"] = dto.Email!; }
            else if (!string.IsNullOrWhiteSpace(dto.PhoneNumber)) { where = "phone_number=@x"; p["@x"] = dto.PhoneNumber!; }
            else return ResponseHelper.BadRequest("Provide user_code or email or phone");

            var rows = await db.Read("users", where, p, 1);
            if (rows.Count == 0) return ResponseHelper.NotFound("User not found");

            var user = rows[0];
            var ok = user.TryGetValue("password_hash", out var saved) && (string?)saved == Sha256(dto.Passcode);
            if (!ok) return ResponseHelper.Unauthorized("Invalid passcode");

            var id = Guid.Parse(user["user_id"].ToString()!);
            var token = JwtHelper.IssueToken(id, jwtKey);
            return ResponseHelper.Ok(new { token, user_id = id }, "Logged in");
        });

        // Logout (stateless JWT: client just drops token; optional revoke store later)
        auth.MapPost("/logout", [Authorize] () => ResponseHelper.Ok<object?>(null, "Logged out"));

        // Passcode-login alias for frontend keypad flow
        auth.MapPost("/passcode-login", async (INeonCrud db, PasscodeLoginDto dto) =>
        {
            var rows = await db.Read("users", "user_code=@u", new Dictionary<string, object>{{"@u", dto.UserCode}}, 1);
            if (rows.Count == 0) return ResponseHelper.NotFound("User not found");
            var user = rows[0];
            var ok = user.TryGetValue("password_hash", out var saved) && (string?)saved == Sha256(dto.Passcode);
            if (!ok) return ResponseHelper.Unauthorized("Invalid passcode");
            var id = Guid.Parse(user["user_id"].ToString()!);
            var token = JwtHelper.IssueToken(id, jwtKey);
            return ResponseHelper.Ok(new { token, user_id = id }, "Logged in");
        });

        // ===========================
        // USERS  (/api/users)
        // ===========================
        var users = app.MapGroup("/api/users").RequireAuthorization();

        users.MapGet("/", async (INeonCrud db, int? limit) =>
        {
            var rows = await db.Read("users", limit: limit ?? 100);
            return ResponseHelper.Ok(rows);
        });

        users.MapGet("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var rows = await db.Read("users", "user_id=@id", new Dictionary<string, object> { ["@id"] = id }, 1);
            return rows.Count == 0 ? ResponseHelper.NotFound("User not found") : ResponseHelper.Ok(rows[0]);
        });

        users.MapPut("/{id:guid}", async (INeonCrud db, Guid id, UpdateUserDto dto) =>
        {
            var patch = new Dictionary<string, object>();
            void Set(string k, object? v) { if (v is not null) patch[k] = v; }
            Set("user_code", dto.UserCode);
            Set("user_name", dto.UserName);
            Set("email", dto.Email);
            Set("phone_number", dto.PhoneNumber);
            Set("ic_number", dto.ICNumber);
            Set("role_id", dto.RoleId);
            Set("is_merchant", dto.IsMerchant);
            Set("merchant_docs_url", dto.MerchantDocsUrl);
            Set("merchant_name", dto.MerchantName);
            Set("password_hash", dto.PasswordHash);

            if (patch.Count == 0) return ResponseHelper.BadRequest("No fields to update");
            var n = await db.Update("users", id, patch, "user_id");
            return n > 0 ? ResponseHelper.NoContent("User updated") : ResponseHelper.NotFound("User not found");
        });

        users.MapDelete("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var n = await db.Delete("users", id, "user_id");
            return n > 0 ? ResponseHelper.NoContent("User deleted") : ResponseHelper.NotFound("User not found");
        });

        // ===========================
        // BANK ACCOUNTS  (/api/bank-accounts)
        // ===========================
        var accounts = app.MapGroup("/api/bank-accounts").RequireAuthorization();

        // Add
        accounts.MapPost("/", async (INeonCrud db, CreateBankAccountDto dto) =>
        {
            var row = new Dictionary<string, object>
            {
                ["bank_account_id"] = Guid.NewGuid(),
                ["account_number"]  = dto.AccountNumber,
                ["user_id"]         = dto.UserId,
                ["balance"]         = dto.Balance,
                ["bank_name"]       = dto.BankName,
                ["bank_code"]       = dto.BankCode,
                ["account_type"]    = dto.AccountType,
                ["currency"]        = dto.Currency ?? "MYR",
                ["is_merchant_account"] = dto.IsMerchantAccount,
                ["merchant_id"]     = dto.MerchantId
            };
            var n = await db.Add("bank_accounts", row);
            return n > 0
                ? ResponseHelper.Created($"/api/bank-accounts/{row["bank_account_id"]}", row, "Bank account created")
                : ResponseHelper.BadRequest("Failed to create bank account");
        });

        // Get many (by user) & balance & last transactions
        accounts.MapGet("/", async (INeonCrud db, Guid? userId, int? limit) =>
        {
            if (userId is Guid uid)
                return ResponseHelper.Ok(await db.Read("bank_accounts", "user_id=@uid", new Dictionary<string, object>{{"@uid", uid}}, limit ?? 100));
            return ResponseHelper.Ok(await db.Read("bank_accounts", limit: limit ?? 100));
        });

        accounts.MapGet("/{id:guid}/balance", async (INeonCrud db, Guid id) =>
        {
            var rows = await db.Read("bank_accounts","bank_account_id=@id", new Dictionary<string,object>{{"@id", id}}, 1);
            return rows.Count == 0 ? ResponseHelper.NotFound("Bank account not found")
                                   : ResponseHelper.Ok(new { balance = rows[0]["balance"], currency = rows[0].GetValueOrDefault("currency","MYR") });
        });

        accounts.MapGet("/{id:guid}/transactions", async (INeonCrud db, Guid id, int? limit) =>
        {
            var rows = await db.Read("transactions","bank_account_id=@id", new Dictionary<string,object>{{"@id", id}}, limit ?? 50);
            return ResponseHelper.Ok(rows, "Transactions");
        });

        // Make payment: deduct from user's bank account and create a transaction to merchant
        accounts.MapPost("/{id:guid}/pay", async (INeonCrud db, Guid id, MakePaymentDto dto) =>
        {
            // 1) check balance
            var accRows = await db.Read("bank_accounts", "bank_account_id=@id", new Dictionary<string, object>{{"@id", id}}, 1);
            if (accRows.Count == 0) return ResponseHelper.NotFound("Bank account not found");
            var acc = accRows[0];
            var bal = Convert.ToDecimal(acc["balance"]);
            if (bal < dto.Amount) return ResponseHelper.BadRequest("Insufficient funds");

            // 2) deduct balance (NOTE: non-atomic demo; for production wrap in SQL txn)
            var n1 = await db.Update("bank_accounts", id, new Dictionary<string, object> { ["balance"] = bal - dto.Amount }, "bank_account_id");
            if (n1 <= 0) return ResponseHelper.ServerError("Failed to update balance");

            // 3) record transaction
            var txId = Guid.NewGuid();
            var tx = new Dictionary<string, object>
            {
                ["transaction_id"] = txId,
                ["user_id"] = Guid.Parse(acc["user_id"].ToString()!),
                ["bank_account_id"] = id,
                ["merchant_id"] = dto.MerchantId,
                ["amount"] = dto.Amount,
                ["occurred_at"] = DateTime.UtcNow
            };
            var n2 = await db.Add("transactions", tx);
            if (n2 <= 0) return ResponseHelper.ServerError("Failed to create transaction");

            return ResponseHelper.Ok(new { transaction_id = txId, new_balance = bal - dto.Amount }, "Payment successful");
        });

        // ===========================
        // TRANSACTIONS  (/api/transactions)
        // ===========================
        var tx = app.MapGroup("/api/transactions").RequireAuthorization();

        tx.MapGet("/", async (INeonCrud db, Guid? userId, int? limit) =>
        {
            if (userId is Guid uid)
                return ResponseHelper.Ok(await db.Read("transactions", "user_id=@uid", new Dictionary<string, object>{{"@uid", uid}}, limit ?? 100));
            return ResponseHelper.Ok(await db.Read("transactions", limit: limit ?? 100));
        });

        tx.MapGet("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var rows = await db.Read("transactions", "transaction_id=@id", new Dictionary<string, object>{{"@id", id}}, 1);
            return rows.Count == 0 ? ResponseHelper.NotFound("Transaction not found") : ResponseHelper.Ok(rows[0]);
        });

        // create/update/delete still possible if you want them open:
        tx.MapPost("/", async (INeonCrud db, CreateTransactionDto dto) =>
        {
            var row = new Dictionary<string, object>
            {
                ["transaction_id"] = Guid.NewGuid(),
                ["user_id"] = dto.UserId,
                ["bank_account_id"] = dto.BankAccountId,
                ["merchant_id"] = dto.MerchantId,
                ["amount"] = dto.Amount,
                ["occurred_at"] = dto.OccurredAt ?? DateTime.UtcNow
            };
            var n = await db.Add("transactions", row);
            return n > 0 ? ResponseHelper.Created($"/api/transactions/{row["transaction_id"]}", row, "Transaction created")
                         : ResponseHelper.BadRequest("Failed to create transaction");
        });

        tx.MapPut("/{id:guid}", async (INeonCrud db, Guid id, UpdateTransactionDto dto) =>
        {
            var patch = new Dictionary<string, object>();
            void Set(string c, object? v) { if (v is not null) patch[c] = v; }
            Set("user_id", dto.UserId);
            Set("bank_account_id", dto.BankAccountId);
            Set("merchant_id", dto.MerchantId);
            Set("amount", dto.Amount);
            Set("occurred_at", dto.OccurredAt);
            if (patch.Count == 0) return ResponseHelper.BadRequest("No fields to update");
            var n = await db.Update("transactions", id, patch, "transaction_id");
            return n > 0 ? ResponseHelper.NoContent("Transaction updated") : ResponseHelper.NotFound("Transaction not found");
        });

        tx.MapDelete("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var n = await db.Delete("transactions", id, "transaction_id");
            return n > 0 ? ResponseHelper.NoContent("Transaction deleted") : ResponseHelper.NotFound("Transaction not found");
        });
    }

    // ===== util =====
    private static string Sha256(string input)
    {
        using var sha = SHA256.Create();
        var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes); // uppercase hex
    }
}

// ===== DTOs =====
public record RegisterDto(
    string? UserCode,
    string? UserName,
    string? Email,
    string? PhoneNumber,
    string? ICNumber,
    Guid? RoleId,
    bool IsMerchant,
    string? MerchantDocsUrl,
    string? MerchantName,
    [property: Required] string Passcode
);

public record LoginDto(
    string? UserCode,
    string? Email,
    string? PhoneNumber,
    [property: Required] string Passcode
);

public record PasscodeLoginDto([property: Required] string UserCode, [property: Required] string Passcode);

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

public record CreateTransactionDto(
    [property: Required] Guid UserId,
    [property: Required] Guid BankAccountId,
    Guid? MerchantId,
    [property: Required] decimal Amount,
    DateTime? OccurredAt
);

public record UpdateTransactionDto(
    Guid? UserId,
    Guid? BankAccountId,
    Guid? MerchantId,
    decimal? Amount,
    DateTime? OccurredAt
);

public record MakePaymentDto([property: Required] Guid MerchantId, [property: Required] decimal Amount);
