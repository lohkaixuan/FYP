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

        // ===== users =====
        var admin = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000001"),
            UserName     = "Admin",
            Email        = "admin@example.com",
            PhoneNumber  = "0388880000",
            ICNumber     = "900101-14-0001",
            UserPassword = "Admin@123", // TEST ONLY
            RoleId       = roleAdminId
        });

        var providerUser = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000002"),
            UserName     = "Provider Operator",
            Email        = "provider@example.com",
            PhoneNumber  = "0399990000",
            ICNumber     = "900202-10-0002",
            UserPassword = "Provider@123", // TEST ONLY
            RoleId       = roleProviderId
        });

        // normal users
        var user1 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000003"),
            UserName     = "Mei User",
            Email        = "mei.user@gmail.com",
            PhoneNumber  = "01122334455",
            ICNumber     = "000505-14-3333",
            UserPassword = "User1@123", // TEST ONLY
            RoleId       = roleUserId
        });

        var user2 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000004"),
            UserName     = "John User",
            Email        = "john.user@gmail.com",
            PhoneNumber  = "0191112222",
            ICNumber     = "010606-10-4444",
            UserPassword = "User2@123", // TEST ONLY
            RoleId       = roleUserId
        });

        var user3 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000005"),
            UserName     = "Sarah User",
            Email        = "sarah.user@gmail.com",
            PhoneNumber  = "0175556666",
            ICNumber     = "990707-08-5555",
            UserPassword = "User3@123", // TEST ONLY
            RoleId       = roleUserId
        });

        var user4 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000006"),
            UserName     = "Ken User",
            Email        = "ken.user@gmail.com",
            PhoneNumber  = "0167778888",
            ICNumber     = "980808-10-6666",
            UserPassword = "User4@123", // TEST ONLY
            RoleId       = roleUserId
        });

        var user5 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000007"),
            UserName     = "Zoe User",
            Email        = "zoe.user@gmail.com",
            PhoneNumber  = "0189990000",
            ICNumber     = "970909-12-7777",
            UserPassword = "User5@123", // TEST ONLY
            RoleId       = roleUserId
        });

        // merchant owners (also users, role = merchant)
        var merchantOwner1 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000008"),
            UserName     = "Ali Merchant",
            Email        = "ali@shop.com",
            PhoneNumber  = "0123456789",
            ICNumber     = "970404-10-2222",
            UserPassword = "Merchant1@123", // TEST ONLY
            RoleId       = roleMerchantId
        });

        var merchantOwner2 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000009"),
            UserName     = "Brenda Merchant",
            Email        = "brenda@frogcafe.com",
            PhoneNumber  = "0133337777",
            ICNumber     = "960505-08-3333",
            UserPassword = "Merchant2@123", // TEST ONLY
            RoleId       = roleMerchantId
        });

        var merchantOwner3 = await EnsureUserAsync(db, new User{
            UserId       = Guid.Parse("11111111-1111-1111-1111-000000000010"),
            UserName     = "Chen Merchant",
            Email        = "chen@meimart.com",
            PhoneNumber  = "0144448888",
            ICNumber     = "950606-12-4444",
            UserPassword = "Merchant3@123", // TEST ONLY
            RoleId       = roleMerchantId
        });

        // ===== wallets for all non-admin users (user + merchant roles + provider if you want) =====
        var userWallets = new Dictionary<Guid, Wallet>();

        async Task<Wallet> ensureUserWallet(User u)
        {
            var w = await EnsureWalletAsync(db, userId: u.UserId);
            userWallets[u.UserId] = w;
            return w;
        }

        // admin: no wallet (后台管理)
        var providerWallet = await ensureUserWallet(providerUser);

        var u1Wallet = await ensureUserWallet(user1);
        var u2Wallet = await ensureUserWallet(user2);
        var u3Wallet = await ensureUserWallet(user3);
        var u4Wallet = await ensureUserWallet(user4);
        var u5Wallet = await ensureUserWallet(user5);

        var owner1UserWallet = await ensureUserWallet(merchantOwner1);
        var owner2UserWallet = await ensureUserWallet(merchantOwner2);
        var owner3UserWallet = await ensureUserWallet(merchantOwner3);

        // ===== merchants =====
        var merchant1 = await EnsureMerchantAsync(db, new Merchant{
            MerchantId           = Guid.Parse("22222222-2222-2222-2222-000000000001"),
            MerchantName         = "Nasi Lemak House",
            MerchantPhoneNumber  = "0128887777",
            MerchantDocUrl       = "https://example.com/docs/nasilemak.pdf",
            OwnerUserId          = merchantOwner1.UserId
        });
        Touch(merchant1);

        var merchant2 = await EnsureMerchantAsync(db, new Merchant{
            MerchantId           = Guid.Parse("22222222-2222-2222-2222-000000000002"),
            MerchantName         = "Frog Café",
            MerchantPhoneNumber  = "0139996666",
            MerchantDocUrl       = "https://example.com/docs/frogcafe.pdf",
            OwnerUserId          = merchantOwner2.UserId
        });
        Touch(merchant2);

        var merchant3 = await EnsureMerchantAsync(db, new Merchant{
            MerchantId           = Guid.Parse("22222222-2222-2222-2222-000000000003"),
            MerchantName         = "MeiMart Groceries",
            MerchantPhoneNumber  = "0142223333",
            MerchantDocUrl       = "https://example.com/docs/meimart.pdf",
            OwnerUserId          = merchantOwner3.UserId
        });
        Touch(merchant3);

        await db.SaveChangesAsync();

        // merchant wallets
        var m1Wallet = await EnsureWalletAsync(db, merchantId: merchant1.MerchantId);
        var m2Wallet = await EnsureWalletAsync(db, merchantId: merchant2.MerchantId);
        var m3Wallet = await EnsureWalletAsync(db, merchantId: merchant3.MerchantId);

        // ===== bank accounts for users (except admin) =====
        var userBanks = new Dictionary<Guid, BankAccount>();

        async Task<BankAccount> ensureUserBank(User u, string accNo, string bankType, decimal balance)
        {
            var bank = await EnsureBankAsync(db, new BankAccount{
                BankAccountNumber   = accNo,
                BankUsername        = u.UserName.ToLower().Replace(" ", "_"),
                BankUserPassword    = "bankPass_" + u.UserName.Split(' ')[0].ToLower(), // TEST ONLY
                BankUserBalance     = balance,
                BankType            = bankType,
                BankAccountCategory = "personal",
                UserId              = u.UserId
            });
            userBanks[u.UserId] = bank;
            return bank;
        }

        var u1Bank = await ensureUserBank(user1, "9001 00 000111", "RHB",    1500m);
        var u2Bank = await ensureUserBank(user2, "9001 00 000112", "CIMB",    900m);
        var u3Bank = await ensureUserBank(user3, "9001 00 000113", "Maybank", 800m);
        var u4Bank = await ensureUserBank(user4, "9001 00 000114", "Public",  700m);
        var u5Bank = await ensureUserBank(user5, "9001 00 000115", "HongLeong",600m);

        var owner1Bank = await ensureUserBank(merchantOwner1, "9001 00 000116", "CIMB", 2000m);
        var owner2Bank = await ensureUserBank(merchantOwner2, "9001 00 000117", "Maybank", 1800m);
        var owner3Bank = await ensureUserBank(merchantOwner3, "9001 00 000118", "RHB", 1600m);

        // merchant bank accounts
        var merchant1Bank = await EnsureBankAsync(db, new BankAccount{
            BankAccountNumber   = "7800 22 000201",
            BankUsername        = "merchant_ali",
            BankUserPassword    = "bankPassM1",
            BankUserBalance     = 5000m,
            BankType            = "CIMB",
            BankAccountCategory = "merchant",
            MerchantId          = merchant1.MerchantId
        });

        var merchant2Bank = await EnsureBankAsync(db, new BankAccount{
            BankAccountNumber   = "7800 22 000202",
            BankUsername        = "merchant_brenda",
            BankUserPassword    = "bankPassM2",
            BankUserBalance     = 4500m,
            BankType            = "Maybank",
            BankAccountCategory = "merchant",
            MerchantId          = merchant2.MerchantId
        });

        var merchant3Bank = await EnsureBankAsync(db, new BankAccount{
            BankAccountNumber   = "7800 22 000203",
            BankUsername        = "merchant_chen",
            BankUserPassword    = "bankPassM3",
            BankUserBalance     = 4200m,
            BankType            = "RHB",
            BankAccountCategory = "merchant",
            MerchantId          = merchant3.MerchantId
        });

        // ===== budgets for all non-admin/non-provider users =====
        async Task SeedBudgetsForUser(User u, decimal food, decimal groceries)
        {
            await UpsertMonthlyBudgetsAsync(db, u.UserId, startOfMonthUtc, endOfMonthUtc, new()
            {
                { "TopUp", 0m }, { "Food", food }, { "Groceries", groceries },
                { "Transport", 200m }, { "Bills", 250m }, { "Entertainment", 150m },
            });
        }

        var allBudgetUsers = new [] {
            user1, user2, user3, user4, user5,
            merchantOwner1, merchantOwner2, merchantOwner3
        };

        foreach (var u in allBudgetUsers)
        {
            await SeedBudgetsForUser(u, food: 300m, groceries: 400m);
        }

        // ===== demo transactions =====
        // 为了避免重复爆炸，只在该用户钱包目前没有交易时才插入 demo 数据
        async Task SeedUserTransactionsAsync(User u, Wallet w, BankAccount bank)
        {
            var hasTxn = await db.Transactions.AnyAsync(t =>
                t.from_wallet_id == w.wallet_id || t.to_wallet_id == w.wallet_id);
            if (hasTxn) return;

            // 1) TopUp
            await TopUpAsync(db, w.wallet_id, bank.BankAccountId, 200m);

            // 2) Pay to merchant1
            await PayAsync(db, w.wallet_id, m1Wallet.wallet_id, 25.50m,
                item: "Nasi Lemak + Teh Tarik", detail: $"Lunch by {u.UserName}");

            // 3) Transfer to another user (round-robin)
            Wallet? targetWallet = null;
            if (u.UserId == user1.UserId) targetWallet = u2Wallet;
            else if (u.UserId == user2.UserId) targetWallet = u3Wallet;
            else if (u.UserId == user3.UserId) targetWallet = u4Wallet;
            else if (u.UserId == user4.UserId) targetWallet = u5Wallet;
            else if (u.UserId == user5.UserId) targetWallet = owner1UserWallet;
            else if (u.UserId == merchantOwner1.UserId) targetWallet = owner2UserWallet;
            else if (u.UserId == merchantOwner2.UserId) targetWallet = owner3UserWallet;
            else if (u.UserId == merchantOwner3.UserId) targetWallet = u1Wallet;

            if (targetWallet != null && targetWallet.wallet_id != w.wallet_id)
            {
                await TransferAsync(db, w.wallet_id, targetWallet.wallet_id, 10m,
                    detail: $"Seeder transfer from {u.UserName}");
            }
        }

        await SeedUserTransactionsAsync(user1, u1Wallet, u1Bank);
        await SeedUserTransactionsAsync(user2, u2Wallet, u2Bank);
        await SeedUserTransactionsAsync(user3, u3Wallet, u3Bank);
        await SeedUserTransactionsAsync(user4, u4Wallet, u4Bank);
        await SeedUserTransactionsAsync(user5, u5Wallet, u5Bank);
        await SeedUserTransactionsAsync(merchantOwner1, owner1UserWallet, owner1Bank);
        await SeedUserTransactionsAsync(merchantOwner2, owner2UserWallet, owner2Bank);
        await SeedUserTransactionsAsync(merchantOwner3, owner3UserWallet, owner3Bank);

        // ===== report =====
        var allUsers = new [] {
            admin, providerUser,
            user1, user2, user3, user4, user5,
            merchantOwner1, merchantOwner2, merchantOwner3
        };
        var allMerchants = new [] { merchant1, merchant2, merchant3 };

        await PrintSummaryAsync(db, allUsers, allMerchants);
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
        existing.UserName     = u.UserName;
        existing.PhoneNumber  = u.PhoneNumber;
        existing.UserPassword = u.UserPassword; // TEST ONLY
        existing.RoleId       = u.RoleId;
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
        existing.MerchantDocUrl      = m.MerchantDocUrl;
        existing.OwnerUserId         = m.OwnerUserId;
        Touch(existing);
        await db.SaveChangesAsync();
        return existing;
    }

    private static async Task<Wallet> EnsureWalletAsync(AppDbContext db, Guid? userId = null, Guid? merchantId = null)
    {
        var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.user_id == userId && w.merchant_id == merchantId);
        if (wallet is null)
        {
            wallet = new Wallet {
                wallet_id      = Guid.NewGuid(),
                wallet_balance = 0m,
                user_id        = userId,
                merchant_id    = merchantId
            };
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
        existing.BankUsername     = b.BankUsername;
        existing.BankUserPassword = b.BankUserPassword; // TEST ONLY
        existing.BankType         = b.BankType;
        existing.BankUserBalance  = b.BankUserBalance;
        existing.UserId           = b.UserId;
        existing.MerchantId       = b.MerchantId;
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
                    UserId     = userId,
                    Category   = category,
                    LimitAmount= limit,
                    CycleStart = cycleStartUtc,
                    CycleEnd   = cycleEndUtc
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

        bank.BankUserBalance  -= amount;
        wallet.wallet_balance += amount;
        Touch(bank); Touch(wallet);

        var cat = Categorize("TopUp", "Seeder top-up", "bank");
        var t = new Transaction {
            transaction_type      = "topup",
            transaction_from      = bank.BankAccountNumber,
            transaction_to        = wallet.wallet_id.ToString(),
            from_bank_id          = bank.BankAccountId,
            to_wallet_id          = wallet.wallet_id,
            transaction_amount    = amount,
            payment_method        = "bank",
            transaction_status    = "success",
            transaction_detail    = "Seeder top-up",
            category              = cat,
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
            transaction_type      = "pay",
            transaction_from      = from.wallet_id.ToString(),
            transaction_to        = to.wallet_id.ToString(),
            from_wallet_id        = from.wallet_id,
            to_wallet_id          = to.wallet_id,
            transaction_amount    = amount,
            payment_method        = "wallet",
            transaction_status    = "success",
            transaction_item      = item,
            transaction_detail    = detail,
            category              = cat,
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
            transaction_type      = "transfer",
            transaction_from      = from.wallet_id.ToString(),
            transaction_to        = to.wallet_id.ToString(),
            from_wallet_id        = from.wallet_id,
            to_wallet_id          = toWalletId,
            transaction_amount    = amount,
            payment_method        = "wallet",
            transaction_status    = "success",
            transaction_detail    = detail,
            category              = cat,
            transaction_timestamp = DateTime.UtcNow
        };
        Touch(t);
        db.Transactions.Add(t);

        await db.SaveChangesAsync();
        await tx.CommitAsync();
    }

    private static async Task PrintSummaryAsync(AppDbContext db, IEnumerable<User> users, IEnumerable<Merchant> merchants)
    {
        Console.WriteLine("\n=== SEED SUMMARY ===");

        Console.WriteLine("\nUsers:");
        foreach (var u in users)
        {
            var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.user_id == u.UserId);
            var banks  = await db.BankAccounts.Where(b => b.UserId == u.UserId).ToListAsync();
            Console.WriteLine($"- {u.UserName} (RoleId={u.RoleId}) | Wallet: {wallet?.wallet_id} Bal: {wallet?.wallet_balance:0.00}");
            foreach (var b in banks)
                Console.WriteLine($"    • {b.BankType} #{b.BankAccountNumber} | Bal: {b.BankUserBalance:0.00}");
        }

        Console.WriteLine("\nMerchants:");
        foreach (var m in merchants)
        {
            var mWallet = await db.Wallets.FirstOrDefaultAsync(w => w.merchant_id == m.MerchantId);
            var mBanks  = await db.BankAccounts.Where(b => b.MerchantId == m.MerchantId).ToListAsync();
            Console.WriteLine($"- {m.MerchantName} (owner {m.OwnerUserId}) | Wallet: {mWallet?.wallet_id} Bal: {mWallet?.wallet_balance:0.00}");
            foreach (var b in mBanks)
                Console.WriteLine($"    • {b.BankType} #{b.BankAccountNumber} | Bal: {b.BankUserBalance:0.00}");
        }

        Console.WriteLine("====================\n");
    }
}
