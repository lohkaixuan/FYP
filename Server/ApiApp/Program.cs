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
using ApiApp.AI;
using ApiApp.Providers;
using ApiApp.Helpers;

Env.Load(); // Load .env first

var builder = WebApplication.CreateBuilder(args);

// ===== Logging: console logger for all environments =====
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

/* ──────────────────────────────────────────────────────────────
 * 0) ENV / HOST CONFIG
 * ──────────────────────────────────────────────────────────────*/

var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
            ?? throw new InvalidOperationException("JWT_KEY is not set");

var neonConn = Environment.GetEnvironmentVariable("NEON_CONN")
              ?? throw new InvalidOperationException("NEON_CONN is not set");

var aesKey = Environment.GetEnvironmentVariable("AES_KEY")
            ?? throw new InvalidOperationException("AES_KEY is not set");

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

// Local dev binding
if (isDev && string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("ASPNETCORE_URLS")))
{
    var port = Environment.GetEnvironmentVariable("PORT") ?? "5000";
    var bind = Environment.GetEnvironmentVariable("BIND") ?? "localhost";
    builder.WebHost.UseUrls($"http://{bind}:{port}");
}

/* ──────────────────────────────────────────────────────────────
 * 1) SERVICES
 * ──────────────────────────────────────────────────────────────*/

builder.Services.AddSingleton<NpgsqlDataSource>(_ =>
{
    var dsb = new NpgsqlDataSourceBuilder(neonConn);
    return dsb.Build();
});

builder.Services.AddDbContext<AppDbContext>((sp, opt) =>
    opt.UseNpgsql(sp.GetRequiredService<NpgsqlDataSource>()));

builder.Services.AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "API", Version = "v1" });

    c.AddSecurityDefinition("Bearer", new()
    {
        Description = "JWT Authorization using Bearer scheme",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
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

builder.Services.AddCors(o => o.AddPolicy("AllowWeb", p =>
{
    if (isDev)
        p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    else
        p.WithOrigins(
             "https://your-frontend.vercel.app",
             "https://yourdomain.com",
             "https://fyp-1-izlh.onrender.com"
         )
         .AllowAnyHeader()
         .AllowAnyMethod()
         .AllowCredentials();
}));

builder.Services.AddDirectoryBrowser();

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

builder.Services.AddSingleton<IReportRepository, ReportRepository>();
builder.Services.AddSingleton<PdfRenderer>();
builder.Services.AddScoped<ProviderRegistry>();
builder.Services.AddScoped<MockBankClient>();
builder.Services.AddSingleton<ICryptoService, AesCryptoService>();

var useZeroShot = string.Equals(
    Environment.GetEnvironmentVariable("CAT_MODE"),
    "zero-shot",
    StringComparison.OrdinalIgnoreCase);

if (useZeroShot)
{
    builder.Services.AddSingleton<RulesCategorizer>();
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

// Render proxy headers
if (isRender)
{
    app.UseForwardedHeaders(new ForwardedHeadersOptions
    {
        ForwardedHeaders = ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedFor
    });
}

// HTTPS redirect (Render or Prod)
if (isRender || !isDev)
    app.UseHttpsRedirection();

app.MapGet("/healthz", () => Results.Ok("ok"));

/* ──────────────────────────────────────────────────────────────
 * GLOBAL ERROR + STATUS LOGGING MIDDLEWARE
 * ──────────────────────────────────────────────────────────────*/
app.Use(async (ctx, next) =>
{
    var logger = ctx.RequestServices.GetRequiredService<ILogger<Program>>();

    try
    {
        await next();

        // 如果没有抛异常但是返回了 5xx，也记一笔 log，方便查 swagger 500
        if (ctx.Response.StatusCode >= 500)
        {
            logger.LogError(
                "Request finished with status {StatusCode} on path {Path}",
                ctx.Response.StatusCode,
                ctx.Request.Path);
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Unhandled server error on path {Path}", ctx.Request.Path);

        ctx.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await ctx.Response.WriteAsJsonAsync(new
        {
            ok = false,
            path = ctx.Request.Path.Value,
            message = ex.Message
        });
    }
});

/* ──────────────────────────────────────────────────────────────
 * CONTINUE PIPELINE
 * ──────────────────────────────────────────────────────────────*/

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();

    if (isDev || seedFlag)
        await AppDbSeeder.SeedAsync(app.Services);
}

app.UseDefaultFiles();
app.UseStaticFiles();
app.UseDirectoryBrowser();

app.UseRouting();
app.UseCors("AllowWeb");
app.UseAuthentication();
app.UseAuthorization();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
    c.RoutePrefix = "swagger";
});

app.MapControllers();
app.MapFallbackToFile("index.html");

app.Run();
