using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
namespace ApiApp.Models;

public static class AppDbSeeder{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await db.Database.MigrateAsync();

        // ---- Roles (you already had these) ----
        await EnsureRoleAsync(db, SystemRoles.Admin,        "admin");
        await EnsureRoleAsync(db, SystemRoles.BankProvider, "bank_provider");
        await EnsureRoleAsync(db, SystemRoles.Merchant,     "merchant");
        await EnsureRoleAsync(db, SystemRoles.User,         "user");

        // ---- Users (you already had these) ----
        var admin    = await EnsureUserAsync(db, new User {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000001"),
            UserCode = "admin001", UserName = "admin", Email = "admin@example.com",
            PhoneNumber = "+60 3-8888 0000", ICNumber = "900101-14-0001",
            RoleId = SystemRoles.Admin, IsMerchant = false, PasswordHash = "Admin@123"
        });

        var provider = await EnsureUserAsync(db, new User {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000002"),
            UserCode = "provider001", UserName = "bank_provider_my", Email = "provider@bank.com",
            PhoneNumber = "+60 3-7654 3210", ICNumber = "880202-10-2345",
            RoleId = SystemRoles.BankProvider, IsMerchant = false, PasswordHash = "Provider@123"
        });

        var merchant1 = await EnsureUserAsync(db, new User {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000003"),
            UserCode = "merchant001", UserName = "Ah Kau", MerchantName = "Teh Tarik Corner",
            Email = "merchant1@shop.com", PhoneNumber = "+60 12-345 6789", ICNumber = "990303-08-1111",
            RoleId = SystemRoles.Merchant, IsMerchant = true, MerchantDocsUrl = "https://example.com/docs/merchant001.pdf",
            PasswordHash = "Merchant1@123"
        });

        var merchant2 = await EnsureUserAsync(db, new User {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000004"),
            UserCode = "merchant002", UserName = "Ali", MerchantName = "Nasi Lemak House",
            Email = "merchant2@shop.com", PhoneNumber = "+60 11-2233 4455", ICNumber = "970404-10-2222",
            RoleId = SystemRoles.Merchant, IsMerchant = true, MerchantDocsUrl = "https://example.com/docs/merchant002.pdf",
            PasswordHash = "Merchant2@123"
        });

        var user1 = await EnsureUserAsync(db, new User {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000005"),
            UserCode = "user001", UserName = "ali_user", Email = "ali.user@gmail.com",
            PhoneNumber = "+60 19-111 2222", ICNumber = "000505-14-3333",
            RoleId = SystemRoles.User, IsMerchant = false, PasswordHash = "User1@123"
        });

        var user2 = await EnsureUserAsync(db, new User {
            UserId = Guid.Parse("11111111-1111-1111-1111-000000000006"),
            UserCode = "user002", UserName = "mei_user", Email = "mei.user@gmail.com",
            PhoneNumber = "+60 12-999 8888", ICNumber = "010606-10-4444",
            RoleId = SystemRoles.User, IsMerchant = false, PasswordHash = "User2@123"
        });

        // ---- Bank accounts: merchants must have 2 (1 merchant + 1 personal), at least one user has 2 ----
        await EnsureAccountsForMerchantAsync(db, merchant1,
            merchantAcct:  ("7800 11 000123", "MYR", "Maybank", "MBBE"),
            personalAcct:  ("7800 11 000124", "MYR", "Maybank", "MBBE"));

        await EnsureAccountsForMerchantAsync(db, merchant2,
            merchantAcct:  ("7800 22 000223", "MYR", "CIMB",   "CIMB"),
            personalAcct:  ("7800 22 000224", "MYR", "CIMB",   "CIMB"));

        // user1 -> 2 personal accounts
        await EnsurePersonalAccountAsync(db, user1, ("9001 00 000111", "MYR", "RHB", "RHB"));
        await EnsurePersonalAccountAsync(db, user1, ("9001 00 000113", "MYR", "RHB", "RHB"));

        // user2 -> 1 personal account
        await EnsurePersonalAccountAsync(db, user2, ("9001 00 000112", "MYR", "RHB", "RHB"));

        // admin + provider can have a simple personal account each (optional)
        await EnsurePersonalAccountAsync(db, admin,    ("7000 00 000001", "MYR", "Maybank", "MBBE"));
        await EnsurePersonalAccountAsync(db, provider, ("7000 00 000002", "MYR", "Maybank", "MBBE"));

