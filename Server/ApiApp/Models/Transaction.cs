// ==================================================
// Program Name   : Transaction.cs
// Purpose        : Transaction entity model
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;
using ApiApp.AI;
using CategoryEnum = ApiApp.AI.Category;
namespace ApiApp.Models;

[Table("transactions")]
[Index(nameof(transaction_timestamp))]
[Index(nameof(payment_method))]
[Index(nameof(transaction_status))]
public class Transaction
{
    [Key, Column("transaction_id")] public Guid transaction_id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(20)][Column("transaction_type")] public string transaction_type { get; set; } = "pay";
    [Required, MaxLength(120)][Column("transaction_from")] public string transaction_from { get; set; } = string.Empty;
    [Required, MaxLength(120)][Column("transaction_to")] public string transaction_to { get; set; } = string.Empty;

    [Column("from_user_id")] public Guid? from_user_id { get; set; }
    [Column("to_user_id")] public Guid? to_user_id { get; set; }
    [Column("from_merchant_id")] public Guid? from_merchant_id { get; set; }
    [Column("to_merchant_id")] public Guid? to_merchant_id { get; set; }
    [Column("from_bank_id")] public Guid? from_bank_id { get; set; }
    [Column("to_bank_id")] public Guid? to_bank_id { get; set; }
    [Column("from_wallet_id")] public Guid? from_wallet_id { get; set; }
    [Column("to_wallet_id")] public Guid? to_wallet_id { get; set; }

    [Column("transaction_amount", TypeName = "decimal(18,2)")] public decimal transaction_amount { get; set; }
    [Column("transaction_timestamp")] public DateTime transaction_timestamp { get; set; } = DateTime.UtcNow;

    [MaxLength(160)][Column("transaction_item")] public string? transaction_item { get; set; }   
    [MaxLength(400)][Column("transaction_detail")] public string? transaction_detail { get; set; } 

    [MaxLength(50)][Column("category")] public string? category { get; set; }

    [MaxLength(30)][Column("payment_method")] public string? payment_method { get; set; }
    [Required, MaxLength(20)][Column("transaction_status")] public string transaction_status { get; set; } = "success";
    [Column("last_update")] public DateTime last_update { get; set; } = DateTime.UtcNow;

    [Column("predicted_category")]
    public CategoryEnum? PredictedCategory { get; set; }

    [Column("predicted_confidence")]
    public double? PredictedConfidence { get; set; }

    [Column("final_category")]
    public CategoryEnum? FinalCategory { get; set; }

    [Column("ml_text")]
    public string? MlText { get; set; }

}
