using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models;

[Table("transactions")]
[Index(nameof(transaction_timestamp))]
[Index(nameof(payment_method))]
[Index(nameof(transaction_status))]
public class Transaction
{
    [Key]
    [Column("transaction_id")]
    public Guid transaction_id { get; set; } = Guid.NewGuid();

    // What kind of transaction this is: "pay" (buyer→seller), "transfer" (user→user/account), "topup" (bank→wallet)
    [Required, MaxLength(20)]
    [Column("transaction_type")]
    public string transaction_type { get; set; } = "pay"; // "pay" | "transfer" | "topup"

    // Who/where funds come from — can be account number, name, or id (store snapshot string for audit)
    [Required, MaxLength(120)]
    [Column("transaction_from")]
    public string transaction_from { get; set; } = string.Empty;

    // Who/where funds go to — can be account number, name, or id (store snapshot string for audit)
    [Required, MaxLength(120)]
    [Column("transaction_to")]
    public string transaction_to { get; set; } = string.Empty;

    // Optional normalized references (use whichever applies)
    [Column("from_user_id")]     public Guid? from_user_id { get; set; }
    [Column("to_user_id")]       public Guid? to_user_id { get; set; }
    [Column("from_merchant_id")] public Guid? from_merchant_id { get; set; }
    [Column("to_merchant_id")]   public Guid? to_merchant_id { get; set; }
    [Column("from_bank_id")]     public Guid? from_bank_id { get; set; }      // BankAccountId
    [Column("to_bank_id")]       public Guid? to_bank_id { get; set; }        // BankAccountId
    [Column("from_wallet_id")]   public Guid? from_wallet_id { get; set; }
    [Column("to_wallet_id")]     public Guid? to_wallet_id { get; set; }

    // Amount & when
    [Column("transaction_amount", TypeName = "decimal(18,2)")]
    public decimal transaction_amount { get; set; }

    [Column("transaction_timestamp")]
    public DateTime transaction_timestamp { get; set; } = DateTime.UtcNow;

    // Details for receipt/statement
    [MaxLength(160)]
    [Column("transaction_item")]
    public string? transaction_item { get; set; } // e.g., “Latte 1x”

    [MaxLength(400)]
    [Column("transaction_detail")]
    public string? transaction_detail { get; set; } // free text notes

    [MaxLength(50)]
    [Column("category")]
    public string? category { get; set; } // user-defined: “Food”, “Transport”, etc.

    // Payment method & status
    [MaxLength(30)]
    [Column("payment_method")]
    public string? payment_method { get; set; } // e.g., "wallet", "bank", "card", "qr", "transfer"

    [Required, MaxLength(20)]
    [Column("transaction_status")]
    public string transaction_status { get; set; } = "success"; // "pending"|"success"|"failed"
    
    [Column("last_update")]
    public DateTime last_update { get; set; } = DateTime.UtcNow;

    // Optional navigations (no cascade rules here; keep simple)
    [ForeignKey(nameof(from_user_id))]     public User? from_user { get; set; }
    [ForeignKey(nameof(to_user_id))]       public User? to_user { get; set; }
    [ForeignKey(nameof(from_merchant_id))] public Merchant? from_merchant { get; set; }
    [ForeignKey(nameof(to_merchant_id))]   public Merchant? to_merchant { get; set; }
    [ForeignKey(nameof(from_bank_id))]     public BankAccount? from_bank { get; set; }
    [ForeignKey(nameof(to_bank_id))]       public BankAccount? to_bank { get; set; }
    [ForeignKey(nameof(from_wallet_id))]   public Wallet? from_wallet { get; set; }
    [ForeignKey(nameof(to_wallet_id))]     public Wallet? to_wallet { get; set; }
}
