// =============================
// Controllers/UsersController.cs
// =============================
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;

namespace ApiApp.Controllers;


[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly AppDbContext _db;
    public UsersController(AppDbContext db) { _db = db; }


    [HttpGet("me")]
    public async Task<IResult> Me()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (sub is null || !Guid.TryParse(sub, out var uid)) return Results.Unauthorized();
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == uid);
        return user is null ? Results.NotFound() : Results.Ok(user);
    }


    [HttpGet]
    public async Task<IResult> List() => Results.Ok(await _db.Users.AsNoTracking().ToListAsync());


    [HttpGet("{id:guid}")]
    public async Task<IResult> Get(Guid id)
    {
        var u = await _db.Users.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == id);
        return u is null ? Results.NotFound() : Results.Ok(u);
    }
}