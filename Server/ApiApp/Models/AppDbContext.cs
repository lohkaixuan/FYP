using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) { }

        public DbSet<User> Users => Set<User>();
        public DbSet<Role> Roles => Set<Role>();
        public DbSet<BankAccount> BankAccounts => Set<BankAccount>();
        public DbSet<Transaction> Transactions => Set<Transaction>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ----- tables (you already had these) -----
            modelBuilder.Entity<User>().ToTable("users");
            modelBuilder.Entity<Role>().ToTable("roles");
            modelBuilder.Entity<BankAccount>().ToTable("bank_accounts");
            modelBuilder.Entity<Transaction>().ToTable("transactions");

            // ----- relationships (you already had these) -----
            // User -> Role
            modelBuilder.Entity<User>()
                .HasOne(u => u.Role)
                .WithMany(r => r.Users)
                .HasForeignKey(u => u.RoleId)
                .OnDelete(DeleteBehavior.Restrict);

            // BankAccount -> User (owner)
            modelBuilder.Entity<BankAccount>()
                .HasOne(b => b.User)
                .WithMany(u => u.BankAccounts)
                .HasForeignKey(b => b.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // BankAccount -> Merchant (optional)
            modelBuilder.Entity<BankAccount>()
                .HasOne(b => b.Merchant)
                .WithMany() // no collection on User to avoid navigation clash
                .HasForeignKey(b => b.MerchantId)
                .OnDelete(DeleteBehavior.Restrict);

            // Transaction -> Payer (User)
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.User)
                .WithMany(u => u.TransactionsAsPayer)
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            // Transaction -> Merchant (User)
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.Merchant)
                .WithMany(u => u.TransactionsAsMerchant)
                .HasForeignKey(t => t.MerchantId)
                .OnDelete(DeleteBehavior.Restrict);

            // Transaction -> BankAccount (source)
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.BankAccount)
                .WithMany()
                .HasForeignKey(t => t.BankAccountId)
                .OnDelete(DeleteBehavior.Restrict);

            // ----- precision for money -----
            modelBuilder.Entity<BankAccount>().Property(b => b.Balance).HasPrecision(18, 2);
            modelBuilder.Entity<Transaction>().Property(t => t.Amount).HasPrecision(18, 2);

            // ==========================================================
            // ===============  SNAKE_CASE COLUMN MAPPING  ==============
            // ==========================================================

            // roles
            modelBuilder.Entity<Role>().Property(r => r.RoleId).HasColumnName("role_id");
            modelBuilder.Entity<Role>().Property(r => r.Name).HasColumnName("name");

            // users
            modelBuilder.Entity<User>().Property(u => u.UserId).HasColumnName("user_id");
            modelBuilder.Entity<User>().Property(u => u.UserCode).HasColumnName("user_code");
            modelBuilder.Entity<User>().Property(u => u.UserName).HasColumnName("user_name");
            modelBuilder.Entity<User>().Property(u => u.Email).HasColumnName("email");
            modelBuilder.Entity<User>().Property(u => u.PhoneNumber).HasColumnName("phone_number");
            modelBuilder.Entity<User>().Property(u => u.ICNumber).HasColumnName("ic_number");
            modelBuilder.Entity<User>().Property(u => u.RoleId).HasColumnName("role_id");
            modelBuilder.Entity<User>().Property(u => u.IsMerchant).HasColumnName("is_merchant");
            modelBuilder.Entity<User>().Property(u => u.MerchantName).HasColumnName("merchant_name");
            modelBuilder.Entity<User>().Property(u => u.MerchantDocsUrl).HasColumnName("merchant_docs_url");
            modelBuilder.Entity<User>().Property(u => u.PasswordHash).HasColumnName("password_hash");

            // bank_accounts
            modelBuilder.Entity<BankAccount>().Property(b => b.BankAccountId).HasColumnName("bank_account_id");
            modelBuilder.Entity<BankAccount>().Property(b => b.AccountNumber).HasColumnName("account_number");
            modelBuilder.Entity<BankAccount>().Property(b => b.Balance).HasColumnName("balance");
            modelBuilder.Entity<BankAccount>().Property(b => b.Currency).HasColumnName("currency");
            modelBuilder.Entity<BankAccount>().Property(b => b.BankName).HasColumnName("bank_name");
            modelBuilder.Entity<BankAccount>().Property(b => b.BankCode).HasColumnName("bank_code");
            modelBuilder.Entity<BankAccount>().Property(b => b.AccountType).HasColumnName("account_type");
            modelBuilder.Entity<BankAccount>().Property(b => b.UserId).HasColumnName("user_id");
            modelBuilder.Entity<BankAccount>().Property(b => b.IsMerchantAccount).HasColumnName("is_merchant_account");
            modelBuilder.Entity<BankAccount>().Property(b => b.MerchantId).HasColumnName("merchant_id");

            // transactions
            modelBuilder.Entity<Transaction>().Property(t => t.TransactionId).HasColumnName("transaction_id");
            modelBuilder.Entity<Transaction>().Property(t => t.UserId).HasColumnName("user_id");
            modelBuilder.Entity<Transaction>().Property(t => t.BankAccountId).HasColumnName("bank_account_id");
            modelBuilder.Entity<Transaction>().Property(t => t.MerchantId).HasColumnName("merchant_id");
            modelBuilder.Entity<Transaction>().Property(t => t.Amount).HasColumnName("amount");
            modelBuilder.Entity<Transaction>().Property(t => t.OccurredAt).HasColumnName("occurred_at");
        }
    }
}
