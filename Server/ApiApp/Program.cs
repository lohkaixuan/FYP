using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ApiApp.Services;
using DotNetEnv;
using ApiApp.Endpoints; // <— add this


Env.Load();

var builder = WebApplication.CreateBuilder(args);

// Port from .env (PORT=1060)
var port = Environment.GetEnvironmentVariable("PORT") ?? "1060";
builder.WebHost.UseUrls($"http://localhost:{port}");
var neonConn = Environment.GetEnvironmentVariable("NEON_CONN");
if (string.IsNullOrWhiteSpace(neonConn))
{
    throw new InvalidOperationException("NEON_CONN is not set in environment or .env file.");
}

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


    app.Run();
