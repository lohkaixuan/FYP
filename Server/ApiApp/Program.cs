using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ApiApp.Services;
using DotNetEnv;
using ApiApp.Endpoints; // <— add this
using ApiApp.Models;  // <— add this

Env.Load();

var builder = WebApplication.CreateBuilder(args);

// Port from .env (PORT=1060)
var port = Environment.GetEnvironmentVariable("PORT") ?? "1060";
builder.WebHost.UseUrls($"http://localhost:{port}");

var neonConn = Environment.GetEnvironmentVariable("NEON_CONN");
if (string.IsNullOrWhiteSpace(neonConn))
    throw new InvalidOperationException("NEON_CONN is not set");

builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseNpgsql(neonConn)
    // If you installed the naming-conventions package, you can uncomment:
    //   .UseSnakeCaseNamingConvention()
);

// optional: swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 2) SEED after Build() (dev-only)
if (app.Environment.IsDevelopment())
{
    await AppDbSeeder.SeedAsync(app.Services);
}

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
    c.RoutePrefix = "swagger";
});

app.MapGet("/health", () => new { status = "OK" });

app.Run();