// ==================================================
// Program Name   : BankAccount.cs
// Purpose        : Bank account entity model
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
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
    public string? BankType { get; set; }

    
    [MaxLength(20)]
    [Column("bank_account_category")]
    public string? BankAccountCategory { get; set; }

    
    [Column("user_id")]
    public Guid? UserId { get; set; }
    public User? User { get; set; }

    [Column("merchant_id")]
    public Guid? MerchantId { get; set; }
    public Merchant? Merchant { get; set; }

   
    [Column("bank_link_id")]
    public Guid? BankLinkId { get; set; }
    public BankLink? BankLink { get; set; }

    string IAccount.AccountId => BankAccountNumber;
    decimal IAccount.Balance { get => BankUserBalance; set => BankUserBalance = value; }
}
