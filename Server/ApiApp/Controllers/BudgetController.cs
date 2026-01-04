// ==================================================
// Program Name   : BudgetController.cs
// Purpose        : API endpoints for budget management
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using ApiApp.Models;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/budget")]
[Authorize]
public sealed class BudgetController : ControllerBase
{
    private readonly AppDbContext _db;
    public BudgetController(AppDbContext db)
    {
        _db = db;
    }

    private bool TryGetUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var raw =
            User.FindFirstValue(ClaimTypes.NameIdentifier) ??
            User.FindFirstValue("sub") ??
            User.FindFirstValue("user_id") ??
            User.FindFirstValue("id");
        return Guid.TryParse(raw, out userId);
    }

    public sealed class UpsertBudgetDto
    {
        public string? category { get; set; }
        public int year { get; set; }
        public int month { get; set; }
        public decimal limitAmount { get; set; }
    }

    // POST /api/budget/upsert
    [HttpPost("upsert")]
    public async Task<IActionResult> Upsert([FromBody] UpsertBudgetDto dto)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        if (string.IsNullOrWhiteSpace(dto.category))
            return BadRequest(new { message = "category is required" });
        if (dto.year <= 0 || dto.month < 1 || dto.month > 12)
            return BadRequest(new { message = "year/month invalid" });

        var cat = dto.category.Trim().ToLowerInvariant();
        var cycleStart = new DateTime(dto.year, dto.month, 1, 0, 0, 0, DateTimeKind.Utc);
        var cycleEnd = cycleStart.AddMonths(1).AddTicks(-1);
        var existing = await _db.Budgets.FirstOrDefaultAsync(b =>
            b.UserId == userId &&
            b.Category == cat &&
            b.CycleStart == cycleStart &&
            b.CycleEnd == cycleEnd);

        if (existing == null)
        {
            existing = new Budget
            {
                BudgetId = Guid.NewGuid(),
                UserId = userId,
                Category = cat,
                CycleStart = cycleStart,
                CycleEnd = cycleEnd,
                LimitAmount = dto.limitAmount,
            };
            _db.Budgets.Add(existing);
        }
        else
        {
            existing.LimitAmount = dto.limitAmount;
        }

        await _db.SaveChangesAsync();
        return Ok(existing);
    }

    // GET /api/budget?year=&month=
    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] int? year, [FromQuery] int? month)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var now = DateTime.UtcNow;
        var y = year ?? now.Year;
        var m = month ?? now.Month;
        var start = new DateTime(y, m, 1, 0, 0, 0, DateTimeKind.Utc);
        var end = start.AddMonths(1).AddTicks(-1);
        var rows = await _db.Budgets
            .Where(b => b.UserId == userId && b.CycleStart == start && b.CycleEnd == end)
            .ToListAsync();

        return Ok(rows);
    }
}
