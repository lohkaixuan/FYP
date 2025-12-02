// File: ApiApp/Models/AppDbContext.cs
using System.Reflection;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        // ===== DbSets (single source of truth) =====
        public DbSet<User> Users => Set<User>();
        public DbSet<Role> Roles => Set<Role>();
        public DbSet<Merchant> Merchants => Set<Merchant>();
        public DbSet<BankAccount> BankAccounts => Set<BankAccount>();
        public DbSet<Wallet> Wallets => Set<Wallet>();
        public DbSet<Transaction> Transactions => Set<Transaction>();

        // New tables
        public DbSet<Budget> Budgets => Set<Budget>();
        public DbSet<Provider> Providers => Set<Provider>();
        public DbSet<ProviderCredential> ProviderCredentials => Set<ProviderCredential>();
        public DbSet<BankLink> BankLinks => Set<BankLink>();

        // ===== Auto-maintain timestamps for BaseTracked =====
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            var now = DateTime.UtcNow;
            foreach (var entry in ChangeTracker.Entries<BaseTracked>())
            {
                if (entry.State == EntityState.Added)
                {
                    entry.Entity.CreatedAt = now;
                    entry.Entity.LastUpdate = now;
                }
                else if (entry.State == EntityState.Modified)
                {
                    entry.Entity.LastUpdate = now;
                }
            }
            return base.SaveChangesAsync(cancellationToken);
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ===== Table names (safe even if [Table] is present) =====
            modelBuilder.Entity<User>().ToTable("users");
            modelBuilder.Entity<Role>().ToTable("roles");
            modelBuilder.Entity<Merchant>().ToTable("merchants");
            modelBuilder.Entity<BankAccount>().ToTable("bank_accounts");
            modelBuilder.Entity<Wallet>().ToTable("wallets");
            modelBuilder.Entity<Transaction>().ToTable("transactions");
            modelBuilder.Entity<Budget>().ToTable("budgets");
            modelBuilder.Entity<Provider>().ToTable("providers");
            modelBuilder.Entity<ProviderCredential>().ToTable("provider_credentials");
            modelBuilder.Entity<BankLink>().ToTable("bank_links");
            // Map AI enums to string columns (no DB enum required)
            modelBuilder.Entity<Transaction>()
                .Property(t => t.PredictedCategory)
                .HasConversion<string>()
                .HasMaxLength(50);

            modelBuilder.Entity<Transaction>()
                .Property(t => t.FinalCategory)
                .HasConversion<string>()
                .HasMaxLength(50);
            // Merchant ↔ OwnerUser (1:1)
            modelBuilder.Entity<Merchant>()
                .HasOne(m => m.OwnerUser)
                .WithOne(u => u.Merchant)
                .HasForeignKey<Merchant>(m => m.OwnerUserId)
                .OnDelete(DeleteBehavior.Restrict);

            // Provider ↔ OwnerUser (optional, many providers per owner)
            modelBuilder.Entity<Provider>()
                .HasOne<User>()                 // no nav on User yet
                .WithMany()                    // if later you add ICollection<Provider> on User, change this
                .HasForeignKey(p => p.OwnerUserId)
                .OnDelete(DeleteBehavior.Restrict);

            // ===== Global query filter for soft delete (BaseTracked) =====
            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                if (typeof(BaseTracked).IsAssignableFrom(entityType.ClrType))
                {
                    var method = typeof(AppDbContext)
                        .GetMethod(nameof(ApplyIsDeletedFilter), BindingFlags.NonPublic | BindingFlags.Static)!
                        .MakeGenericMethod(entityType.ClrType);
                    method.Invoke(null, new object[] { modelBuilder });
                }
            }

            // ===== Money precision =====
            modelBuilder.Entity<User>()
                .Property(u => u.Balance)
                .HasPrecision(18, 2);

            modelBuilder.Entity<BankAccount>()
                .Property(b => b.BankUserBalance)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Wallet>()
                .Property(w => w.wallet_balance)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Transaction>()
                .Property(t => t.transaction_amount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Budget>()
                .Property(b => b.LimitAmount)
                .HasPrecision(18, 2);

            // ===== Relationships =====

            // User ↔ Role (many users per role)
            modelBuilder.Entity<User>()
                .HasOne(u => u.Role)
                .WithMany(r => r.Users)
                .HasForeignKey(u => u.RoleId);

            // User ↔ BankAccounts 1..n (delete user => delete accounts)
            modelBuilder.Entity<BankAccount>()
                .HasOne(b => b.User)
                .WithMany(u => u.BankAccounts)   // assuming User has ICollection<BankAccount>
                .HasForeignKey(b => b.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Merchant ↔ BankAccounts 1..n (restrict delete merchant)
            modelBuilder.Entity<BankAccount>()
                .HasOne(b => b.Merchant)
                .WithMany(m => m.BankAccounts)
                .HasForeignKey(b => b.MerchantId)
                .OnDelete(DeleteBehavior.Restrict);

            // BankAccount ↔ BankLink (optional, many accounts can reuse one link)
            modelBuilder.Entity<BankAccount>()
                .HasOne(b => b.BankLink)
                .WithMany() // you can add ICollection<BankAccount> on BankLink later if needed
                .HasForeignKey(b => b.BankLinkId)
                .OnDelete(DeleteBehavior.SetNull);

            // ProviderCredential ↔ Provider (cascade)
            modelBuilder.Entity<ProviderCredential>()
                .HasOne(pc => pc.Provider)
                .WithMany(p => p.Credentials)
                .HasForeignKey(pc => pc.ProviderId)
                .OnDelete(DeleteBehavior.Cascade);

            // BankLink ↔ Provider (restrict)
            modelBuilder.Entity<BankLink>()
                .HasOne(bl => bl.Provider)
                .WithMany() // add nav later if you want
                .HasForeignKey(bl => bl.ProviderId)
                .OnDelete(DeleteBehavior.Restrict);

            // ===== Indices =====

            // Budget: (UserId, Category, CycleStart, CycleEnd)
            modelBuilder.Entity<Budget>()
                .HasIndex(b => new { b.UserId, b.Category, b.CycleStart, b.CycleEnd });

            // BankLink: prevent duplicates per user/provider/accountRef
            modelBuilder.Entity<BankLink>()
                .HasIndex(bl => new { bl.UserId, bl.ProviderId, bl.ExternalAccountRef })
                .IsUnique();
        }

        // helper for soft delete filter
        private static void ApplyIsDeletedFilter<T>(ModelBuilder builder) where T : BaseTracked
            => builder.Entity<T>().HasQueryFilter(e => !e.IsDeleted);
    }
}
