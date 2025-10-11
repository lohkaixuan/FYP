using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) { }

        public DbSet<User> Users => Set<User>();
        public DbSet<Role> Roles => Set<Role>();
        public DbSet<Merchant> Merchants => Set<Merchant>();
        public DbSet<BankAccount> BankAccounts => Set<BankAccount>();
        public DbSet<Wallet> Wallets => Set<Wallet>();
        public DbSet<Transaction> Transactions => Set<Transaction>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Tables (optional if you already use [Table] attributes on models)
            modelBuilder.Entity<User>().ToTable("users");
            modelBuilder.Entity<Role>().ToTable("roles");
            modelBuilder.Entity<Merchant>().ToTable("merchants");
            modelBuilder.Entity<BankAccount>().ToTable("bank_accounts");
            modelBuilder.Entity<Transaction>().ToTable("transactions");

            // Money precision
            modelBuilder.Entity<User>()
                .Property(u => u.Balance)
                .HasPrecision(18, 2);

            modelBuilder.Entity<BankAccount>()
                .Property(b => b.BankUserBalance)
                .HasPrecision(18, 2);

            // User ↔ Role  (many Users per Role)
            modelBuilder.Entity<User>()
                .HasOne(u => u.Role)
                .WithMany(r => r.Users)
                .HasForeignKey(u => u.RoleId);

            // User ↔ BankAccounts (personal)  (1..n)
            modelBuilder.Entity<BankAccount>()
                .HasOne(b => b.User)
                .WithMany(u => u.BankAccounts)
                .HasForeignKey(b => b.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Merchant ↔ BankAccounts (merchant accounts) (1..n)
            modelBuilder.Entity<BankAccount>()
                .HasOne(b => b.Merchant)
                .WithMany(m => m.BankAccounts)
                .HasForeignKey(b => b.MerchantId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Wallet>().Property(w => w.wallet_balance).HasPrecision(18, 2);
        
            modelBuilder.Entity<Transaction>().Property(t => t.transaction_amount).HasPrecision(18, 2);

        }
    }
}