        // Seed sample transactions after users and accounts are created
        await EnsureSampleTransactionsAsync(db, user1, merchant1, user1 /* as source bank owner, adjust if needed */);
    }

    // ---------------- helpers ----------------

    private static async Task<Role> EnsureRoleAsync(AppDbContext db, Guid id, string name)
    {
        var existing = await db.Roles.FirstOrDefaultAsync(r => r.Name == name);
        if (existing is null)
        {
            existing = new Role { RoleId = id, Name = name };
            db.Roles.Add(existing);
            await db.SaveChangesAsync();
        }
        else if (existing.RoleId != id)
        {
            db.Roles.Remove(existing);
            existing = new Role { RoleId = id, Name = name };
            db.Roles.Add(existing);
            await db.SaveChangesAsync();
        }
        return existing;
    }

    private static async Task<User> EnsureUserAsync(AppDbContext db, User u)
    {
        var existing = await db.Users.FirstOrDefaultAsync(x =>
            (!string.IsNullOrEmpty(u.Email) && x.Email == u.Email) || x.UserName == u.UserName);

        if (existing is null)
        {
            db.Users.Add(u);
            await db.SaveChangesAsync();
            return u;
        }

        // update key fields (don’t change PK)
        existing.UserCode        = u.UserCode;
        existing.PhoneNumber     = u.PhoneNumber;
        existing.ICNumber        = u.ICNumber;
        existing.RoleId          = u.RoleId;
        existing.IsMerchant      = u.IsMerchant;
        existing.MerchantName    = u.MerchantName;
        existing.MerchantDocsUrl = u.MerchantDocsUrl;
        existing.PasswordHash    = u.PasswordHash;
        await db.SaveChangesAsync();
        return existing;
    }

    private static async Task EnsureAccountsForMerchantAsync(
        AppDbContext db, User merchant,
        (string acctNo, string cur, string bankName, string bankCode) merchantAcct,
        (string acctNo, string cur, string bankName, string bankCode) personalAcct)
    {
        // merchant account (bound to MerchantId and UserId)
        await EnsureBankAccountAsync(db, new BankAccount
        {
            AccountNumber      = merchantAcct.acctNo,
            Currency           = merchantAcct.cur,
            BankName           = merchantAcct.bankName,
            BankCode           = merchantAcct.bankCode,
            AccountType        = "merchant",
            IsMerchantAccount  = true,
            MerchantId         = merchant.UserId,
            UserId             = merchant.UserId
        });

        // personal account for the same merchant (UserId owner, no MerchantId)
        await EnsureBankAccountAsync(db, new BankAccount
        {
            AccountNumber      = personalAcct.acctNo,
            Currency           = personalAcct.cur,
            BankName           = personalAcct.bankName,
            BankCode           = personalAcct.bankCode,
            AccountType        = "personal",
            IsMerchantAccount  = false,
            MerchantId         = null,
            UserId             = merchant.UserId
        });

        // sanity: if someone removed one, ensure there are >= 2 total accounts for this merchant
        var count = await db.BankAccounts.CountAsync(b => b.UserId == merchant.UserId);
        if (count < 2)
        {
            // add a synthetic extra personal if needed
            await EnsureBankAccountAsync(db, new BankAccount
            {
                AccountNumber = $"{merchant.UserCode}-P{count+1:D2}", // deterministic
                Currency      = "MYR",
                BankName      = "DefaultBank",
                BankCode      = "DFLT",
                AccountType   = "personal",
                IsMerchantAccount = false,
                MerchantId    = null,
                UserId        = merchant.UserId
            });
        }
    }

    private static async Task EnsurePersonalAccountAsync(
        AppDbContext db, User user,
        (string acctNo, string cur, string bankName, string bankCode) acct)
    {
        await EnsureBankAccountAsync(db, new BankAccount
        {
            AccountNumber      = acct.acctNo,
            Currency           = acct.cur,
            BankName           = acct.bankName,
            BankCode           = acct.bankCode,
            AccountType        = "personal",
            IsMerchantAccount  = false,
            MerchantId         = null,
            UserId             = user.UserId
        });
    }

    private static async Task EnsureBankAccountAsync(AppDbContext db, BankAccount b)
    {
        // upsert by unique AccountNumber
        var existing = await db.BankAccounts.FirstOrDefaultAsync(x => x.AccountNumber == b.AccountNumber);
        if (existing is null)
        {
            b.Balance = b.Balance == 0 ? 0m : b.Balance; // default 0 if omitted
            db.BankAccounts.Add(b);
            await db.SaveChangesAsync();
            return;
        }

        // update selected fields if changed
        existing.Currency          = b.Currency ?? existing.Currency;
        existing.BankName          = b.BankName ?? existing.BankName;
        existing.BankCode          = b.BankCode ?? existing.BankCode;
        existing.AccountType       = b.AccountType ?? existing.AccountType;
        await db.SaveChangesAsync();
    }

    private static async Task EnsureSampleTransactionsAsync(
        AppDbContext db,
        User payer,
        User merchant,
        User payerAsUser // often same as payer; but you might allow internal transfers or different bank owner
    )
    {
        // load at least one bank account from payer
        var payerAcct = await db.BankAccounts
            .Where(b => b.UserId == payer.UserId && !b.IsMerchantAccount)
            .OrderBy(b => b.BankAccountId)
            .FirstOrDefaultAsync();
        if (payerAcct == null) return;

        // load at least one merchant account from merchant
        var merchantAcct = await db.BankAccounts
            .Where(b => b.UserId == merchant.UserId && b.IsMerchantAccount)
            .OrderBy(b => b.BankAccountId)
            .FirstOrDefaultAsync();
        if (merchantAcct == null) return;

        // define some sample amounts & times
        var samples = new List<(decimal amount, string memo)> {
            (50, "Coffee purchase"),
            (120, "Lunch"),
            (15.5m, "Snack"),
            (300, "Groceries"),
            (75, "Books")
        };

        foreach (var s in samples)
        {
            // check if such transaction already exists (by amount + user + merchant + timestamp approx)
            var exists = await db.Transactions.AnyAsync(t =>
                t.UserId == payer.UserId
                && t.MerchantId == merchant.UserId
                && t.Amount == s.amount
            );
            if (exists) continue;

            var tx = new Transaction {
                UserId        = payer.UserId,
                BankAccountId = payerAcct.BankAccountId,
                MerchantId     = merchant.UserId,
                Amount        = s.amount,
                OccurredAt    = DateTime.UtcNow
            };
            db.Transactions.Add(tx);
            await db.SaveChangesAsync();
        }
    }

}