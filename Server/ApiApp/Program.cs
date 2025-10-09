using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ApiApp.Helpers;
using ApiApp.Controllers;
using ApiApp.Models;
using DotNetEnv;

Env.Load(); // loads .env

var builder = WebApplication.CreateBuilder(args);

// ---- Port binding (default 1060) ----
var port = Environment.GetEnvironmentVariable("PORT") ?? "1060";
builder.WebHost.UseUrls($"http://localhost:{port}");

// ---- Neon/Postgres connection ----
var neonConn = Environment.GetEnvironmentVariable("NEON_CONN");
if (string.IsNullOrWhiteSpace(neonConn))
    throw new InvalidOperationException("NEON_CONN is not set");

// ---- Services ----
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseNpgsql(neonConn)
    // .UseSnakeCaseNamingConvention() // uncomment if you use it
);

builder.Services.AddSingleton<INeonCrud>(_ => new NeonHelper(neonConn));
builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

/* ===== Global timeout/error envelope ===== */
app.Use(async (ctx, next) =>
{
    try
    {
        await next();
    }
    catch (OperationCanceledException)
    {
        ctx.Response.StatusCode = StatusCodes.Status504GatewayTimeout;
        await ctx.Response.WriteAsJsonAsync(
            new ApiApp.Helpers.ApiResponse<object?>(StatusCodes.Status504GatewayTimeout, false, "Operation timed out", null));
    }
    catch (TimeoutException)
    {
        ctx.Response.StatusCode = StatusCodes.Status504GatewayTimeout;
        await ctx.Response.WriteAsJsonAsync(
            new ApiApp.Helpers.ApiResponse<object?>(StatusCodes.Status504GatewayTimeout, false, "Operation timed out", null));
    }
    catch (Exception)
    {
        ctx.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await ctx.Response.WriteAsJsonAsync(
            new ApiApp.Helpers.ApiResponse<object?>(StatusCodes.Status500InternalServerError, false, "Server error", null));
    }
});

/* ===== Dev seed ===== */
if (app.Environment.IsDevelopment())
{
    await AppDbSeeder.SeedAsync(app.Services);
}

/* ===== Static homepage at "/" =====
   Put your index.html at:  wwwroot/index.html  */
app.UseDefaultFiles();   // serves index.html by default
app.UseStaticFiles();    // enables static file hosting from wwwroot

/* ===== Swagger ===== */
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
    c.RoutePrefix = "swagger"; // available at /swagger
});

/* ===== MVC routes (your 3 controllers) ===== */
app.MapControllers();

/* No /health endpoint anymore */

app.Run();
