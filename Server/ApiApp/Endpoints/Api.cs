// Endpoints/Api.cs — central route catalog (read-only)
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace ApiApp.Endpoints;

public static class Api
{
    public static void MapApi(this WebApplication app)
    {
        
        // Info
        app.MapGet("/info", () => Results.Ok(new
        {
            name = "ApiApp",
            version = "v1",
            time = DateTime.UtcNow
        }));

        // Routes catalog (for easy reference & maintenance)
        app.MapGet("/routes", () =>
        {
            // Keep this list in sync with Controllers
            var list = new[]
            {
                // ---------- AuthController ----------
                new { method = "POST", path = "/api/auth/register/user",            controller = "Auth",        action = "RegisterUser",          notes = "Create user + auto wallet" },
                new { method = "POST", path = "/api/auth/register/merchant-apply",  controller = "Auth",        action = "RegisterMerchantApply", notes = "User applies as merchant (doc upload)" },
                new { method = "POST", path = "/api/auth/admin/approve-merchant/{merchantId}", controller = "Auth", action = "AdminApproveMerchant", notes = "Admin approves merchant; flip role + merchant wallet" },
                new { method = "POST", path = "/api/auth/login",                    controller = "Auth",        action = "Login",                 notes = "Email+password | Phone+password | Passcode → JWT + user row" },
                new { method = "POST", path = "/api/auth/logout",                   controller = "Auth",        action = "Logout",                notes = "Invalidate stored JWT" },

                // ---------- UsersController ----------
                new { method = "GET",  path = "/api/users/me",                      controller = "Users",       action = "Me",                    notes = "Current user profile (JWT)" },
                new { method = "GET",  path = "/api/users",                         controller = "Users",       action = "List",                  notes = "List users" },
                new { method = "GET",  path = "/api/users/{id}",                    controller = "Users",       action = "Get",                   notes = "Get user by id" },

                // ---------- WalletController ----------
                new { method = "POST", path = "/api/wallet/topup",                  controller = "Wallet",      action = "TopUp",                 notes = "From bank → wallet, inserts transaction" },
                new { method = "POST", path = "/api/wallet/pay",                    controller = "Wallet",      action = "Pay",                   notes = "Wallet → wallet (e.g., user→merchant), inserts transaction & syncs user_balance" },
                new { method = "POST", path = "/api/wallet/transfer",               controller = "Wallet",      action = "Transfer",              notes = "Wallet → wallet (user→user), inserts transaction & syncs user_balance" },

                // ---------- BankAccountController ----------
                new { method = "GET",  path = "/api/bankaccount",                  controller = "BankAccount", action = "List",                  notes = "List bank accounts" },
                new { method = "POST", path = "/api/bankaccount",                  controller = "BankAccount", action = "Create",                notes = "Create/link bank account" },

                // ---------- TransactionController ----------
                new { method = "GET",  path = "/api/transaction",                  controller = "Transaction", action = "List",                  notes = "List recent transactions" },
                new { method = "GET",  path = "/api/transaction/by-wallet/{walletId}", controller = "Transaction", action = "ByWallet",         notes = "Transactions involving a wallet" },
            };

            return Results.Ok(list);
        });
    }
}
