using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ApiApp.Data;
using ApiApp.Services;
using DotNetEnv;

Env.Load();

var builder = WebApplication.CreateBuilder(args);

// Port from .env (PORT=1060)
var port = Environment.GetEnvironmentVariable("PORT") ?? "1060";
builder.WebHost.UseUrls($"http://localhost:{port}");

// DB connection from .env (NEON_CONN=...)
var connString = Environment.GetEnvironmentVariable("NEON_CONN")
                 ?? builder.Configuration.GetConnectionString("DefaultConnection")
                 ?? throw new InvalidOperationException("No connection string found. Set NEON_CONN or DefaultConnection.");

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDbContext<AppDbContext>(opt => opt.UseNpgsql(connString));
builder.Services.AddScoped<INoteHelper, NoteHelper>();

var app = builder.Build();

// ----- enable swagger in all envs (so you can always click it) -----
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
    c.RoutePrefix = "swagger"; // UI at /swagger
});

// ----- serve wwwroot/index.html at "/" -----
app.UseDefaultFiles();   // looks for index.html in wwwroot
app.UseStaticFiles();    // serves files from wwwroot

// OPTIONAL: if you don't want HTTPS redirect while testing on plain HTTP
// app.UseHttpsRedirection();

// Minimal CRUD
app.MapGet("/notes", async (INoteHelper h) => await h.GetAllAsync());
app.MapGet("/notes/{id:int}", async (INoteHelper h, int id) =>
    (await h.GetByIdAsync(id)) is { } n ? Results.Ok(n) : Results.NotFound());

app.MapPost("/notes", async (INoteHelper h, NoteDto dto) =>
{
    if (string.IsNullOrWhiteSpace(dto.Text)) return Results.BadRequest("Text required");
    var created = await h.CreateAsync(dto.Text);
    return Results.Created($"/notes/{created.Id}", created);
});

app.MapPut("/notes/{id:int}", async (INoteHelper h, int id, NoteDto dto) =>
    await h.UpdateAsync(id, dto.Text) ? Results.NoContent() : Results.NotFound());

app.MapDelete("/notes/{id:int}", async (INoteHelper h, int id) =>
    await h.DeleteAsync(id) ? Results.NoContent() : Results.NotFound());

// Health ping so you can test quickly
app.MapGet("/health", () => Results.Ok(new { status = "OK", port }));

app.Run();

public record NoteDto(string Text);
