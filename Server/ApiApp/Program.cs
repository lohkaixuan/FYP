using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using ApiApp.Models;

// Load .env (JWT_KEY, NEON_CONN, PORT, etc.)
Env.Load();

var builder = WebApplication.CreateBuilder(args);

// ----- Env / config -----
var port   = Environment.GetEnvironmentVariable("PORT") ?? "1060";
var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
            ?? throw new InvalidOperationException("JWT_KEY is not set");
var neonConn = Environment.GetEnvironmentVariable("NEON_CONN")
              ?? throw new InvalidOperationException("NEON_CONN is not set");

builder.WebHost.UseUrls($"http://localhost:{port}");

// ----- Services -----
builder.Services.AddDbContext<AppDbContext>(opt => opt.UseNpgsql(neonConn));
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// JWT auth with DB token check
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
        opt.Events = new JwtBearerEvents
        {
            OnTokenValidated = async ctx =>
            {
                var db = ctx.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
                var sub = ctx.Principal!.FindFirstValue(ClaimTypes.NameIdentifier)
                          ?? ctx.Principal!.FindFirstValue("sub");
                if (sub is null || !Guid.TryParse(sub, out var userId))
                {
                    ctx.Fail("Missing sub");
                    return;
                }
                var authz = ctx.Request.Headers["Authorization"].ToString();
                var token = authz.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) ? authz[7..] : null;

                var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == userId);
                if (user is null || string.IsNullOrWhiteSpace(user.JwtToken) || !string.Equals(user.JwtToken, token, StringComparison.Ordinal))
                {
                    ctx.Fail("Token not active for user");
                }
            }
        };
    });
builder.Services.AddAuthorization();

var app = builder.Build();

// Global error envelope (optional)
app.Use(async (ctx, next) =>
{
    try { await next(); }
    catch (OperationCanceledException)
    {
        ctx.Response.StatusCode = StatusCodes.Status504GatewayTimeout;
        await ctx.Response.WriteAsJsonAsync(new { ok = false, message = "Operation timed out" });
    }
    catch (TimeoutException)
    {
        ctx.Response.StatusCode = StatusCodes.Status504GatewayTimeout;
        await ctx.Response.WriteAsJsonAsync(new { ok = false, message = "Operation timed out" });
    }
    catch (Exception)
    {
        ctx.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await ctx.Response.WriteAsJsonAsync(new { ok = false, message = "Server error" });
    }
});

// Dev seed
if (app.Environment.IsDevelopment())
{
    await AppDbSeeder.SeedAsync(app.Services);
}

app.UseAuthentication();
app.UseAuthorization();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
    c.RoutePrefix = "swagger";
});

app.MapControllers();
app.Run();
