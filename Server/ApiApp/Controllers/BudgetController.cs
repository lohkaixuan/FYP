// File: ApiApp/Controllers/BudgetsController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/budgets")]
public class BudgetsController : ControllerBase
{
    private readonly AppDbContext _db;

    public BudgetsController(AppDbContext db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Budget dto)
    {
        if (dto.CycleEnd <= dto.CycleStart) return BadRequest("cycle end must be after start");
        _db.Budgets.Add(dto);
        await _db.SaveChangesAsync();
        return Ok(dto);
    }

    [HttpGet("summary/{userId:guid}")]
    public async Task<IActionResult> Summary(Guid userId)
    {
        var now = DateTime.UtcNow;
        var budgets = await _db.Budgets
            .Where(b => b.UserId == userId && b.CycleStart <= now && b.CycleEnd >= now)
            .ToListAsync();

        var result = new List<object>();
        foreach (var b in budgets)
        {
            // FinalCategory 优先；若为空再用 PredictedCategory
            var spent = await _db.Transactions
                .Where(t => t.from_user_id == userId
                         && t.transaction_timestamp >= b.CycleStart
                         && t.transaction_timestamp <= b.CycleEnd
                         && (
                              (t.FinalCategory != null && t.FinalCategory!.ToString() == b.Category)
                           || (t.PredictedCategory != null && t.PredictedCategory!.ToString() == b.Category)
                         ))
                .SumAsync(t => t.transaction_amount);

            var remaining = b.LimitAmount - spent;
            result.Add(new
            {
                b.Category,
                b.LimitAmount,
                Spent = spent,
                Remaining = remaining,
                Percent = b.LimitAmount == 0 ? 0 : Math.Round((double)spent / (double)b.LimitAmount * 100, 2)
            });
        }

        return Ok(result);
    }
}
