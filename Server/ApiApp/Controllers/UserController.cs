// =============================
// Controllers/UsersController.cs
// =============================
using System.Security.Claims;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;

namespace ApiApp.Controllers;


[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly AppDbContext _db;
    private const string TemporaryPassword = "12345678";
    public UsersController(AppDbContext db) { _db = db; }

    public class UpdateUserDto
    {
        public string? user_name { get; set; }
        public string? user_email { get; set; }
        public string? user_phone_number { get; set; }
        public int? user_age { get; set; }
        public string? user_ic_number { get; set; }
        public Guid? role_id { get; set; }
    }


    [HttpGet("me")]
    public async Task<IResult> Me()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (sub is null || !Guid.TryParse(sub, out var uid)) return Results.Unauthorized();
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == uid);
        if (user is null) return Results.NotFound();

        // Ensure personal wallet
        var userWallet = await _db.Wallets.FirstOrDefaultAsync(w => w.user_id == uid && w.merchant_id == null);
        if (userWallet is null)
        {
            userWallet = new Wallet
            {
                wallet_id = Guid.NewGuid(),
                user_id = uid,
                merchant_id = null,
                wallet_balance = 0m,
                last_update = DateTime.UtcNow
            };
            _db.Wallets.Add(userWallet);
            await _db.SaveChangesAsync();
        }

        // If this user owns a merchant, ensure merchant wallet
        Guid? merchantWalletId = null;
        Wallet? merchantWallet = null;
        var merchant = await _db.Merchants.AsNoTracking().FirstOrDefaultAsync(m => m.OwnerUserId == uid);
        if (merchant is not null)
        {
            merchantWallet = await _db.Wallets.FirstOrDefaultAsync(w => w.merchant_id == merchant.MerchantId);
            if (merchantWallet is null)
            {
                merchantWallet = new Wallet
                {
                    wallet_id = Guid.NewGuid(),
                    user_id = null,
                    merchant_id = merchant.MerchantId,
                    wallet_balance = 0m,
                    last_update = DateTime.UtcNow
                };
                _db.Wallets.Add(merchantWallet);
                await _db.SaveChangesAsync();
            }
            merchantWalletId = merchantWallet.wallet_id;
        }

        // Return a safe, client-friendly projection including wallet_id
        return Results.Ok(new
        {
            user_id = user.UserId,
            user_name = user.UserName,
            user_email = user.Email,
            user_phone_number = user.PhoneNumber,
            user_balance = user.Balance,
            last_login = user.LastLogin,
            // Back-compat: wallet_id = personal wallet
            wallet_id = userWallet.wallet_id,
            user_wallet_id = userWallet.wallet_id,
            user_wallet_balance = userWallet.wallet_balance,
            merchant_wallet_id = merchantWalletId,
            merchant_wallet_balance = merchantWallet?.wallet_balance,
            merchant_name = merchant?.MerchantName
        });
    }


    [HttpGet]
    public async Task<IResult> List() => Results.Ok(await _db.Users.AsNoTracking().ToListAsync());


    [HttpGet("{id:guid}")]
    public async Task<IResult> Get(Guid id)
    {
        var u = await _db.Users.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == id);
        return u is null ? Results.NotFound() : Results.Ok(u);
    }

    [HttpPut("{id:guid}")]
    public async Task<IResult> Update(Guid id, [FromBody] UpdateUserDto dto)
    {
        if (dto is null) return Results.BadRequest(new { message = "Body is required" });

    var actorId = GetCurrentUserId();
    if (actorId is null) return Results.Unauthorized();

    // 1. Get the User
    var target = await _db.Users.FirstOrDefaultAsync(u => u.UserId == id);
    if (target is null) return Results.NotFound();

    var isAdmin = HasRole("admin");
    var isMerchant = HasRole("merchant");
    var editingSelf = actorId.Value == id;

    if (!isAdmin && !isMerchant && !editingSelf)
        return Results.Forbid();

    var changed = false;

    // ---------------------------------------------------------
    // 2. Update Name (Owner Name Only)
    // ---------------------------------------------------------
    if (!string.IsNullOrWhiteSpace(dto.user_name))
    {
        var trimmed = dto.user_name.Trim();
        if (!string.Equals(trimmed, target.UserName, StringComparison.Ordinal))
        {
            target.UserName = trimmed;
            changed = true;

            // --- DELETED: Sync Logic ---
            // The code that updated Merchant.MerchantName and Provider.Name
            // has been removed to allow independent editing.
        }
    }

    // ---------------------------------------------------------
    // 3. Update Email
    // ---------------------------------------------------------
    if (dto.user_email is not null)
    {
        var normalizedEmail = NormalizeOptional(dto.user_email);
        if (!string.Equals(normalizedEmail, target.Email, StringComparison.OrdinalIgnoreCase))
        {
            if (!string.IsNullOrWhiteSpace(normalizedEmail))
            {
                var emailUsed = await _db.Users
                    .AnyAsync(u => u.Email == normalizedEmail && u.UserId != target.UserId);
                if (emailUsed) return Results.Conflict(new { message = "Email already in use" });
            }
            target.Email = normalizedEmail;
            changed = true;
        }
    }

    // ---------------------------------------------------------
    // 4. Update Phone (Owner Phone Only)
    // ---------------------------------------------------------
    if (dto.user_phone_number is not null)
    {
        var normalizedPhone = NormalizeOptional(dto.user_phone_number);
        
        if (!string.Equals(normalizedPhone, target.PhoneNumber, StringComparison.Ordinal))
        {
            if (!string.IsNullOrWhiteSpace(normalizedPhone))
            {
                var phoneUsed = await _db.Users
                    .AnyAsync(u => u.PhoneNumber == normalizedPhone && u.UserId != target.UserId);
                if (phoneUsed) return Results.Conflict(new { message = "Phone number already in use" });
            }

            target.PhoneNumber = normalizedPhone;
            changed = true;

            // --- DELETED: Sync Logic ---
            // The code that updated Merchant.MerchantPhoneNumber has been
            // removed to allow independent editing.
        }
    }

    // ---------------------------------------------------------
    // 5. Update Age
    // ---------------------------------------------------------
    if (dto.user_age.HasValue)
    {
        if (dto.user_age.Value < 0) return Results.BadRequest(new { message = "Age must be positive" });
        if (target.UserAge != dto.user_age.Value)
        {
            target.UserAge = dto.user_age;
            changed = true;
        }
    }

    // ---------------------------------------------------------
    // 6. Update IC Number
    // ---------------------------------------------------------
    if (dto.user_ic_number is not null)
    {
        var trimmed = dto.user_ic_number.Trim();
        if (trimmed.Length == 0) return Results.BadRequest(new { message = "IC number cannot be empty" });

        if (!string.Equals(trimmed, target.ICNumber, StringComparison.OrdinalIgnoreCase))
        {
            var icUsed = await _db.Users
                .AnyAsync(u => u.ICNumber == trimmed && u.UserId != target.UserId);
            if (icUsed) return Results.Conflict(new { message = "IC number already in use" });
            target.ICNumber = trimmed;
            changed = true;
        }
    }

    // ---------------------------------------------------------
    // 7. Update Role (Admin only)
    // ---------------------------------------------------------
    if (dto.role_id.HasValue && dto.role_id.Value != target.RoleId)
    {
        if (!isAdmin) return Results.Forbid();
        var roleExists = await _db.Roles.AnyAsync(r => r.RoleId == dto.role_id.Value);
        if (!roleExists) return Results.BadRequest(new { message = "Role not found" });
        target.RoleId = dto.role_id.Value;
        changed = true;
    }

    if (!changed) return Results.BadRequest(new { message = "No changes detected" });

    target.LastUpdate = DateTime.UtcNow;
    
    // Save changes for Users only (unless manual Merchant updates happen elsewhere)
    await _db.SaveChangesAsync();

    return Results.Ok(new
    {
        message = "User updated",
        user = new
        {
            user_id = target.UserId,
            user_name = target.UserName,
            user_email = target.Email,
            user_phone_number = target.PhoneNumber,
            user_age = target.UserAge,
            user_ic_number = target.ICNumber,
            role_id = target.RoleId
        }
    });
    }

    // DTO 可以放在同一个文件底部，或者单独建一个文件
    public sealed class DirectoryAccountDto
    {
        public Guid Id { get; set; }              // 主 ID（userId / merchantId / providerId）
        public string Role { get; set; } = "";    // "user" / "merchant" / "provider"

        public string? Name { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }

        public DateTimeOffset? LastLogin { get; set; }
        public bool IsDeleted { get; set; }

        public Guid? OwnerUserId { get; set; }    // user 自己 = userId；merchant/provider = owner_user_id
        public Guid? MerchantId { get; set; }     // 只有商家有
        public Guid? ProviderId { get; set; }     // 只有第三方有
    }

    [HttpGet("directory")]
    public async Task<IResult> ListDirectory([FromQuery] string? role = null)
    {
        if (!CanViewDirectory()) return Results.Forbid();

        var roleFilter = role?.ToLowerInvariant();
        var list = new List<DirectoryAccountDto>();

        // ===================== USERS =====================
        if (roleFilter is null || roleFilter == "all" || roleFilter == "user")
        {
            var users = await _db.Users.AsNoTracking()
                .Include(u => u.Role)
                .Where(u => u.Role != null && u.Role.RoleName == "user")
                .OrderBy(u => u.UserName)
                .Select(u => new DirectoryAccountDto
                {
                    Id = u.UserId,
                    Role = "user",
                    Name = u.UserName,
                    Phone = u.PhoneNumber,
                    Email = u.Email,
                    LastLogin = u.LastLogin,
                    IsDeleted = u.IsDeleted,
                    OwnerUserId = u.UserId,   // 自己就是 owner
                    MerchantId = null,
                    ProviderId = null,
                })
                .ToListAsync();

            list.AddRange(users);
        }

        // ===================== MERCHANTS =====================
        if (roleFilter is null || roleFilter == "all" || roleFilter == "merchant")
        {
            var merchants = await _db.Merchants.AsNoTracking()
                .Include(m => m.OwnerUser)
                .OrderBy(m => m.MerchantName)
                .Select(m => new DirectoryAccountDto
                {
                    Id = m.MerchantId,
                    Role = "merchant",
                    Name = m.MerchantName,
                    Phone = m.MerchantPhoneNumber,
                    Email = m.OwnerUser != null ? m.OwnerUser.Email : null,

                    // 登录时间 & 删除状态都从 users 表拿
                    LastLogin = m.OwnerUser != null ? m.OwnerUser.LastLogin : null,
                    IsDeleted = m.OwnerUser != null && m.OwnerUser.IsDeleted,

                    OwnerUserId = m.OwnerUserId,
                    MerchantId = m.MerchantId,
                    ProviderId = null,
                })
                .ToListAsync();

            list.AddRange(merchants);
        }

        // ===================== PROVIDERS =====================
        if (roleFilter is null || roleFilter == "all" || roleFilter == "provider" || roleFilter == "thirdparty")
        {
            var providersQuery =
                from p in _db.Providers.AsNoTracking()
                join u in _db.Users.AsNoTracking()
                    on p.OwnerUserId equals u.UserId into userGroup
                from subUser in userGroup.DefaultIfEmpty()
                orderby p.Name
                select new DirectoryAccountDto
                {
                    Id = p.ProviderId,
                    Role = "provider",    // 或者 "thirdparty" 看你前端习惯
                    Name = p.Name,
                    Phone = subUser != null ? subUser.PhoneNumber : null,
                    Email = subUser != null ? subUser.Email : null,

                    LastLogin = subUser != null ? subUser.LastLogin : null,
                    IsDeleted = subUser != null && subUser.IsDeleted,

                    OwnerUserId = p.OwnerUserId,
                    MerchantId = null,
                    ProviderId = p.ProviderId,
                };

            var providers = await providersQuery.ToListAsync();
            list.AddRange(providers);
        }

        // 你也可以在这里按 Name 排序一下：
        list = list.OrderBy(x => x.Role).ThenBy(x => x.Name).ToList();

        return Results.Ok(list);
    }



    [HttpPost("{id:guid}/reset-password")]
    public async Task<IResult> ResetPassword(Guid id)
    {
        var actorId = GetCurrentUserId();
        if (actorId is null) return Results.Unauthorized();

        var isAdmin = HasRole("admin");
        if (!isAdmin && actorId.Value != id) return Results.Forbid();

        var target = await _db.Users.FirstOrDefaultAsync(u => u.UserId == id);
        if (target is null) return Results.NotFound();

        target.UserPassword = TemporaryPassword;
        target.LastUpdate = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Results.Ok(new { message = $"Password reset to temporary value {TemporaryPassword}" });
    }


    private Guid? GetCurrentUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        return Guid.TryParse(sub, out var uid) ? uid : null;
    }

    private bool HasRole(string roleName)
    {
        if (string.IsNullOrWhiteSpace(roleName)) return false;
        var csv = User.FindFirstValue("roles_csv") ?? User.FindFirstValue(ClaimTypes.Role);
        if (string.IsNullOrWhiteSpace(csv)) return false;
        return csv.Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Any(part => string.Equals(part.Trim(), roleName, StringComparison.OrdinalIgnoreCase));
    }

    private bool CanViewDirectory() => HasRole("admin") || HasRole("merchant");

    private static string? NormalizeOptional(string? value)
    {
        if (value is null) return null;
        var trimmed = value.Trim();
        return trimmed.Length == 0 ? null : trimmed;
    }
}
