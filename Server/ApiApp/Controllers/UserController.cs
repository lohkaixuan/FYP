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

        var target = await _db.Users.FirstOrDefaultAsync(u => u.UserId == id);
        if (target is null) return Results.NotFound();

        var isAdmin = HasRole("admin");
        var isMerchant = HasRole("merchant");
        var editingSelf = actorId.Value == id;

        if (!isAdmin && !isMerchant && !editingSelf)
            return Results.Forbid();

        var changed = false;

        if (!string.IsNullOrWhiteSpace(dto.user_name))
        {
            var trimmed = dto.user_name.Trim();
            if (!string.Equals(trimmed, target.UserName, StringComparison.Ordinal))
            {
                target.UserName = trimmed;
                changed = true;
            }
        }

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
            }
        }

        if (dto.user_age.HasValue)
        {
            if (dto.user_age.Value < 0) return Results.BadRequest(new { message = "Age must be positive" });
            if (target.UserAge != dto.user_age.Value)
            {
                target.UserAge = dto.user_age;
                changed = true;
            }
        }

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


    [HttpGet("all-users")]
    public async Task<IResult> ListAllUsers()
    {
        if (!CanViewDirectory()) return Results.Forbid();

        var users = await _db.Users.AsNoTracking()
            .Include(u => u.Role)
            .Where(u => u.Role != null && u.Role.RoleName == "user")
            .OrderBy(u => u.UserName)
            .Select(u => new
            {
                user_id = u.UserId,
                user_name = u.UserName,
                user_email = u.Email,
                user_phone_number = u.PhoneNumber,
                role = u.Role != null ? u.Role.RoleName : null,
                last_login = u.LastLogin, 
                is_deleted = u.IsDeleted
            })
            .ToListAsync();

        return Results.Ok(users);
    }


    [HttpGet("all-merchants")]
    public async Task<IResult> ListAllMerchants()
    {
        if (!CanViewDirectory()) return Results.Forbid();

        var merchants = await _db.Merchants.AsNoTracking()
            .Include(m => m.OwnerUser) // Load the linked User data
            .OrderBy(m => m.MerchantName)
            .Select(m => new
            {
                merchant_id = m.MerchantId,
                merchant_name = m.MerchantName,
                merchant_phone_number = m.MerchantPhoneNumber,
                owner_user_id = m.OwnerUserId,
                // Accessing User status via the navigation property
                is_deleted = m.OwnerUser != null && m.OwnerUser.IsDeleted,
                last_login = m.OwnerUser != null ? m.OwnerUser.LastLogin : null
            })
            .ToListAsync();

        return Results.Ok(merchants);
    }


    [HttpGet("all-providers")]
    public async Task<IResult> ListAllProviders()
    {
        if (!CanViewDirectory()) return Results.Forbid();

        // Since Provider.cs does not have a "public User OwnerUser" property,
        // we use a LINQ Join to connect Providers to Users manually.
        var query = from p in _db.Providers.AsNoTracking()
                    join u in _db.Users.AsNoTracking() 
                    on p.OwnerUserId equals u.UserId into userGroup
                    from subUser in userGroup.DefaultIfEmpty() // Left Join in case Owner is null
                    orderby p.Name
                    select new
                    {
                        provider_id = p.ProviderId,
                        name = p.Name,
                        base_url = p.BaseUrl,
                        enabled = p.Enabled,
                        // Mapping the User status columns
                        is_deleted = subUser != null && subUser.IsDeleted,
                        last_login = subUser != null ? subUser.LastLogin : null
                    };

        var providers = await query.ToListAsync();

        return Results.Ok(providers);
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
