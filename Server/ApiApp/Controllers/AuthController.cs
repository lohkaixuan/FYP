// File: ApiApp/Controllers/AuthController.cs
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Helpers; // JwtToken helper

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _cfg;
    private readonly IWebHostEnvironment _env;

    public AuthController(AppDbContext db, IConfiguration cfg, IWebHostEnvironment env)
    {
        _db = db; _cfg = cfg; _env = env;
    }

    // ====== constants (your seeded role ids) ======
    private static readonly Guid ROLE_USER = Guid.Parse("11111111-1111-1111-1111-111111111001");
    private static readonly Guid ROLE_MERCHANT = Guid.Parse("11111111-1111-1111-1111-111111111002");
    private static readonly Guid ROLE_ADMIN = Guid.Parse("11111111-1111-1111-1111-111111111003");
    private static readonly Guid ROLE_THIRDPARTY = Guid.Parse("11111111-1111-1111-1111-111111111004");

    private static readonly TimeSpan TOKEN_TTL = TimeSpan.FromHours(2);

    // ======================================================
    // DTOs
    // ======================================================
    public record RegisterUserDto(
        string user_name,
        string user_password,
        string user_ic_number,
        string? user_email,
        string? user_phone_number,
        int? user_age
    );

    public class RegisterMerchantForm
    {
        public Guid owner_user_id { get; set; }
        public string merchant_name { get; set; } = string.Empty; // shop name
        public string? merchant_phone_number { get; set; }
        public IFormFile? merchant_doc { get; set; }                  // upload (PDF/JPG/PNG)
    }

    public record LoginDto(
        string? user_email,
        string? user_phone_number,
        string? user_password,
        string? user_passcode
    );

    public record RegisterPasscodeDto(string passcode);
    public record ChangePasscodeDto(string current_passcode, string new_passcode);

    // ======================================================
    // REGISTER: USER (auto wallet)
    // ======================================================
    [HttpPost("register/user")]
    public async Task<IResult> RegisterUser([FromBody] RegisterUserDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.user_name) ||
            string.IsNullOrWhiteSpace(dto.user_password) ||
            string.IsNullOrWhiteSpace(dto.user_ic_number))
            return Results.BadRequest("name, password, ic required");

        var dup = await _db.Users.AnyAsync(u =>
            u.Email == dto.user_email ||
            u.PhoneNumber == dto.user_phone_number ||
            u.ICNumber == dto.user_ic_number);
        if (dup) return Results.BadRequest("duplicate email/phone/ic");

        var user = new User
        {
            UserId = Guid.NewGuid(),
            UserName = dto.user_name,
            UserPassword = dto.user_password, // DEV only plain
            ICNumber = dto.user_ic_number,
            Email = string.IsNullOrWhiteSpace(dto.user_email) ? null : dto.user_email,
            PhoneNumber = string.IsNullOrWhiteSpace(dto.user_phone_number) ? null : dto.user_phone_number,
            UserAge = dto.user_age,
            RoleId = ROLE_USER,
            Balance = 0m,
            LastUpdate = DateTime.UtcNow
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        await EnsureWalletAsync(userId: user.UserId);

        return Results.Created($"/api/users/{user.UserId}", new { user_id = user.UserId, user_name = user.UserName });
    }

    // ======================================================
    // REGISTER: MERCHANT APPLY (user must exist; role stays user)
    // ======================================================
    [HttpPost("register/merchant-apply")]
    [RequestSizeLimit(25_000_000)]
    public async Task<IResult> RegisterMerchantApply([FromForm] RegisterMerchantForm form)
    {
        var owner = await _db.Users.FirstOrDefaultAsync(u => u.UserId == form.owner_user_id);
        if (owner is null) return Results.BadRequest("owner user not found");

        string? docUrl = null;
        byte[]? docBytes = null;
        string? docContentType = null;
        long? docSize = null;

        if (form.merchant_doc is not null && form.merchant_doc.Length > 0)
        {
            // 1) 存成 bytes（进数据库）
            using (var ms = new MemoryStream())
            {
                await form.merchant_doc.CopyToAsync(ms);
                docBytes = ms.ToArray();
            }

            docContentType = form.merchant_doc.ContentType;
            docSize = form.merchant_doc.Length;

            // 2) 也存一份到 wwwroot/uploads，留一个 URL
            var (path, size) = await FileStorage.SaveFormFileAsync(_env, form.merchant_doc);
            docUrl = path;   // e.g. "/uploads/xxx.pdf"
            docSize = size;  // 长度再覆盖一下也可以
        }

        var merchant = new Merchant
        {
            MerchantId = Guid.NewGuid(),
            MerchantName = form.merchant_name,
            MerchantPhoneNumber = form.merchant_phone_number,
            MerchantDocUrl = docUrl,
            MerchantDocBytes = docBytes,
            MerchantDocContentType = docContentType,
            MerchantDocSize = docSize,
            OwnerUserId = owner.UserId
        };
        ModelTouch.Touch(merchant);
        _db.Merchants.Add(merchant);
        await _db.SaveChangesAsync();

        Console.WriteLine($"[MerchantApply] user={owner.UserName} merchant='{merchant.MerchantName}' doc={docUrl ?? "-"}");

        return Results.Accepted($"/api/merchant/{merchant.MerchantId}", new
        {
            message = "Application received. Await approval.",
            merchant_id = merchant.MerchantId
        });
    }

    // ======================================================
    // ADMIN: APPROVE MERCHANT (flip role + create merchant wallet)
    // ======================================================
    [Authorize(Roles = "admin")]
    [HttpPost("admin/approve-merchant/{merchantId:guid}")]
    public async Task<IResult> AdminApproveMerchant(Guid merchantId)
    {
        // 1. Find the Merchant
        var merchant = await _db.Merchants.FirstOrDefaultAsync(m => m.MerchantId == merchantId);
        if (merchant is null) return Results.NotFound("Merchant not found");
        if (merchant.OwnerUserId is null) return Results.BadRequest("Merchant has no owner");

        // 2. Find the Owner
        var owner = await _db.Users.FirstOrDefaultAsync(u => u.UserId == merchant.OwnerUserId);
        if (owner is null) return Results.BadRequest("Owner user not found");

        // 3. ✅ DYNAMIC ROLE LOOKUP (Fixes the hardcoded ID issue)
        var merchantRole = await _db.Roles.FirstOrDefaultAsync(r => r.RoleName.ToLower() == "merchant");
        
        if (merchantRole == null) 
        {
            Console.WriteLine("[Error] 'merchant' role not found in Roles table.");
            return Results.Problem("System configuration error: 'merchant' role missing.");
        }

        // 4. Update the User's Role
        owner.RoleId = merchantRole.RoleId; 
        owner.LastUpdate = DateTime.UtcNow;

        // 5. ✅ ENSURE WALLET EXISTS
        var exists = await _db.Wallets.AnyAsync(w => w.merchant_id == merchant.MerchantId);
        if (!exists)
        {
            _db.Wallets.Add(new Wallet
            {
                wallet_id = Guid.NewGuid(),
                merchant_id = merchant.MerchantId,
                wallet_balance = 0m,
                last_update = DateTime.UtcNow
            });
            Console.WriteLine($"[Approve] Created wallet for {merchant.MerchantName}");
        }

        await _db.SaveChangesAsync();
        
        return Results.Ok(new { message = "Approved. Owner updated to merchant and wallet created." });
    }

    [Authorize(Roles = "admin")]
    [HttpPost("admin/reject-merchant/{merchantId:guid}")]
    public async Task<IResult> AdminRejectMerchant(Guid merchantId)
    {
        var merchant = await _db.Merchants.FirstOrDefaultAsync(m => m.MerchantId == merchantId);
        if (merchant is null) return Results.NotFound("Merchant not found.");

        // ✅ SOFT DELETE: Mark as deleted but keep the record
        merchant.IsDeleted = true;

        // Optional: Log it
        Console.WriteLine($"[MerchantReject] Soft deleted application for '{merchant.MerchantName}'");

        await _db.SaveChangesAsync();

        return Results.Ok(new { message = "Merchant application rejected (soft deleted)." });
    }

    // ======================================================
    // REGISTER: THIRDPARTY PROVIDER (direct register as thirdparty)
    // ======================================================
    [HttpPost("register/thirdparty")]
    public async Task<IResult> RegisterThirdParty([FromBody] RegisterUserDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.user_name) || string.IsNullOrWhiteSpace(dto.user_password))
            return Results.BadRequest("name and password required");

        var dup = await _db.Users.AnyAsync(u =>
            u.Email == dto.user_email || u.PhoneNumber == dto.user_phone_number);
        if (dup) return Results.BadRequest("duplicate email or phone");

        // === CHANGE STARTS HERE ===
        // Generate a new ID first so we can use it
        var newUserId = Guid.NewGuid();

        // Create a UNIQUE dummy IC number. 
        // taking first 8 chars of the ID ensures it is unique but short enough.
        // Result example: "TP-a1b2c3d4"
        string uniqueDummyIc = $"TP-{newUserId.ToString("N").Substring(0, 8)}";

        var user = new User
        {
            UserId = newUserId, // Use the ID we generated above
            UserName = dto.user_name,
            UserPassword = dto.user_password,

            // UPDATED LINE: Use the unique string, NOT the static "thridParty"
            ICNumber = uniqueDummyIc,

            Email = dto.user_email,
            PhoneNumber = dto.user_phone_number,
            UserAge = dto.user_age,
            RoleId = ROLE_THIRDPARTY,
            Balance = 0m,
            LastUpdate = DateTime.UtcNow
        };
        // === CHANGE ENDS HERE ===

        _db.Users.Add(user);

        var provider = new Provider
        {
            ProviderId = Guid.NewGuid(),
            Name = dto.user_name,
            OwnerUserId = user.UserId,
            Enabled = true,
            LastUpdate = DateTime.UtcNow
        };
        _db.Providers.Add(provider);

        try
        {
            await _db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            // Log the inner exception to see database errors
            Console.WriteLine(ex.InnerException?.Message ?? ex.Message);
            return Results.Problem("Database Error: " + (ex.InnerException?.Message ?? ex.Message));
        }

        Console.WriteLine($"[ThirdPartyRegister] Created User '{user.UserName}' with IC '{user.ICNumber}'");

        return Results.Created($"/api/users/{user.UserId}", new
        {
            user_id = user.UserId,
            provider_id = provider.ProviderId,
            role = "thirdparty"
        });
    }

    // ======================================================
    // LOGIN (email+password OR phone+password OR passcode)
    // returns: { token, role, user }
    // ======================================================
    [HttpPost("login")]
    public async Task<IResult> Login([FromBody] LoginDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.user_email) && string.IsNullOrWhiteSpace(dto.user_phone_number))
            return Results.BadRequest(new { message = "Email or phone required" });

        var user = await _db.Users.Include(x => x.Role).FirstOrDefaultAsync(u =>
            (!string.IsNullOrWhiteSpace(dto.user_email) && u.Email == dto.user_email) ||
            (!string.IsNullOrWhiteSpace(dto.user_phone_number) && u.PhoneNumber == dto.user_phone_number));
        if (user is null) return Results.NotFound(new { message = "User not found" });

        var ok = false;
        if (!string.IsNullOrWhiteSpace(dto.user_password))
            ok = string.Equals(dto.user_password, user.UserPassword ?? "", StringComparison.Ordinal);
        else if (!string.IsNullOrWhiteSpace(dto.user_passcode))
            ok = string.Equals(dto.user_passcode, user.Passcode ?? "", StringComparison.Ordinal);

        if (!ok) return Results.Unauthorized();

        // 🔹 1. Check Specific Roles (Admin, ThirdParty, Merchant)
        var isAdmin = string.Equals(user.Role?.RoleName, "admin", StringComparison.OrdinalIgnoreCase);
        // Ensure you check against your ROLE_THIRDPARTY constant defined in the class
        var isThirdParty = user.RoleId == ROLE_THIRDPARTY;
        var hasMerchant = await _db.Merchants.AnyAsync(m => m.OwnerUserId == user.UserId);

        // 🔹 2. Determine the Role Label correctly
        string roleLabel;
        if (isAdmin)
        {
            roleLabel = "admin";
        }
        else if (isThirdParty)
        {
            // ✅ This was missing before!
            roleLabel = "thirdparty";
        }
        else if (hasMerchant)
        {
            roleLabel = "merchant,user";
        }
        else
        {
            roleLabel = "user";
        }

        // 🔹 3. Construct Extra Claims (Add is_thirdparty)
        var extraClaims = new Dictionary<string, string>
        {
            ["roles_csv"] = roleLabel,
            ["is_merchant"] = hasMerchant ? "true" : "false",
            ["is_admin"] = isAdmin ? "true" : "false",
            ["is_thirdparty"] = isThirdParty ? "true" : "false"
        };

        var key = Environment.GetEnvironmentVariable("JWT_KEY") ?? "dev_super_secret_change_me";

        string token;
        try
        {
            token = JwtToken.Issue(
                user.UserId,                     // subject (Guid)
                user.UserName ?? "User",         // display name
                user.Role?.RoleName ?? "user",   // main role
                key,
                TOKEN_TTL,
                extraClaims                      // ✅ Includes new role logic
            );
        }
        catch (Exception ex)
        {
            Console.WriteLine($"JWT error: {ex.Message}");
            return Results.Problem("Failed to generate token");
        }

        user.JwtToken = token;
        user.LastLogin = DateTime.UtcNow;
        user.LastUpdate = DateTime.UtcNow;

        try
        {
            await _db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"DB save error: {ex.Message}");
            return Results.Problem("Failed to save login state");
        }

        // 🔹 Ensure Personal Wallet
        var userWallet = await EnsureWalletAsync(userId: user.UserId);

        // 🔹 Ensure Merchant Wallet (if applicable)
        Guid? merchantWalletId = null;
        if (hasMerchant)
        {
            var merchant = await _db.Merchants.AsNoTracking()
                .FirstOrDefaultAsync(m => m.OwnerUserId == user.UserId);
            if (merchant is not null)
            {
                var mw = await EnsureWalletAsync(merchantId: merchant.MerchantId);
                merchantWalletId = mw.wallet_id;
            }
        }

        return Results.Ok(new
        {
            token,
            role = roleLabel,   // ✅ Will now return "thirdparty"
            user = new
            {
                user_id = user.UserId,
                user_name = user.UserName,
                user_email = user.Email,
                user_phone_number = user.PhoneNumber,
                user_balance = user.Balance,
                last_login = user.LastLogin,
                wallet_id = userWallet.wallet_id,
                user_wallet_id = userWallet.wallet_id,
                merchant_wallet_id = merchantWalletId
            }
        });
    }

    // ======================================================
    // PASSCODE MANAGEMENT
    // ======================================================
    [Authorize]
    [HttpPost("passcode/register")]
    public async Task<IResult> RegisterPasscode([FromBody] RegisterPasscodeDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.passcode))
            return Results.BadRequest(new { message = "Passcode is required" });
        if (!IsValidPasscode(dto.passcode))
            return Results.BadRequest(new { message = "Passcode must be exactly 6 digits" });

        var user = await GetCurrentUserAsync();
        if (user is null) return Results.Unauthorized();
        if (!string.IsNullOrEmpty(user.Passcode))
            return Results.Conflict(new { message = "Passcode already registered" });

        user.Passcode = dto.passcode;
        user.LastUpdate = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Results.Ok(new { message = "Passcode registered" });
    }

    [Authorize]
    [HttpPut("passcode/change")]
    public async Task<IResult> ChangePasscode([FromBody] ChangePasscodeDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.current_passcode) || string.IsNullOrWhiteSpace(dto.new_passcode))
            return Results.BadRequest(new { message = "Current and new passcodes are required" });
        if (!IsValidPasscode(dto.new_passcode))
            return Results.BadRequest(new { message = "New passcode must be exactly 6 digits" });

        var user = await GetCurrentUserAsync();
        if (user is null) return Results.Unauthorized();
        if (string.IsNullOrEmpty(user.Passcode))
            return Results.BadRequest(new { message = "No passcode registered" });
        if (!string.Equals(dto.current_passcode, user.Passcode, StringComparison.Ordinal))
            return Results.Unauthorized();

        user.Passcode = dto.new_passcode;
        user.LastUpdate = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Results.Ok(new { message = "Passcode updated" });
    }

    [Authorize]
    [HttpGet("passcode")]
    public async Task<IResult> GetPasscode([FromQuery] Guid? user_id)
    {
        var user = await GetCurrentUserAsync();
        if (user is null) return Results.Unauthorized();

        if (user_id.HasValue && user_id.Value != user.UserId)
            return Results.Forbid();

        return Results.Ok(new { passcode = user.Passcode });
    }

    // ======================================================
    // LOGOUT (invalidate stored token)
    // ======================================================
    [Authorize]
    [HttpPost("logout")]
    public async Task<IResult> Logout()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (sub is null || !Guid.TryParse(sub, out var uid)) return Results.Unauthorized();

        var u = await _db.Users.FirstOrDefaultAsync(x => x.UserId == uid);
        if (u is null) return Results.Unauthorized();

        u.JwtToken = null;
        u.LastUpdate = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Results.Ok(new { message = "logged out" });
    }

    // ======================================================
    // helpers
    // ======================================================
    private async Task<Wallet> EnsureWalletAsync(Guid? userId = null, Guid? merchantId = null)
    {
        if ((userId is null && merchantId is null) || (userId is not null && merchantId is not null))
            throw new ArgumentException("Provide exactly one of userId or merchantId");

        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.user_id == userId && w.merchant_id == merchantId);
        if (wallet is not null) return wallet;

        wallet = new Wallet
        {
            wallet_id = Guid.NewGuid(),
            user_id = userId,
            merchant_id = merchantId,
            wallet_balance = 0m,
            last_update = DateTime.UtcNow
        };
        _db.Wallets.Add(wallet);
        await _db.SaveChangesAsync();
        return wallet;
    }

    private async Task<string> SaveFileAsync(IFormFile file)
    {
        var uploads = Path.Combine(_env.ContentRootPath, "wwwroot", "uploads");
        Directory.CreateDirectory(uploads);
        var fileName = $"{Guid.NewGuid()}_{Path.GetFileName(file.FileName)}";
        var path = Path.Combine(uploads, fileName);
        using (var fs = System.IO.File.Create(path))
        {
            await file.CopyToAsync(fs);
        }
        return $"/uploads/{fileName}";
    }

    private async Task<User?> GetCurrentUserAsync()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (sub is null || !Guid.TryParse(sub, out var uid)) return null;
        return await _db.Users.FirstOrDefaultAsync(u => u.UserId == uid);
    }

    private static bool IsValidPasscode(string passcode)
    {
        if (passcode.Length != 6) return false;
        foreach (var ch in passcode)
        {
            if (!char.IsDigit(ch)) return false;
        }
        return true;
    }
}
