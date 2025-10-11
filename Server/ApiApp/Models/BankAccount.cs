using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models
{
    [Table("bank_accounts")]
    [Index(nameof(BankAccountNumber), IsUnique = true)]
    public class BankAccount
    {
        [Key]
        [Column("bank_account_id")]
        public Guid BankAccountId { get; set; } = Guid.NewGuid();

        [Required, MaxLength(40)]
        [Column("bank_account_number")]
        public string BankAccountNumber { get; set; } = string.Empty;

        // DEV/TEST plaintext for auto-login
        [MaxLength(80)]
        [Column("bank_username")]
        public string? BankUsername { get; set; }

        [MaxLength(120)]
        [Column("bank_userpassword")]
        public string? BankUserPassword { get; set; }

        [Column("bank_user_balance", TypeName = "decimal(18,2)")]
        public decimal BankUserBalance { get; set; } = 0m;

        [MaxLength(40)]
        [Column("bank_type")]
        public string? BankType { get; set; } // e.g., "CIMB"

        // "personal" or "merchant"
        [MaxLength(20)]
        [Column("bank_account_category")]
        public string? BankAccountCategory { get; set; }

        [Column("last_update")]
        public DateTime last_update { get; set; } = DateTime.UtcNow;

        // Ownership: either user or merchant
        [Column("user_id")]
        public Guid? UserId { get; set; }
        public User? User { get; set; }

        [Column("merchant_id")]
        public Guid? MerchantId { get; set; }
        public Merchant? Merchant { get; set; }
    }
}
