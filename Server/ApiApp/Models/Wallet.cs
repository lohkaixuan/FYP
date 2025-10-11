using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models;

[Table("wallets")]
[Index(nameof(wallet_number), IsUnique = true)]
[Index(nameof(user_id))]
[Index(nameof(merchant_id))]
public class Wallet
{
    [Key]
    [Column("wallet_id")]
    public Guid wallet_id { get; set; } = Guid.NewGuid();

    // NEW: bank-like wallet number (unique)
    [MaxLength(40)]
    [Column("wallet_number")]
    public string? wallet_number { get; set; }

    [Column("wallet_balance", TypeName = "decimal(18,2)")]
    public decimal wallet_balance { get; set; } = 0m;

    [Column("last_update")]
    public DateTime last_update { get; set; } = DateTime.UtcNow;

    [Column("user_id")]     public Guid? user_id { get; set; }
    [Column("merchant_id")] public Guid? merchant_id { get; set; }

    [ForeignKey(nameof(user_id))]     public User? user { get; set; }
    [ForeignKey(nameof(merchant_id))] public Merchant? merchant { get; set; }
}
