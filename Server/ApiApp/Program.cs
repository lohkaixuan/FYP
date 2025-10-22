using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using ApiApp.Models;

// ---- Load .env for local/dev ----
Env.Load();

var builder = WebApplication.CreateBuilder(args);

// ----- Env / config -----
var jwtKey   = Environment.GetEnvironmentVariable("JWT_KEY")
               ?? throw new InvalidOperationException("JWT_KEY is not set");
var neonConn = Environment.GetEnvironmentVariable("NEON_CONN")
               ?? throw new InvalidOperationException("NEON_CONN is not set");

// Detect platform/runtime
var isRender = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER"))
               || !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER_EXTERNAL_URL"))
               || !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER_INTERNAL_IP"));

var isDev = builder.Environment.IsDevelopment();

// ✅ Local dev: honor PORT (and optional BIND) from .env if ASPNETCORE_URLS not already set
//    This lets you do: PORT=5088 dotnet run  (or put PORT in .env)
if (isDev && string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("ASPNETCORE_URLS")))
{
    var port = Environment.GetEnvironmentVariable("PORT") ?? "5000";
    var bind = Environment.GetEnvironmentVariable("BIND") ?? "localhost"; // use 0.0.0.0 to expose to LAN/emulators
    builder.WebHost.UseUrls($"http://{bind}:{port}");
    // 小贴士: Android 模拟器可用 BIND=0.0.0.0，然后从设备访问 http://<你的局域网IP>:<PORT>
}

// ----- Services -----
builder.Services.AddDbContext<AppDbContext>(opt => opt.UseNpgsql(neonConn));
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS
builder.Services.AddCors(o => o.AddPolicy("AllowWeb", p =>
    p.WithOrigins(
        "https://your-frontend.vercel.app",
        "https://yourdomain.com",
        "http://localhost:3000",        // dev 前端
        "http://127.0.0.1:3000"         // dev 前端（另一种写法）
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

// ---- Proxy/HTTPS behavior ----
// Only trust forwarded headers when actually behind a proxy (Render)
if (isRender)
{
    app.UseForwardedHeaders(new ForwardedHeadersOptions
    {
        ForwardedHeaders = ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedFor
    });
}

// Avoid HTTPS redirect loop in local dev; keep it in Render/prod
if (isRender || !isDev)
{
    app.UseHttpsRedirection();
}

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
app.UseDefaultFiles();
app.UseStaticFiles();

app.UseCors("AllowWeb");
app.UseAuthentication();
app.UseAuthorization();



// Swagger: always on (you can restrict to dev if you prefer)
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
    c.RoutePrefix = "swagger";
});

app.MapControllers();
app.MapFallbackToFile("index.html");

app.Run();
