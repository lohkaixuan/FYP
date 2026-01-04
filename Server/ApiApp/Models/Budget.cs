// ==================================================
// Program Name   : Budget.cs
// Purpose        : Budget entity model
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

[Table("budgets")]
[Index(nameof(UserId), nameof(Category), nameof(CycleStart), nameof(CycleEnd))]
public class Budget : BaseTracked
{
    [Key, Column("budget_id")]
    public Guid BudgetId { get; set; } = Guid.NewGuid();

    [Required, Column("user_id")]
    public Guid UserId { get; set; }

    [MaxLength(50), Column("category")]
    public string Category { get; set; } = "General";

    [Column("limit_amount", TypeName = "decimal(18,2)")]
    public decimal LimitAmount { get; set; } = 0m;

    [Column("cycle_start")]
    public DateTime CycleStart { get; set; }

    [Column("cycle_end")]
    public DateTime CycleEnd { get; set; }
}
