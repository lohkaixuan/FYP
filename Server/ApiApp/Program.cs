using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;   // ✅ needed for UseForwardedHeaders
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using ApiApp.Models;

// Load .env locally (Render uses dashboard env vars)
Env.Load();

var builder = WebApplication.CreateBuilder(args);

// ----- Env / config -----
var jwtKey   = Environment.GetEnvironmentVariable("JWT_KEY")
               ?? throw new InvalidOperationException("JWT_KEY is not set");
var neonConn = Environment.GetEnvironmentVariable("NEON_CONN")
               ?? throw new InvalidOperationException("NEON_CONN is not set");

// ❌ DO NOT hard-bind to localhost/port on Render
// builder.WebHost.UseUrls($"http://localhost:{port}");
// ✅ Let ASPNETCORE_URLS control binding (Render sets ASPNETCORE_URLS=http://0.0.0.0:${PORT})

// ----- Services -----
builder.Services.AddDbContext<AppDbContext>(opt => opt.UseNpgsql(neonConn));
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// (Optional) CORS for your web app domains
builder.Services.AddCors(o => o.AddPolicy("AllowWeb", p =>
    p.WithOrigins(
        "https://your-frontend.vercel.app",
        "https://yourdomain.com"
    )
    .AllowAnyHeader()
    .AllowAnyMethod()
    .AllowCredentials()
));

// JWT auth with DB token check
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
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
                var db  = ctx.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
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
                if (user is null || string.IsNullOrWhiteSpace(user.JwtToken) ||
                    !string.Equals(user.JwtToken, token, StringComparison.Ordinal))
                {
                    ctx.Fail("Token not active for user");
                }
            }
        };
    });
builder.Services.AddAuthorization();

var app = builder.Build();

// Trust proxy headers (Render terminates TLS)
app.UseForwardedHeaders(new ForwardedHeadersOptions {
    ForwardedHeaders = ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedFor
});

// ⚠️ Keep https redirect only if it doesn't loop after enabling forwarded headers
app.UseHttpsRedirection();

app.MapGet("/healthz", () => Results.Ok("ok"));

// Global error envelope
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

// (Optional) Seed only in Development
if (app.Environment.IsDevelopment())
{
    await AppDbSeeder.SeedAsync(app.Services);
}

app.UseCors("AllowWeb");        // ✅ if you added CORS policy
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
