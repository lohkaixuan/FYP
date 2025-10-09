// Endpoints/Api.cs
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using ApiApp.Helpers;
using System.ComponentModel.DataAnnotations;
using System.Collections.Generic;

namespace ApiApp.Endpoints;

public static class Api
{
    // call from Program.cs: app.MapApi(port);
    public static void MapApi(this WebApplication app, string port)
    {
        // ===========================
        // Users
        // ===========================
        var users = app.MapGroup("/api/users");

        users.MapGet("/", async (INeonCrud db, int? limit) =>
        {
            var rows = await db.Read("users", limit: limit ?? 100);
            return ResponseHelper.Ok(rows);
        });

        users.MapGet("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var rows = await db.Read(
                "users",
                "user_id=@id",
                new Dictionary<string, object> { ["@id"] = id },
                1);

            return rows.Count == 0
                ? ResponseHelper.NotFound("User not found")
                : ResponseHelper.Ok(rows[0]);
        });

        users.MapPost("/", async (INeonCrud db, CreateUserDto dto) =>
        {
            var row = new Dictionary<string, object>
            {
                ["user_id"] = Guid.NewGuid(),
                ["user_code"] = dto.UserCode,
                ["user_name"] = dto.UserName,
                ["email"] = dto.Email,
                ["phone_number"] = dto.PhoneNumber,
                ["ic_number"] = dto.ICNumber,
                ["role_id"] = dto.RoleId,
                ["is_merchant"] = dto.IsMerchant,
                ["merchant_docs_url"] = dto.MerchantDocsUrl,
                ["merchant_name"] = dto.MerchantName,
                ["password_hash"] = dto.PasswordHash
            };

            var n = await db.Add("users", row);
            return n > 0
                ? ResponseHelper.Created($"/api/users/{row["user_id"]}", row, "User created")
                : ResponseHelper.BadRequest("Failed to create user");
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
            return n > 0
                ? ResponseHelper.NoContent("User updated")
                : ResponseHelper.NotFound("User not found");
        });

        users.MapDelete("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var n = await db.Delete("users", id, "user_id");
            return n > 0
                ? ResponseHelper.NoContent("User deleted")
                : ResponseHelper.NotFound("User not found");
        });

        // ===========================
        // Bank Accounts
        // ===========================
        var accounts = app.MapGroup("/api/bank-accounts");

        accounts.MapGet("/", async (INeonCrud db, Guid? userId, int? limit) =>
        {
            if (userId is Guid uid)
            {
                var rows = await db.Read(
                    "bank_accounts",
                    "user_id=@uid",
                    new Dictionary<string, object> { ["@uid"] = uid },
                    limit ?? 100);

                return ResponseHelper.Ok(rows);
            }

            return ResponseHelper.Ok(await db.Read("bank_accounts", limit: limit ?? 100));
        });

        accounts.MapGet("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var rows = await db.Read(
                "bank_accounts",
                "bank_account_id=@id",
                new Dictionary<string, object> { ["@id"] = id },
                1);

            return rows.Count == 0
                ? ResponseHelper.NotFound("Bank account not found")
                : ResponseHelper.Ok(rows[0]);
        });

        accounts.MapPost("/", async (INeonCrud db, CreateBankAccountDto dto) =>
        {
            var row = new Dictionary<string, object>
            {
                ["bank_account_id"] = Guid.NewGuid(),
                ["account_number"] = dto.AccountNumber,
                ["user_id"] = dto.UserId,
                ["balance"] = dto.Balance,
                ["bank_name"] = dto.BankName,
                ["bank_code"] = dto.BankCode,
                ["account_type"] = dto.AccountType,
                ["currency"] = dto.Currency ?? "MYR",
                ["is_merchant_account"] = dto.IsMerchantAccount,
                ["merchant_id"] = dto.MerchantId
            };

            var n = await db.Add("bank_accounts", row);
            return n > 0
                ? ResponseHelper.Created($"/api/bank-accounts/{row["bank_account_id"]}", row, "Bank account created")
                : ResponseHelper.BadRequest("Failed to create bank account");
        });

        accounts.MapPut("/{id:guid}", async (INeonCrud db, Guid id, UpdateBankAccountDto dto) =>
        {
            var patch = new Dictionary<string, object>();
            void Set(string c, object? v) { if (v is not null) patch[c] = v; }

            Set("account_number", dto.AccountNumber);
            Set("balance", dto.Balance);
            Set("bank_name", dto.BankName);
            Set("bank_code", dto.BankCode);
            Set("account_type", dto.AccountType);
            Set("currency", dto.Currency);
            Set("is_merchant_account", dto.IsMerchantAccount);
            Set("merchant_id", dto.MerchantId);

            if (patch.Count == 0) return ResponseHelper.BadRequest("No fields to update");

            var n = await db.Update("bank_accounts", id, patch, "bank_account_id");
            return n > 0
                ? ResponseHelper.NoContent("Bank account updated")
                : ResponseHelper.NotFound("Bank account not found");
        });

        accounts.MapDelete("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var n = await db.Delete("bank_accounts", id, "bank_account_id");
            return n > 0
                ? ResponseHelper.NoContent("Bank account deleted")
                : ResponseHelper.NotFound("Bank account not found");
        });

        // ===========================
        // Transactions
        // ===========================
        var tx = app.MapGroup("/api/transactions");

        tx.MapGet("/", async (INeonCrud db, Guid? userId, int? limit) =>
        {
            if (userId is Guid uid)
            {
                var rows = await db.Read(
                    "transactions",
                    "user_id=@uid",
                    new Dictionary<string, object> { ["@uid"] = uid },
                    limit ?? 100);

                return ResponseHelper.Ok(rows);
            }

            return ResponseHelper.Ok(await db.Read("transactions", limit: limit ?? 100));
        });

        tx.MapGet("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var rows = await db.Read(
                "transactions",
                "transaction_id=@id",
                new Dictionary<string, object> { ["@id"] = id },
                1);

            return rows.Count == 0
                ? ResponseHelper.NotFound("Transaction not found")
                : ResponseHelper.Ok(rows[0]);
        });

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
            return n > 0
                ? ResponseHelper.Created($"/api/transactions/{row["transaction_id"]}", row, "Transaction created")
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
            return n > 0
                ? ResponseHelper.NoContent("Transaction updated")
                : ResponseHelper.NotFound("Transaction not found");
        });

        tx.MapDelete("/{id:guid}", async (INeonCrud db, Guid id) =>
        {
            var n = await db.Delete("transactions", id, "transaction_id");
            return n > 0
                ? ResponseHelper.NoContent("Transaction deleted")
                : ResponseHelper.NotFound("Transaction not found");
        });
    }
}

#region DTOs (shared with UsersController shape)
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
#endregion
