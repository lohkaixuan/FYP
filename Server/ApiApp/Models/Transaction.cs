
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models
{
    [Index(nameof(OccurredAt))]
    public class Transaction
    {
        [Key]
        public Guid TransactionId { get; set; } = Guid.NewGuid();

        // The user who initiates / pays
        [Required]
        public Guid UserId { get; set; }
        public User User { get; set; } = default!;

        // Source bank account
        [Required]
        public Guid BankAccountId { get; set; }
        public BankAccount BankAccount { get; set; } = default!;

        // Merchant user (optional)
        public Guid? MerchantId { get; set; }
        public User? Merchant { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
    }
}
