// ==================================================
// Program Name   : Program.cs
// Purpose        : Configures and starts the ASP.NET Core API application
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using Amazon;
using Amazon.S3;
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

Env.Load();
var builder = WebApplication.CreateBuilder(args);
var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
            ?? throw new InvalidOperationException("JWT_KEY is not set");
var neonConn = Environment.GetEnvironmentVariable("NEON_CONN");
var rdsConn = Environment.GetEnvironmentVariable("RDS_CONN")
           ?? Environment.GetEnvironmentVariable("AWS_RDS_CONN");
var dbConn = !string.IsNullOrWhiteSpace(rdsConn)
    ? rdsConn!
    : neonConn ?? throw new InvalidOperationException("NEON_CONN or RDS_CONN is not set");
var aesKey = Environment.GetEnvironmentVariable("AES_KEY")
            ?? throw new InvalidOperationException("AES_KEY is not set");
builder.Configuration["Crypto:AesKey"] = aesKey;

var isRender =
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER")) ||
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER_EXTERNAL_URL")) ||
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RENDER_INTERNAL_IP"));
var isEc2 =
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("EC2")) ||
    !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("AWS_EXECUTION_ENV"));

var s3Bucket = Environment.GetEnvironmentVariable("S3_BUCKET");
var s3Region = Environment.GetEnvironmentVariable("S3_REGION") ?? "ap-southeast-1";
var s3ReportPrefix = Environment.GetEnvironmentVariable("S3_REPORT_PREFIX") ?? "reports/";
var enableS3 = isEc2 && !string.IsNullOrWhiteSpace(s3Bucket);
builder.Configuration["S3:Bucket"] = s3Bucket ?? "";
builder.Configuration["S3:Region"] = s3Region;
builder.Configuration["S3:ReportPrefix"] = s3ReportPrefix;

var isDev = builder.Environment.IsDevelopment();
var seedFlag = (Environment.GetEnvironmentVariable("SEED") ?? "")
    .Equals("1", StringComparison.OrdinalIgnoreCase)
 || (Environment.GetEnvironmentVariable("SEED") ?? "")
    .Equals("true", StringComparison.OrdinalIgnoreCase);
if (isDev && string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("ASPNETCORE_URLS")))
{
    var port = Environment.GetEnvironmentVariable("PORT") ?? "5000";
    var bind = Environment.GetEnvironmentVariable("BIND") ?? "localhost";
    builder.WebHost.UseUrls($"http://{bind}:{port}");
}
builder.Services.AddSingleton<NpgsqlDataSource>(_ =>
{
    var dsb = new NpgsqlDataSourceBuilder(dbConn);
    return dsb.Build();
});
if (enableS3)
{
    builder.Services.AddSingleton<IAmazonS3>(_ =>
        new AmazonS3Client(RegionEndpoint.GetBySystemName(s3Region)));
}
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
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
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
builder.Services.AddHttpClient();
builder.Services.AddSingleton<IProviderClient, MockBankClient>();
builder.Services.AddSingleton<ProviderRegistry>();
builder.Services.AddSingleton<IPaymentGatewayClient, StripeGatewayClient>();
builder.Services.AddSingleton<PaymentGatewayRegistry>();
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
builder.Services.AddSingleton<IReportRepository>(sp =>
    new ReportRepository(
        sp.GetService<IAmazonS3>(),
        sp.GetRequiredService<IConfiguration>()));
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

var app = builder.Build();
if (isRender)
{
    app.UseForwardedHeaders(new ForwardedHeadersOptions
    {
        ForwardedHeaders = ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedFor
    });
}
if (isRender || !isDev)
    app.UseHttpsRedirection();
app.MapGet("/healthz", () => Results.Ok("ok"));
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
