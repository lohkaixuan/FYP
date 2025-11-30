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
        public string? merchant_name { get; set; }
        public string? merchant_phone_number { get; set; }
        public string? provider_base_url { get; set; }
        public bool? provider_enabled { get; set; }
        public bool? is_deleted { get; set; } 
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
        // 1. Fetch the User
    var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(x => x.UserId == id);
    if (user is null) return Results.NotFound();

    // 2. Fetch Merchant Info (if this user is an owner)
    var merchant = await _db.Merchants.AsNoTracking()
        .FirstOrDefaultAsync(m => m.OwnerUserId == id);

    // 3. Fetch Provider Info (if this user is a provider)
    var provider = await _db.Providers.AsNoTracking()
        .FirstOrDefaultAsync(p => p.OwnerUserId == id);

    // 4. Return a merged object
    return Results.Ok(new
    {
        // --- Standard User Fields ---
        user_id = user.UserId,
        user_name = user.UserName,
        user_email = user.Email,
        user_phone_number = user.PhoneNumber,
        user_age = user.UserAge,
        user_ic_number = user.ICNumber,
        user_balance = user.Balance,
        last_login = user.LastLogin,
        is_deleted = user.IsDeleted,

        // --- Merchant Extras ---
        merchant_id = merchant?.MerchantId,
        merchant_name = merchant?.MerchantName,
        merchant_phone_number = merchant?.MerchantPhoneNumber,

        // --- Provider Extras ---
        provider_id = provider?.ProviderId,
        provider_base_url = provider?.BaseUrl,
        provider_enabled = provider?.Enabled
    });
    }

    [HttpPut("{id:guid}")]
    public async Task<IResult> Update(Guid id, [FromBody] UpdateUserDto dto)
    {
      if (dto is null) return Results.BadRequest(new { message = "Body is required" });

    var actorId = GetCurrentUserId();
    if (actorId is null) return Results.Unauthorized();

    // 1. Get the User & their Role
    var target = await _db.Users
        .Include(u => u.Role)
        .FirstOrDefaultAsync(u => u.UserId == id);

    if (target is null) return Results.NotFound();

    var isAdmin = HasRole("admin");
    // Allow users to delete themselves if needed, or restrict to admin only.
    // For now, assuming admin does the deleting based on your UI screenshots.
    if (!isAdmin) return Results.Forbid();

    // ==================================================================
    // SOFT DELETE LOGIC (Intercept Request if is_deleted is sent)
    // ==================================================================
    if (dto.is_deleted.HasValue)
    {
        bool shouldDelete = dto.is_deleted.Value;
        string roleName = target.Role?.RoleName?.ToLower() ?? "user";
        bool deleteChanged = false;

        // LOAD ASSOCIATED ENTITIES (needed for Merchant/Provider deletion)
        var merchant = await _db.Merchants.FirstOrDefaultAsync(m => m.OwnerUserId == target.UserId);
        var provider = await _db.Providers.FirstOrDefaultAsync(p => p.OwnerUserId == target.UserId);

        if (shouldDelete)
        {
            // --- SCENARIO: DELETING (Deactivating) ---
            
            if (roleName == "merchant")
            {
                // Requirement: Demote to 'user' role, soft delete merchant record.
                
                // 1. Find the 'user' role ID needed for demotion
                var userRole = await _db.Roles.FirstOrDefaultAsync(r => r.RoleName == "user");
                if (userRole == null) return Results.Problem("Default 'user' role not found in DB.");

                // 2. Demote the User
                if (target.RoleId != userRole.RoleId)
                {
                    target.RoleId = userRole.RoleId;
                    // Note: We do NOT set target.IsDeleted = true for the user record here, 
                    // as they are just being demoted to a regular user.
                    deleteChanged = true;
                }

                // 3. Soft Delete the Merchant record
                if (merchant != null && !merchant.IsDeleted)
                {
                    merchant.IsDeleted = true;
                    deleteChanged = true;
                }
            }
            else if (roleName == "provider" || roleName == "thirdparty")
            {
                // Requirement: Soft delete user record AND provider record.

                // 1. Soft Delete User Record
                if (!target.IsDeleted) { target.IsDeleted = true; deleteChanged = true; }

                // 2. Soft Delete Provider Record
                if (provider != null && !provider.Enabled) // Assuming 'Enabled=false' means soft deleted for provider based on your model
                {
                     // If your Provider model has IsDeleted, use that. 
                     // Based on apimodel.dart, it has 'enabled'. Let's assume disabling = soft delete.
                     provider.Enabled = false;
                     deleteChanged = true;
                }
                 // If you add IsDeleted to Provider model later:
                 // if (provider != null && !provider.IsDeleted) { provider.IsDeleted = true; deleteChanged = true; }
            }
            else
            {
                // Requirement: Standard User -> Soft delete user record.
                if (!target.IsDeleted) { target.IsDeleted = true; deleteChanged = true; }
            }
        }
        else
        {
             // --- SCENARIO: REACTIVATING (Optional, if you want a single toggle endpoint) ---
             // Logic to reverse the above (e.g., set IsDeleted = false). 
             // For simplicity based on your request, I'll stick to just deletion logic above.
             // If you send is_deleted: false, nothing happens currently.
        }


        if (deleteChanged)
        {
            target.LastUpdate = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            // Return the updated user object so UI can update status immediately
            return Results.Ok(new { message = "Account deactivated successfully", user = await GetUserResponse(target.UserId) });
        }
         return Results.Ok(new { message = "Account is already deactivated", user = await GetUserResponse(target.UserId) });
    }

    // ==================================================================
    // NORMAL UPDATE LOGIC (Your existing code for profile edits)
    // ==================================================================
    // ... (Keep your entire existing Part A, Part B, Part C logic here) ...
    // ... This part only runs if dto.is_deleted is null ...

    var changed = false;
    // PART A: UPDATE USER (Owner) INFO
    if (!string.IsNullOrWhiteSpace(dto.user_name)) { var val = dto.user_name.Trim(); if (target.UserName != val) { target.UserName = val; changed = true; } }
    if (dto.user_email != null) { var val = dto.user_email.Trim(); if (target.Email != val) { target.Email = val; changed = true; } }
    if (dto.user_phone_number != null) { var val = dto.user_phone_number.Trim(); if (target.PhoneNumber != val) { target.PhoneNumber = val; changed = true; } }
    if (dto.user_age.HasValue && target.UserAge != dto.user_age.Value) { target.UserAge = dto.user_age.Value; changed = true; }
    if (dto.user_ic_number != null && target.ICNumber != dto.user_ic_number) { target.ICNumber = dto.user_ic_number; changed = true; }

    // PART B: UPDATE MERCHANT INFO
    var merchantForUpdate = await _db.Merchants.FirstOrDefaultAsync(m => m.OwnerUserId == target.UserId);
    if (merchantForUpdate != null)
    {
        if (!string.IsNullOrWhiteSpace(dto.merchant_name)) { var val = dto.merchant_name.Trim(); if (merchantForUpdate.MerchantName != val) { merchantForUpdate.MerchantName = val; changed = true; } }
        if (dto.merchant_phone_number != null) { var val = dto.merchant_phone_number.Trim(); if (merchantForUpdate.MerchantPhoneNumber != val) { merchantForUpdate.MerchantPhoneNumber = val; changed = true; } }
    }

    // PART C: UPDATE PROVIDER INFO
    var providerForUpdate = await _db.Providers.FirstOrDefaultAsync(p => p.OwnerUserId == target.UserId);
    if (providerForUpdate != null)
    {
        if (providerForUpdate.Name != target.UserName) { providerForUpdate.Name = target.UserName; changed = true; }
        if (dto.provider_base_url != null) { var val = dto.provider_base_url.Trim(); if (providerForUpdate.BaseUrl != val) { providerForUpdate.BaseUrl = val; changed = true; } }
        if (dto.provider_enabled.HasValue) { if (providerForUpdate.Enabled != dto.provider_enabled.Value) { providerForUpdate.Enabled = dto.provider_enabled.Value; changed = true; } }
    }

    if (changed)
    {
        target.LastUpdate = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        // Use helper method for consistent response
        return Results.Ok(new { message = "Account updated successfully", user = await GetUserResponse(target.UserId) });
    }

    return Results.Ok(new { message = "No changes detected", user = await GetUserResponse(target.UserId) });
}

// Helper method to generate the response object (keeps the main method cleaner)
private async Task<object> GetUserResponse(Guid userId)
{
    var user = await _db.Users.AsNoTracking().Include(u => u.Role).FirstOrDefaultAsync(u => u.UserId == userId);
    var merchant = await _db.Merchants.AsNoTracking().FirstOrDefaultAsync(m => m.OwnerUserId == userId);
    var provider = await _db.Providers.AsNoTracking().FirstOrDefaultAsync(p => p.OwnerUserId == userId);

    return new
    {
        user_id = user.UserId,
        user_name = user.UserName,
        user_email = user.Email,
        user_phone_number = user.PhoneNumber,
        user_age = user.UserAge,
        user_ic_number = user.ICNumber,
        role_id = user.RoleId,
        role_name = user.Role?.RoleName, // Helpful for UI
        is_deleted = user.IsDeleted,     // Crucial for UI status
        merchant_name = merchant?.MerchantName,
        merchant_phone_number = merchant?.MerchantPhoneNumber,
        merchant_is_deleted = merchant?.IsDeleted, // Crucial for Merchant status
        provider_base_url = provider?.BaseUrl,
        provider_enabled = provider?.Enabled
    };
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
