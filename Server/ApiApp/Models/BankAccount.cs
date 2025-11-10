// ApiApp/Models/BankAccount.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models;

[Table("bank_accounts")]
[Index(nameof(BankAccountNumber), IsUnique = true)]
public class BankAccount : BaseTracked, IAccount
{
    [Key]
    [Column("bank_account_id")]
    public Guid BankAccountId { get; set; } = Guid.NewGuid();

    [Required, MaxLength(40)]
    [Column("bank_account_number")]
    public string BankAccountNumber { get; set; } = string.Empty;

    // ======= TEST ONLY: plaintext for auto-login =======
    // TODO(PROD): Remove plaintext; store only encrypted/hashed secrets.
    [MaxLength(80)]
    [Column("bank_username")]
    public string? BankUsername { get; set; }

    [MaxLength(120)]
    [Column("bank_userpassword")] // keep name; comment says plaintext for test
    public string? BankUserPassword { get; set; }
    // ======= /TEST ONLY =======

    [Column("bank_user_balance", TypeName = "decimal(18,2)")]
    public decimal BankUserBalance { get; set; } = 0m;

    [MaxLength(40)]
    [Column("bank_type")] // e.g., "CIMB"
    public string? BankType { get; set; }

    // "personal" or "merchant"
    [MaxLength(20)]
    [Column("bank_account_category")]
    public string? BankAccountCategory { get; set; }

    // Ownership: either user or merchant
    [Column("user_id")]
    public Guid? UserId { get; set; }
    public User? User { get; set; }

    [Column("merchant_id")]
    public Guid? MerchantId { get; set; }
    public Merchant? Merchant { get; set; }

    // ✅ NEW: link this account to a provider via BankLink
    // This lets you “view balance” and “top up” using the same link.
    [Column("bank_link_id")]
    public Guid? BankLinkId { get; set; }
    public BankLink? BankLink { get; set; }

    string IAccount.AccountId => BankAccountNumber;
    decimal IAccount.Balance { get => BankUserBalance; set => BankUserBalance = value; }
}
