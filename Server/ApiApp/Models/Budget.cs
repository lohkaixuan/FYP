// ApiApp/Models/Budget.cs
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
