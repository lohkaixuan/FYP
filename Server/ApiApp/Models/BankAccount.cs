using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models
{
    [Index(nameof(AccountNumber), IsUnique = true)]
    public class BankAccount
    {
        [Key]
        public Guid BankAccountId { get; set; } = Guid.NewGuid();

        [Required, MaxLength(40)]
        public string AccountNumber { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Balance { get; set; } = 0m;

        // Foreign key to the user who owns this account
        [Required]
        public Guid UserId { get; set; }
        public User User { get; set; } = default!;

        // BankAccount.cs (additions)
        [MaxLength(80)]
        public string? BankName { get; set; }

        [MaxLength(20)]
        public string? BankCode { get; set; }   // e.g., 'MBBEMYKL' or internal code

        [MaxLength(20)]
        public string? AccountType { get; set; } // 'personal', 'merchant', 'savings', etc.

        [MaxLength(3)]
        public string? Currency { get; set; } = "MYR";

        public bool IsMerchantAccount { get; set; } = false;

        // When IsMerchantAccount = true, bind to a merchant (who is also a user)
        public Guid? MerchantId { get; set; }
        public User? Merchant { get; set; }

    }
}
