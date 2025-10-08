using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models
{
    [Index(nameof(UserName), IsUnique = true)]
    [Index(nameof(ICNumber), IsUnique = true)]
    [Index(nameof(Email), IsUnique = true)]
    public class User
    {
        [Key]
        public Guid UserId { get; set; } = Guid.NewGuid();

        // Human-friendly code like "user001"
        [Required, MaxLength(20)]
        public string UserCode { get; set; } = string.Empty;

        [Required, MaxLength(80)]
        public string UserName { get; set; } = string.Empty;

        [MaxLength(120)]
        public string? Email { get; set; } // for Gmail login

        [MaxLength(25)]
        public string? PhoneNumber { get; set; } // keep formatting like "+60 12-345 6789"

        [Required, MaxLength(20)]
        public string ICNumber { get; set; } = string.Empty; // e.g. "990101-14-1234"

        // FK to Role
        [Required]
        public Guid RoleId { get; set; }
        public Role Role { get; set; } = default!;

        public bool IsMerchant { get; set; }

        [MaxLength(256)]
        public string? MerchantDocsUrl { get; set; }
        [MaxLength(80)]
        public string? MerchantName { get; set; } = string.Empty;
        // For development: store plain text or a hash here (prefer hash in production)
        [Required, MaxLength(200)]
        public string PasswordHash { get; set; } = string.Empty;

        // Navs (define BankAccount/Transaction in your project as needed)
        public ICollection<BankAccount> BankAccounts { get; set; } = new List<BankAccount>();
        public ICollection<Transaction> TransactionsAsPayer { get; set; } = new List<Transaction>();
        public ICollection<Transaction> TransactionsAsMerchant { get; set; } = new List<Transaction>();
    }
}
