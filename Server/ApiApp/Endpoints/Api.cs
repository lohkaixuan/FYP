// Endpoints/Api.cs — central route catalog (read-only)
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace ApiApp.Endpoints;

public static class Api
{
    public static void MapApi(this WebApplication app)
    {
        // Basic info
        app.MapGet("/info", () => Results.Ok(new
        {
            name = "ApiApp",
            version = "v1",
            time = DateTime.UtcNow
        }));

        // Human-friendly routes catalog (keep in sync with controllers)
        app.MapGet("/routes", () =>
        {
            var list = new[]
            {
                // ---------- AuthController ----------
                new { method = "POST", path = "/api/auth/register/user",                   controller = "Auth", action = "RegisterUser",            notes = "Create user + auto wallet" },
                new { method = "POST", path = "/api/auth/register/merchant-apply",         controller = "Auth", action = "RegisterMerchantApply",   notes = "User applies as merchant (doc upload)" },
                new { method = "POST", path = "/api/auth/admin/approve-merchant/{merchantId}", controller = "Auth", action = "AdminApproveMerchant", notes = "Admin approves merchant; flip role + merchant wallet" },
                new { method = "POST", path = "/api/auth/admin/approve-thirdparty/{userId}",   controller = "Auth", action = "AdminApproveThirdParty", notes = "Admin promotes user to third-party" },
                new { method = "POST", path = "/api/auth/register/thirdparty",             controller = "Auth", action = "RegisterThirdParty",      notes = "Register a third-party provider" },
                new { method = "POST", path = "/api/auth/login",                           controller = "Auth", action = "Login",                   notes = "Email/Phone + password or passcode → JWT" },
                new { method = "POST", path = "/api/auth/logout",                          controller = "Auth", action = "Logout",                  notes = "Invalidate stored JWT" },

                // ---------- UsersController ----------
                new { method = "GET",  path = "/api/users/me",                             controller = "Users", action = "Me",                     notes = "Current user profile (JWT)" },
                new { method = "GET",  path = "/api/users",                                controller = "Users", action = "List",                   notes = "List users" },
                new { method = "GET",  path = "/api/users/{id}",                           controller = "Users", action = "Get",                    notes = "Get user by id" },

                // ---------- WalletController ----------
                new { method = "GET", path = "/api/wallet/{id}",    controller = "Wallet", action = "Get",    notes = "User wallet details" },
                new { method = "POST", path = "/api/wallet/topup",    controller = "Wallet", action = "TopUp",    notes = "Bank → Wallet top-up (auto categorized)" },
                new { method = "POST", path = "/api/wallet/pay",       controller = "Wallet", action = "Pay",      notes = "Wallet → Wallet payment (standard/NFC/QR + auto category)" },
                new { method = "POST", path = "/api/wallet/transfer",  controller = "Wallet", action = "Transfer", notes = "A2A Wallet transfer (auto category)" },

                // ---------- BankAccountController ----------
                new { method = "GET",  path = "/api/bankaccount",                          controller = "BankAccount", action = "List",             notes = "List bank accounts" },
                new { method = "POST", path = "/api/bankaccount",                          controller = "BankAccount", action = "Create",           notes = "Create/link bank account" },

                // ---------- TransactionsController ----------
                new { method = "POST", path = "/api/transactions",                         controller = "Transactions", action = "Create",          notes = "Create tx (auto-categorized)" },
                new { method = "GET",  path = "/api/transactions",                         controller = "Transactions", action = "List",            notes = "List recent transactions" },
                new { method = "GET",  path = "/api/transactions/{id}",                    controller = "Transactions", action = "GetById",         notes = "Get tx by id" },
                new { method = "POST", path = "/api/transactions/categorize",              controller = "Transactions", action = "Categorize",      notes = "Run categorizer only (no insert)" },
                new { method = "PATCH",path = "/api/transactions/{id}/final-category",     controller = "Transactions", action = "SetFinal",        notes = "Override final category (updates 'category')" },

                // ---------- BudgetsController ----------
                new { method = "POST", path = "/api/budgets",                              controller = "Budgets", action = "Create",               notes = "Create budget window" },
                new { method = "GET",  path = "/api/budgets/summary/{userId}",             controller = "Budgets", action = "Summary",              notes = "Spend vs limit for active budgets" },

                // ---------- ProviderGatewayController ----------
                new { method = "GET",  path = "/api/providers/balance/{linkId}",           controller = "ProviderGateway", action = "GetBalance",   notes = "Query provider for a link balance" },

                // ---------- ReportController ----------
                new { method = "POST", path = "/api/report/monthly/generate",              controller = "Report", action = "Generate",              notes = "Generate & store monthly PDF report" },
                new { method = "GET",  path = "/api/report/{id}/download",                 controller = "Report", action = "Download",              notes = "Download stored report PDF" },
            };

            return Results.Ok(list);
        });
    }
}
