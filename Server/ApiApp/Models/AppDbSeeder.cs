// File: ApiApp/Models/AppDbSeeder.cs
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models;

public static class AppDbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync(); // ensures tables incl. budgets are created

        // ===== monthly window (UTC) =====
        var nowUtc = DateTime.UtcNow;
        var startOfMonthUtc = new DateTime(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var endOfMonthUtc   = startOfMonthUtc.AddMonths(1).AddTicks(-1);

        // ===== roles =====
        var roleUserId     = Guid.Parse("11111111-1111-1111-1111-111111111001");
        var roleMerchantId = Guid.Parse("11111111-1111-1111-1111-111111111002");
        var roleAdminId    = Guid.Parse("11111111-1111-1111-1111-111111111003");
        var roleProviderId = Guid.Parse("11111111-1111-1111-1111-111111111004");

        await EnsureRoleAsync(db, roleUserId,     "user");
        await EnsureRoleAsync(db, roleMerchantId, "merchant");
        await EnsureRoleAsync(db, roleAdminId,    "admin");
        await EnsureRoleAsync(db, roleProviderId, "bank provider");

        // ===== users / merchant =====
        var admin = await EnsureUserAsync(db, new User{
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000001"),
            UserName = "Admin",
            Email = "admin@example.com",
            PhoneNumber = "+60 3-8888 0000",
            ICNumber = "900101-14-0001",
            UserPassword = "Admin@123", // TEST ONLY
            RoleId = roleAdminId
        });

        var user1 = await EnsureUserAsync(db, new User{
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000003"),
            UserName = "Mei User",
            Email = "mei.user@gmail.com",
            PhoneNumber = "+60 11-2233 4455",
            ICNumber = "000505-14-3333",
            UserPassword = "User1@123", // TEST ONLY
            RoleId = roleUserId
        });
        var user1Wallet = await EnsureWalletAsync(db, userId: user1.UserId);

        var user2 = await EnsureUserAsync(db, new User{
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000004"),
            UserName = "John User",
            Email = "john.user@gmail.com",
            PhoneNumber = "+60 19-111 2222",
            ICNumber = "010606-10-4444",
            UserPassword = "User2@123", // TEST ONLY
            RoleId = roleUserId
        });
        var user2Wallet = await EnsureWalletAsync(db, userId: user2.UserId);

        var merchantOwner = await EnsureUserAsync(db, new User{
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000002"),
            UserName = "Ali Merchant",
            Email = "ali@shop.com",
            PhoneNumber = "+60 12-345 6789",
            ICNumber = "970404-10-2222",
            UserPassword = "Merchant@123", // TEST ONLY
            RoleId = roleMerchantId
        });

        var merchant = await EnsureMerchantAsync(db, new Merchant{
            MerchantId = Guid.Parse("22222222-2222-2222-2222-000000000001"),
            MerchantName = "Nasi Lemak House",
            MerchantPhoneNumber = "+60 12-888 7777",
            MerchantDocUrl = "https://example.com/docs/nasilemak.pdf",
            OwnerUserId = merchantOwner.UserId
        });
        Touch(merchant); await db.SaveChangesAsync();

        var merchantWallet = await EnsureWalletAsync(db, merchantId: merchant.MerchantId);

        // ===== bank accts =====
        var user1Bank1 = await EnsureBankAsync(db, new BankAccount{
            BankAccountNumber   = "9001 00 000111",
            BankUsername        = "mei_user",
            BankUserPassword    = "bankPass1", // TEST ONLY
            BankUserBalance     = 1500m,
            BankType            = "RHB",
            BankAccountCategory = "personal",
            UserId              = user1.UserId
        });

        var user1Bank2 = await EnsureBankAsync(db, new BankAccount{
            BankAccountNumber   = "9001 00 000112",
            BankUsername        = "mei_user2",
            BankUserPassword    = "bankPass2", // TEST ONLY
            BankUserBalance     = 800m,
            BankType            = "Maybank",
            BankAccountCategory = "personal",
            UserId              = user1.UserId
        });

        var user2Bank1 = await EnsureBankAsync(db, new BankAccount{
            BankAccountNumber   = "7800 22 000199",
            BankUsername        = "john_user",
            BankUserPassword    = "bankPassJ", // TEST ONLY
            BankUserBalance     = 600m,
            BankType            = "CIMB",
            BankAccountCategory = "personal",
            UserId              = user2.UserId
        });

        var merchantBank = await EnsureBankAsync(db, new BankAccount{
            BankAccountNumber   = "7800 22 000223",
            BankUsername        = "merchant_ali",
            BankUserPassword    = "bankPassM", // TEST ONLY
            BankUserBalance     = 5000m,
            BankType            = "CIMB",
            BankAccountCategory = "merchant",
            MerchantId          = merchant.MerchantId
        });

        // ===== budgets (this creates 'budgets' table via migration) =====
        await UpsertMonthlyBudgetsAsync(db, user1.UserId, startOfMonthUtc, endOfMonthUtc, new()
        {
            { "TopUp", 0m }, { "Food", 400m }, { "Groceries", 500m },
            { "Transport", 200m }, { "Bills", 300m }, { "Entertainment", 150m },
        });
        await UpsertMonthlyBudgetsAsync(db, user2.UserId, startOfMonthUtc, endOfMonthUtc, new()
        {
            { "TopUp", 0m }, { "Food", 300m }, { "Groceries", 400m },
            { "Transport", 150m }, { "Bills", 250m }, { "Entertainment", 120m },
        });

        // ===== demo txns (auto category) =====
        await TopUpAsync(db, user1Wallet.wallet_id, user1Bank1.BankAccountId, 120m);
        await PayAsync(db, user1Wallet.wallet_id, merchantWallet.wallet_id, 35.50m,
            item: "Nasi Lemak + Teh Tarik", detail: "Lunch order @ Nasi Lemak House");
        await TransferAsync(db, user1Wallet.wallet_id, user2Wallet.wallet_id, 10m, detail: "Split bill for lunch");

        // ===== report =====
        await PrintSummaryAsync(db, admin, new [] { user1, user2 }, merchant, merchantOwner);
    }

    // ---------------- helpers (timestamp-safe) ----------------

    // set updated timestamp only if the entity exposes such a property
    private static void Touch(object entity)
    {
        var t = entity.GetType();
        var p1 = t.GetProperty("LastUpdate");
        if (p1 is not null && p1.PropertyType == typeof(DateTime))
            p1.SetValue(entity, DateTime.UtcNow);

        var p2 = t.GetProperty("last_update");
        if (p2 is not null && p2.PropertyType == typeof(DateTime))
            p2.SetValue(entity, DateTime.UtcNow);
    }

    private static async Task<Role> EnsureRoleAsync(AppDbContext db, Guid id, string name)
    {
        var existing = await db.Roles.FirstOrDefaultAsync(r => r.RoleId == id);
        if (existing is null)
        {
            existing = new Role { RoleId = id, RoleName = name };
            db.Roles.Add(existing);
            await db.SaveChangesAsync();
        }
        return existing;
    }

    private static async Task<User> EnsureUserAsync(AppDbContext db, User u)
    {
        var existing = await db.Users.FirstOrDefaultAsync(x => x.UserId == u.UserId || x.Email == u.Email);
        if (existing is null)
        {
            Touch(u);
            db.Users.Add(u);
            await db.SaveChangesAsync();
            return u;
        }
        existing.UserName = u.UserName;
        existing.PhoneNumber = u.PhoneNumber;
        existing.UserPassword = u.UserPassword; // TEST ONLY
        existing.RoleId = u.RoleId;
        Touch(existing);
        await db.SaveChangesAsync();
        return existing;
    }

    private static async Task<Merchant> EnsureMerchantAsync(AppDbContext db, Merchant m)
    {
        var existing = await db.Merchants.FirstOrDefaultAsync(x => x.MerchantId == m.MerchantId);
        if (existing is null)
        {
            Touch(m);
            db.Merchants.Add(m);
            await db.SaveChangesAsync();
            return m;
        }
        existing.MerchantPhoneNumber = m.MerchantPhoneNumber;
        existing.MerchantDocUrl = m.MerchantDocUrl;
        existing.OwnerUserId = m.OwnerUserId;
        Touch(existing);
        await db.SaveChangesAsync();
        return existing;
    }

    private static async Task<Wallet> EnsureWalletAsync(AppDbContext db, Guid? userId = null, Guid? merchantId = null)
    {
        var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.user_id == userId && w.merchant_id == merchantId);
        if (wallet is null)
        {
            wallet = new Wallet { wallet_id = Guid.NewGuid(), wallet_balance = 0m, user_id = userId, merchant_id = merchantId };
            Touch(wallet);
            db.Wallets.Add(wallet);
            await db.SaveChangesAsync();
        }
        return wallet;
    }

    private static async Task<BankAccount> EnsureBankAsync(AppDbContext db, BankAccount b)
    {
        var existing = await db.BankAccounts.FirstOrDefaultAsync(x => x.BankAccountNumber == b.BankAccountNumber);
        if (existing is null)
        {
            Touch(b);
            db.BankAccounts.Add(b);
            await db.SaveChangesAsync();
            return b;
        }
        existing.BankUsername = b.BankUsername;
        existing.BankUserPassword = b.BankUserPassword; // TEST ONLY
        existing.BankType = b.BankType;
        existing.BankUserBalance = b.BankUserBalance;
        existing.UserId = b.UserId;
        existing.MerchantId = b.MerchantId;
        Touch(existing);
        await db.SaveChangesAsync();
        return existing;
    }

    private static async Task UpsertMonthlyBudgetsAsync(
        AppDbContext db,
        Guid userId,
        DateTime cycleStartUtc,
        DateTime cycleEndUtc,
        Dictionary<string, decimal> caps)
    {
        foreach (var (category, limit) in caps)
        {
            var existing = await db.Budgets.FirstOrDefaultAsync(x =>
                x.UserId == userId && x.Category == category &&
                x.CycleStart == cycleStartUtc && x.CycleEnd == cycleEndUtc);

            if (existing is null)
            {
                var b = new Budget {
                    UserId = userId, Category = category, LimitAmount = limit,
                    CycleStart = cycleStartUtc, CycleEnd = cycleEndUtc
                };
                Touch(b);
                db.Budgets.Add(b);
            }
            else
            {
                existing.LimitAmount = limit;
                Touch(existing);
            }
        }
        await db.SaveChangesAsync();
    }

    // -------- categorization --------
    private static string Categorize(string? item, string? detail, string paymentMethod, string? counterparty = null)
    {
        var text = string.Join(" ", item ?? "", detail ?? "", counterparty ?? "", paymentMethod ?? "").ToLowerInvariant();

        if (paymentMethod?.ToLowerInvariant() == "bank") return "TopUp";
        if (text.Contains("topup") || text.Contains("top up")) return "TopUp";

        if (text.Contains("nasi") || text.Contains("lemak") || text.Contains("teh tarik") ||
            text.Contains("kopi") || text.Contains("kfc") || text.Contains("mcd") ||
            text.Contains("burger") || text.Contains("restaurant") || text.Contains("cafe"))
            return "Food";

        if (text.Contains("grocer") || text.Contains("tesco") || text.Contains("aeon") ||
            text.Contains("jaya") || text.Contains("mydin") || text.Contains("giant"))
            return "Groceries";

        if (text.Contains("grab") || text.Contains("tng") || text.Contains("rapid") ||
            text.Contains("lrt") || text.Contains("mrt") || text.Contains("petrol") ||
            text.Contains("shell") || text.Contains("petronas"))
            return "Transport";

        if (text.Contains("tenaga") || text.Contains("tm") || text.Contains("maxis") ||
            text.Contains("celcom") || text.Contains("digi") || text.Contains("water") || text.Contains("bill"))
            return "Bills";

        if (text.Contains("netflix") || text.Contains("spotify") || text.Contains("cinema") ||
            text.Contains("movie") || text.Contains("game"))
            return "Entertainment";

        return "General";
    }

    // -------- txns (no compile-time last_update refs) --------
    private static async Task TopUpAsync(AppDbContext db, Guid walletId, Guid fromBankId, decimal amount)
    {
        using var tx = await db.Database.BeginTransactionAsync();
        var wallet = await db.Wallets.FirstAsync(w => w.wallet_id == walletId);
        var bank   = await db.BankAccounts.FirstAsync(b => b.BankAccountId == fromBankId);
        if (bank.BankUserBalance < amount) throw new InvalidOperationException("insufficient bank balance");

        bank.BankUserBalance -= amount;
        wallet.wallet_balance += amount;
        Touch(bank); Touch(wallet);

        var cat = Categorize("TopUp", "Seeder top-up", "bank");
        var t = new Transaction {
            transaction_type    = "topup",
            transaction_from    = bank.BankAccountNumber,
            transaction_to      = wallet.wallet_id.ToString(),
            from_bank_id        = bank.BankAccountId,
            to_wallet_id        = wallet.wallet_id,
            transaction_amount  = amount,
            payment_method      = "bank",
            transaction_status  = "success",
            transaction_detail  = "Seeder top-up",
            category            = cat,
            transaction_timestamp = DateTime.UtcNow
        };
        Touch(t);
        db.Transactions.Add(t);

        await db.SaveChangesAsync();
        await tx.CommitAsync();
    }

    private static async Task PayAsync(AppDbContext db, Guid fromWalletId, Guid toWalletId, decimal amount, string? item = null, string? detail = null)
    {
        using var tx = await db.Database.BeginTransactionAsync();
        var from = await db.Wallets.FirstAsync(w => w.wallet_id == fromWalletId);
        var to   = await db.Wallets.FirstAsync(w => w.wallet_id == toWalletId);
        if (from.wallet_balance < amount) throw new InvalidOperationException("insufficient wallet balance");

        from.wallet_balance -= amount;
        to.wallet_balance   += amount;
        Touch(from); Touch(to);

        var cat = Categorize(item, detail, "wallet", "merchant");
        var t = new Transaction {
            transaction_type    = "pay",
            transaction_from    = from.wallet_id.ToString(),
            transaction_to      = to.wallet_id.ToString(),
            from_wallet_id      = from.wallet_id,
            to_wallet_id        = to.wallet_id,
            transaction_amount  = amount,
            payment_method      = "wallet",
            transaction_status  = "success",
            transaction_item    = item,
            transaction_detail  = detail,
            category            = cat,
            transaction_timestamp = DateTime.UtcNow
        };
        Touch(t);
        db.Transactions.Add(t);

        await db.SaveChangesAsync();
        await tx.CommitAsync();
    }

    private static async Task TransferAsync(AppDbContext db, Guid fromWalletId, Guid toWalletId, decimal amount, string? detail = null)
    {
        using var tx = await db.Database.BeginTransactionAsync();
        var from = await db.Wallets.FirstAsync(w => w.wallet_id == fromWalletId);
        var to   = await db.Wallets.FirstAsync(w => w.wallet_id == toWalletId);
        if (from.wallet_balance < amount) throw new InvalidOperationException("insufficient wallet balance");

        from.wallet_balance -= amount;
        to.wallet_balance   += amount;
        Touch(from); Touch(to);

        var cat = Categorize(null, detail, "wallet", "user");
        var t = new Transaction {
            transaction_type    = "transfer",
            transaction_from    = from.wallet_id.ToString(),
            transaction_to      = to.wallet_id.ToString(),
            from_wallet_id      = from.wallet_id,
            to_wallet_id        = toWalletId,
            transaction_amount  = amount,
            payment_method      = "wallet",
            transaction_status  = "success",
            transaction_detail  = detail,
            category            = cat,
            transaction_timestamp = DateTime.UtcNow
        };
        Touch(t);
        db.Transactions.Add(t);

        await db.SaveChangesAsync();
        await tx.CommitAsync();
    }

    private static async Task PrintSummaryAsync(AppDbContext db, User admin, IEnumerable<User> users, Merchant merchant, User merchantOwner)
    {
        Console.WriteLine("\n=== SEED SUMMARY ===");
        Console.WriteLine("Admin (no wallet): " + admin.UserName + " | " + (admin.Email ?? admin.PhoneNumber));

        Console.WriteLine("\nUsers:");
        foreach (var u in users)
        {
            var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.user_id == u.UserId);
            var banks = await db.BankAccounts.Where(b => b.UserId == u.UserId).ToListAsync();
            Console.WriteLine($"- {u.UserName} | Wallet: {wallet?.wallet_id} Bal: {wallet?.wallet_balance:0.00}");
            foreach (var b in banks)
                Console.WriteLine($"    • {b.BankType} #{b.BankAccountNumber} | Bal: {b.BankUserBalance:0.00}");
        }

        Console.WriteLine("\nMerchant:");
        var mWallet = await db.Wallets.FirstOrDefaultAsync(w => w.merchant_id == merchant.MerchantId);
        var mBanks = await db.BankAccounts.Where(b => b.MerchantId == merchant.MerchantId).ToListAsync();
        Console.WriteLine($"- {merchant.MerchantName} (owner {merchantOwner.UserName}) | Wallet: {mWallet?.wallet_id} Bal: {mWallet?.wallet_balance:0.00}");
        foreach (var b in mBanks)
            Console.WriteLine($"    • {b.BankType} #{b.BankAccountNumber} | Bal: {b.BankUserBalance:0.00}");
        Console.WriteLine("====================\n");
    }
}
