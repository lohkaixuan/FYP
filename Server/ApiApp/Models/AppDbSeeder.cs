using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models;

public static class AppDbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync();

        // ===== monthly windows (UTC) =====
        var nowUtc = DateTime.UtcNow;
        var startThisUtc = new DateTime(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var endThisUtc = startThisUtc.AddMonths(1).AddTicks(-1);

        var startPrev1Utc = startThisUtc.AddMonths(-1);
        var endPrev1Utc = startPrev1Utc.AddMonths(1).AddTicks(-1);

        var startPrev2Utc = startThisUtc.AddMonths(-2);
        var endPrev2Utc = startPrev2Utc.AddMonths(1).AddTicks(-1);

        // ===== roles =====
        var roleUserId = Guid.Parse("11111111-1111-1111-1111-111111111001");
        var roleMerchantId = Guid.Parse("11111111-1111-1111-1111-111111111002");
        var roleAdminId = Guid.Parse("11111111-1111-1111-1111-111111111003");
        var roleProviderId = Guid.Parse("11111111-1111-1111-1111-111111111004");

        await EnsureRoleAsync(db, roleUserId, "user");
        await EnsureRoleAsync(db, roleMerchantId, "merchant");
        await EnsureRoleAsync(db, roleAdminId, "admin");
        await EnsureRoleAsync(db, roleProviderId, "bank provider");

        // ===== users =====
        var admin = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000001"),
            UserName = "Admin",
            Email = "admin@example.com",
            PhoneNumber = "0388880000",
            ICNumber = "900101-14-0001",
            UserPassword = "Admin@123",
            RoleId = roleAdminId
        });

        var providerUser = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000002"),
            UserName = "Provider Operator",
            Email = "provider@example.com",
            PhoneNumber = "0399990000",
            ICNumber = "900202-10-0002",
            UserPassword = "Provider@123",
            RoleId = roleProviderId
        });

        // normal users
        var user1 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000003"),
            UserName = "Mei User",
            Email = "mei.user@gmail.com",
            PhoneNumber = "01122334455",
            ICNumber = "000505-14-3333",
            UserPassword = "User1@123",
            RoleId = roleUserId
        });
        var user2 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000004"),
            UserName = "John User",
            Email = "john.user@gmail.com",
            PhoneNumber = "0191112222",
            ICNumber = "010606-10-4444",
            UserPassword = "User2@123",
            RoleId = roleUserId
        });

        var user3 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000005"),
            UserName = "Sarah User",
            Email = "sarah.user@gmail.com",
            PhoneNumber = "0175556666",
            ICNumber = "990707-08-5555",
            UserPassword = "User3@123",
            RoleId = roleUserId
        });

        var user4 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000006"),
            UserName = "Ken User",
            Email = "ken.user@gmail.com",
            PhoneNumber = "0167778888",
            ICNumber = "980808-10-6666",
            UserPassword = "User4@123",
            RoleId = roleUserId
        });

        var user5 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000007"),
            UserName = "Zoe User",
            Email = "zoe.user@gmail.com",
            PhoneNumber = "0189990000",
            ICNumber = "970909-12-7777",
            UserPassword = "User5@123",
            RoleId = roleUserId
        });

        // merchant owners
        var merchantOwner1 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000008"),
            UserName = "Ali Merchant",
            Email = "ali@shop.com",
            PhoneNumber = "0123456789",
            ICNumber = "970404-10-2222",
            UserPassword = "Merchant1@123",
            RoleId = roleMerchantId
        });

        var merchantOwner2 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000009"),
            UserName = "Brenda Merchant",
            Email = "brenda@frogcafe.com",
            PhoneNumber = "0133337777",
            ICNumber = "960505-08-3333",
            UserPassword = "Merchant2@123",
            RoleId = roleMerchantId
        });

        var merchantOwner3 = await EnsureUserAsync(db, new User
        {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000010"),
            UserName = "Chen Merchant",
            Email = "chen@meimart.com",
            PhoneNumber = "0144448888",
            ICNumber = "950606-12-4444",
            UserPassword = "Merchant3@123",
            RoleId = roleMerchantId
        });

        // ===== wallets =====
        async Task<Wallet> ensureUserWallet(User u)
        {
            var w = await EnsureWalletAsync(db, userId: u.UserId);
            return w;
        }

        var providerWallet = await ensureUserWallet(providerUser);

        var u1Wallet = await ensureUserWallet(user1);
        var u2Wallet = await ensureUserWallet(user2);
        var u3Wallet = await ensureUserWallet(user3);
        var u4Wallet = await ensureUserWallet(user4);
        var u5Wallet = await ensureUserWallet(user5);

        var owner1Wallet = await ensureUserWallet(merchantOwner1);
        var owner2Wallet = await ensureUserWallet(merchantOwner2);
        var owner3Wallet = await ensureUserWallet(merchantOwner3);
        // merchants
        var merchant1 = await EnsureMerchantAsync(db, new Merchant
        {
            MerchantId = Guid.Parse("22222222-2222-2222-2222-000000000001"),
            MerchantName = "Nasi Lemak House",
            MerchantPhoneNumber = "0128887777",
            MerchantDocUrl = "https://example.com/docs/nasilemak.pdf",
            OwnerUserId = merchantOwner1.UserId
        });

        var merchant2 = await EnsureMerchantAsync(db, new Merchant
        {
            MerchantId = Guid.Parse("22222222-2222-2222-2222-000000000002"),
            MerchantName = "Frog Café",
            MerchantPhoneNumber = "0139996666",
            MerchantDocUrl = "https://example.com/docs/frogcafe.pdf",
            OwnerUserId = merchantOwner2.UserId
        });

        var merchant3 = await EnsureMerchantAsync(db, new Merchant
        {
            MerchantId = Guid.Parse("22222222-2222-2222-2222-000000000003"),
            MerchantName = "MeiMart Groceries",
            MerchantPhoneNumber = "0142223333",
            MerchantDocUrl = "https://example.com/docs/meimart.pdf",
            OwnerUserId = merchantOwner3.UserId
        });

        await db.SaveChangesAsync();

        var m1Wallet = await EnsureWalletAsync(db, merchantId: merchant1.MerchantId);
        var m2Wallet = await EnsureWalletAsync(db, merchantId: merchant2.MerchantId);
        var m3Wallet = await EnsureWalletAsync(db, merchantId: merchant3.MerchantId);

        // bank accounts
        async Task<BankAccount> ensureUserBank(User u, string acc, string bankType, decimal bal)
        {
            var b = await EnsureBankAsync(db, new BankAccount
            {
                BankAccountNumber = acc,
                BankUsername = u.UserName.ToLower().Replace(" ", "_"),
                BankUserPassword = "bankPass",
                BankUserBalance = bal,
                BankType = bankType,
                BankAccountCategory = "personal",
                UserId = u.UserId
            });
            return b;
        }

        var u1Bank = await ensureUserBank(user1, "9001 00 000111", "RHB", 1500m);
        var u2Bank = await ensureUserBank(user2, "9001 00 000112", "CIMB", 900m);
        var u3Bank = await ensureUserBank(user3, "9001 00 000113", "Maybank", 800m);
        var u4Bank = await ensureUserBank(user4, "9001 00 000114", "Public", 700m);
        var u5Bank = await ensureUserBank(user5, "9001 00 000115", "HongLeong", 600m);

        var owner1Bank = await ensureUserBank(merchantOwner1, "9001 00 000116", "CIMB", 2000m);
        var owner2Bank = await ensureUserBank(merchantOwner2, "9001 00 000117", "Maybank", 1800m);
        var owner3Bank = await ensureUserBank(merchantOwner3, "9001 00 000118", "RHB", 1600m);
        // ===== budgets for 3 months =====
        async Task SeedBudgetsForUser(User u, decimal food, decimal groceries)
        {
            foreach (var (s, e) in new[] {
                (startPrev2Utc, endPrev2Utc),   // 2 months ago
                (startPrev1Utc, endPrev1Utc),   // last month
                (startThisUtc,   endThisUtc)    // this month
            })
            {
                await UpsertMonthlyBudgetsAsync(db, u.UserId, s, e, new(){
                    { "TopUp", 0m },
                    { "Food", food },
                    { "Groceries", groceries },
                    { "Transport", 200m },
                    { "Bills", 250m },
                    { "Entertainment", 150m }
                });
            }
        }

        var budgetUsers = new[]{
            user1, user2, user3, user4, user5,
            merchantOwner1, merchantOwner2, merchantOwner3
        };

        foreach (var u in budgetUsers)
            await SeedBudgetsForUser(u, 300m, 400m);

        // ========== Txn helpers with timestamp ==========

        async Task TopUpWithTs(
            AppDbContext db, Guid walletId, Guid fromBankId, decimal amount, DateTime ts)
        {
            using var tx = await db.Database.BeginTransactionAsync();
            var wallet = await db.Wallets.FirstAsync(w => w.wallet_id == walletId);
            var bank = await db.BankAccounts.FirstAsync(b => b.BankAccountId == fromBankId);

            bank.BankUserBalance -= amount;
            wallet.wallet_balance += amount;
            Touch(bank); Touch(wallet);

            var t = new Transaction
            {
                transaction_type = "topup",
                transaction_from = bank.BankAccountNumber,
                transaction_to = wallet.wallet_id.ToString(),
                from_bank_id = bank.BankAccountId,
                to_wallet_id = wallet.wallet_id,
                from_user_id = bank.UserId,
                to_user_id = wallet.user_id,
                to_merchant_id = wallet.merchant_id,
                transaction_amount = amount,
                payment_method = "bank",
                transaction_status = "success",
                transaction_detail = "Seeder top-up",
                category = "TopUp",
                transaction_timestamp = ts
            };
            Touch(t);
            db.Transactions.Add(t);

            await db.SaveChangesAsync();
            await tx.CommitAsync();
        }

        async Task PayWithTs(
            AppDbContext db, Guid fromWalletId, Guid toWalletId,
            decimal amount, string item, string detail, DateTime ts)
        {
            using var tx = await db.Database.BeginTransactionAsync();
            var from = await db.Wallets.FirstAsync(w => w.wallet_id == fromWalletId);
            var to = await db.Wallets.FirstAsync(w => w.wallet_id == toWalletId);

            from.wallet_balance -= amount;
            to.wallet_balance += amount;
            Touch(from); Touch(to);

            var t = new Transaction
            {
                transaction_type = "pay",
                transaction_from = from.wallet_id.ToString(),
                transaction_to = to.wallet_id.ToString(),
                from_user_id = from.user_id,
                to_user_id = to.user_id,
                to_merchant_id = to.merchant_id,
                from_wallet_id = from.wallet_id,
                to_wallet_id = to.wallet_id,
                transaction_amount = amount,
                payment_method = "wallet",
                transaction_status = "success",
                transaction_item = item,
                transaction_detail = detail,
                category = "Food",
                transaction_timestamp = ts
            };
            Touch(t);
            db.Transactions.Add(t);

            await db.SaveChangesAsync();
            await tx.CommitAsync();
        }

        async Task TransferWithTs(
            AppDbContext db, Guid fromWalletId, Guid toWalletId,
            decimal amount, string detail, DateTime ts)
        {
            using var tx = await db.Database.BeginTransactionAsync();
            var from = await db.Wallets.FirstAsync(w => w.wallet_id == fromWalletId);
            var to = await db.Wallets.FirstAsync(w => w.wallet_id == toWalletId);

            from.wallet_balance -= amount;
            to.wallet_balance += amount;
            Touch(from); Touch(to);

            var t = new Transaction
            {
                transaction_type = "transfer",
                transaction_from = from.wallet_id.ToString(),
                transaction_to = to.wallet_id.ToString(),
                from_user_id = from.user_id,
                to_user_id = to.user_id,
                from_wallet_id = from.wallet_id,
                to_wallet_id = to.wallet_id,
                transaction_amount = amount,
                payment_method = "wallet",
                transaction_status = "success",
                transaction_detail = detail,
                category = "General",
                transaction_timestamp = ts
            };

            Touch(t);
            db.Transactions.Add(t);

            await db.SaveChangesAsync();
            await tx.CommitAsync();
        }

        async Task SeedUserTx3Months(User u, Wallet w, BankAccount bank)
        {
            // target for transfers
            Wallet? target = u.UserId switch
            {
                var id when id == user1.UserId => u2Wallet,
                var id when id == user2.UserId => u3Wallet,
                var id when id == user3.UserId => u4Wallet,
                var id when id == user4.UserId => u5Wallet,
                var id when id == user5.UserId => owner1Wallet,
                var id when id == merchantOwner1.UserId => owner2Wallet,
                var id when id == merchantOwner2.UserId => owner3Wallet,
                _ => u1Wallet
            };

            // September
            await TopUpWithTs(db, w.wallet_id, bank.BankAccountId, 200m, startPrev2Utc.AddDays(3).AddHours(10));
            await PayWithTs(db, w.wallet_id, m1Wallet.wallet_id, 18.60m, "Lunch", $"Lunch by {u.UserName}", startPrev2Utc.AddDays(3).AddHours(12));
            await TransferWithTs(db, w.wallet_id, target.wallet_id, 8m, $"Transfer ({u.UserName}) prev2", startPrev2Utc.AddDays(3).AddHours(15));

            // October
            await TopUpWithTs(db, w.wallet_id, bank.BankAccountId, 180m, startPrev1Utc.AddDays(5).AddHours(10));
            await PayWithTs(db, w.wallet_id, m2Wallet.wallet_id, 22.30m, "Cafe", $"Cafe {u.UserName}", startPrev1Utc.AddDays(5).AddHours(13));
            await TransferWithTs(db, w.wallet_id, target.wallet_id, 6m, $"Transfer {u.UserName} prev1", startPrev1Utc.AddDays(5).AddHours(16));

            // November
            await TopUpWithTs(db, w.wallet_id, bank.BankAccountId, 150m, startThisUtc.AddDays(1).AddHours(9));
            await PayWithTs(db, w.wallet_id, m3Wallet.wallet_id, 19.99m, "Groceries", $"MeiMart by {u.UserName}", startThisUtc.AddDays(1).AddHours(11));
            await TransferWithTs(db, w.wallet_id, target.wallet_id, 5m, $"Transfer {u.UserName} thisMonth", startThisUtc.AddDays(1).AddHours(14));
        }

        await SeedUserTx3Months(user1, u1Wallet, u1Bank);
        await SeedUserTx3Months(user2, u2Wallet, u2Bank);
        await SeedUserTx3Months(user3, u3Wallet, u3Bank);
        await SeedUserTx3Months(user4, u4Wallet, u4Bank);
        await SeedUserTx3Months(user5, u5Wallet, u5Bank);
        await SeedUserTx3Months(merchantOwner1, owner1Wallet, owner1Bank);
        await SeedUserTx3Months(merchantOwner2, owner2Wallet, owner2Bank);
        await SeedUserTx3Months(merchantOwner3, owner3Wallet, owner3Bank);

        Console.WriteLine("Seeder for 3-month transactions completed.");
    }


    // ============================================
    // helpers: Touch, EnsureRole, EnsureUser, etc.
    // ============================================

    private static void Touch(object entity)
    {
        var t = entity.GetType();
        foreach (var name in new[] { "LastUpdate", "last_update" })
        {
            var p = t.GetProperty(name);
            if (p != null && p.PropertyType == typeof(DateTime))
                p.SetValue(entity, DateTime.UtcNow);
        }
    }

    private static async Task<Role> EnsureRoleAsync(AppDbContext db, Guid id, string name)
    {
        var e = await db.Roles.FirstOrDefaultAsync(x => x.RoleId == id);
        if (e == null)
        {
            e = new Role { RoleId = id, RoleName = name };
            db.Roles.Add(e);
            await db.SaveChangesAsync();
        }
        return e;
    }

    private static async Task<User> EnsureUserAsync(AppDbContext db, User u)
    {
        // Avoid duplicate email constraint hits by matching on either id or email
        var e = await db.Users.FirstOrDefaultAsync(x => x.UserId == u.UserId || x.Email == u.Email);
        if (e == null)
        {
            Touch(u);
            db.Users.Add(u);
            await db.SaveChangesAsync();
            return u;
        }

        // Keep existing user aligned with seed data
        e.UserName = u.UserName;
        e.Email = u.Email;
        e.PhoneNumber = u.PhoneNumber;
        e.ICNumber = u.ICNumber;
        e.UserPassword = u.UserPassword;
        e.RoleId = u.RoleId;
        Touch(e);
        await db.SaveChangesAsync();
        return e;
    }

    private static async Task<Merchant> EnsureMerchantAsync(AppDbContext db, Merchant m)
    {
        // Ignore global query filters (like IsDeleted) so we don't accidentally
        // re-insert a soft-deleted merchant with the same primary key.
        var e = await db.Merchants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(x => x.MerchantId == m.MerchantId);

        if (e == null)
        {
            // Brand new merchant, safe to insert
            Touch(m);
            db.Merchants.Add(m);
            await db.SaveChangesAsync();
            return m;
        }

        // Keep existing row in sync with seed data & "un-delete" if needed
        e.MerchantName = m.MerchantName;
        e.MerchantPhoneNumber = m.MerchantPhoneNumber;
        e.MerchantDocUrl = m.MerchantDocUrl;
        e.OwnerUserId = m.OwnerUserId;

        // If Merchant inherits BaseTracked with IsDeleted, clear the delete flag
        var isDeletedProp = e.GetType().GetProperty("IsDeleted");
        if (isDeletedProp != null && isDeletedProp.PropertyType == typeof(bool))
        {
            isDeletedProp.SetValue(e, false);
        }

        Touch(e);
        await db.SaveChangesAsync();
        return e;
    }


    private static async Task<Wallet> EnsureWalletAsync(AppDbContext db, Guid? userId = null, Guid? merchantId = null)
    {
        var w = await db.Wallets.FirstOrDefaultAsync(x => x.user_id == userId && x.merchant_id == merchantId);
        if (w == null)
        {
            w = new Wallet
            {
                wallet_id = Guid.NewGuid(),
                wallet_balance = 0,
                user_id = userId,
                merchant_id = merchantId
            };
            Touch(w);
            db.Wallets.Add(w);
            await db.SaveChangesAsync();
        }
        return w;
    }

    private static async Task<BankAccount> EnsureBankAsync(AppDbContext db, BankAccount b)
    {
        var e = await db.BankAccounts.FirstOrDefaultAsync(x => x.BankAccountNumber == b.BankAccountNumber);
        if (e == null)
        {
            Touch(b);
            db.BankAccounts.Add(b);
            await db.SaveChangesAsync();
            return b;
        }
        Touch(e);
        return e;
    }

    private static async Task UpsertMonthlyBudgetsAsync(
        AppDbContext db, Guid userId,
        DateTime startUtc, DateTime endUtc,
        Dictionary<string, decimal> caps)
    {
        foreach (var (cat, limit) in caps)
        {
            var b = await db.Budgets.FirstOrDefaultAsync(x =>
                x.UserId == userId &&
                x.Category == cat &&
                x.CycleStart == startUtc &&
                x.CycleEnd == endUtc
            );
            if (b == null)
            {
                b = new Budget
                {
                    UserId = userId,
                    Category = cat,
                    LimitAmount = limit,
                    CycleStart = startUtc,
                    CycleEnd = endUtc
                };
                Touch(b);
                db.Budgets.Add(b);
            }
            else
            {
                b.LimitAmount = limit;
                Touch(b);
            }
        }
        await db.SaveChangesAsync();
    }
}
