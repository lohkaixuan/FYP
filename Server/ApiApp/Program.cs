// File: ApiApp/Program.cs
using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using System.Text.Json.Serialization;
using Npgsql;

using ApiApp.Models;
using ApiApp.AI;        // Category / ICategorizer / RulesCategorizer / ZeroShotCategorizer
using ApiApp.Providers; // ProviderRegistry, MockBankClient
using ApiApp.Helpers;   // ICryptoService, AesCryptoService

Env.Load(); // load .env first

var builder = WebApplication.CreateBuilder(args);

/* ──────────────────────────────────────────────────────────────
 * 0) ENV / HOST CONFIG
 * ──────────────────────────────────────────────────────────────*/

var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
            ?? throw new InvalidOperationException("JWT_KEY is not set");

var neonConn = Environment.GetEnvironmentVariable("NEON_CONN")
              ?? throw new InvalidOperationException("NEON_CONN is not set");

// AES key for provider credentials (must exist in .env)
var aesKey = Environment.GetEnvironmentVariable("AES_KEY")
            ?? throw new InvalidOperationException("AES_KEY is not set");

// expose to configuration so AesCryptoService 可以通过 IConfiguration 读取
builder.Configuration["Crypto:AesKey"] = aesKey;

var isRender =
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER")) ||
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER_EXTERNAL_URL")) ||
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER_INTERNAL_IP"));

var isDev = builder.Environment.IsDevelopment();

var seedFlag = (Environment.GetEnvironmentVariable("SEED") ?? "")
    .Equals("1", StringComparison.OrdinalIgnoreCase)
 || (Environment.GetEnvironmentVariable("SEED") ?? "")
    .Equals("true", StringComparison.OrdinalIgnoreCase);

// 本地开发自动设定 URL
if (isDev && string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("ASPNETCORE_URLS")))
{
    var port = Environment.GetEnvironmentVariable("PORT") ?? "5000";
    var bind = Environment.GetEnvironmentVariable("BIND") ?? "localhost";
    builder.WebHost.UseUrls($"http://{bind}:{port}");
}

/* ──────────────────────────────────────────────────────────────
 * 1) SERVICES
 * ──────────────────────────────────────────────────────────────*/

// 1.1 Npgsql DataSource + EF Core
builder.Services.AddSingleton<NpgsqlDataSource>(_ =>
{
    var dsb = new NpgsqlDataSourceBuilder(neonConn);
    return dsb.Build();
});

builder.Services.AddDbContext<AppDbContext>((sp, opt) =>
    opt.UseNpgsql(sp.GetRequiredService<NpgsqlDataSource>()));

// 1.2 Controllers + JSON enum as string
builder.Services.AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

// 1.3 Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new()
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
        Name        = "Authorization",
        In          = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type        = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme      = "Bearer"
    });
    c.AddSecurityRequirement(new()
    {
        {
            new()
            {
                Reference = new()
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id   = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// 1.4 CORS
builder.Services.AddCors(o => o.AddPolicy("AllowWeb", p =>
{
    if (isDev)
        p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    else
        p.WithOrigins(
             "https://your-frontend.vercel.app",
             "https://yourdomain.com",
             "https://fyp-1-izlh.onrender.com/"
          )
         .AllowAnyHeader()  
         .AllowAnyMethod()
         .AllowCredentials();
}));

// 如果要用 UseDirectoryBrowser，记得注册服务
builder.Services.AddDirectoryBrowser();

// 1.5 Auth (JWT) + DB token check
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = false,
            ValidateAudience         = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateLifetime         = true,
            ClockSkew                = TimeSpan.Zero
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
                var token = authz.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                          ? authz[7..]
                          : null;

                var user = await db.Users.AsNoTracking()
                    .FirstOrDefaultAsync(u => u.UserId == userId);

                if (user is null ||
                    string.IsNullOrWhiteSpace(user.JwtToken) ||
                    !string.Equals(user.JwtToken, token, StringComparison.Ordinal))
                {
                    ctx.Fail("Token not active for user");
                }
            }
        };
    });
builder.Services.AddAuthorization();

// 1.6 App services (reports/providers/etc.)
builder.Services.AddSingleton<IReportRepository, ReportRepository>();
builder.Services.AddSingleton<PdfRenderer>();
builder.Services.AddScoped<ProviderRegistry>();
builder.Services.AddScoped<MockBankClient>(); // registry will resolve this

// 1.7 Crypto service (AES for provider keys)
builder.Services.AddSingleton<ICryptoService, AesCryptoService>();

// 1.8 AI Categorizer
var useZeroShot = string.Equals(
    Environment.GetEnvironmentVariable("CAT_MODE"),
    "zero-shot",
    StringComparison.OrdinalIgnoreCase);

if (useZeroShot)
{
    builder.Services.AddSingleton<RulesCategorizer>(); // fallback rules
    builder.Services.AddHttpClient<ZeroShotCategorizer>(c =>
    {
        var token = Environment.GetEnvironmentVariable("HF_TOKEN");
        if (!string.IsNullOrWhiteSpace(token))
        {
            c.DefaultRequestHeaders.Authorization =
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        }
    });
    builder.Services.AddTransient<ICategorizer>(sp => sp.GetRequiredService<ZeroShotCategorizer>());
}
else
{
    builder.Services.AddSingleton<ICategorizer, RulesCategorizer>();
}

/* ──────────────────────────────────────────────────────────────
 * 2) APP PIPELINE
 * ──────────────────────────────────────────────────────────────*/

var app = builder.Build();

// 2.1 Proxy headers (Render)
if (isRender)
{
    app.UseForwardedHeaders(new ForwardedHeadersOptions
    {
        ForwardedHeaders = ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedFor
    });
}

// 2.2 HTTPS redirect in prod
if (isRender || !isDev)
    app.UseHttpsRedirection();

// 2.3 Health
app.MapGet("/healthz", () => Results.Ok("ok"));

// 2.4 Global error envelope
app.Use(async (ctx, next) =>
{
    try
    {
        await next();
    }
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

// 2.5 DB migrate + (optional) seed
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();

    if (isDev || seedFlag)
        await AppDbSeeder.SeedAsync(app.Services);
}

// 2.6 Static + pipeline
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseDirectoryBrowser();

app.UseRouting();
app.UseCors("AllowWeb");
app.UseAuthentication();
app.UseAuthorization();

// 2.7 Swagger
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
    c.RoutePrefix = "swagger";
});

// 2.8 Controllers & SPA fallback
app.MapControllers();
app.MapFallbackToFile("index.html");

app.Run();
