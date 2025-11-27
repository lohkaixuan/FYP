using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models;

[Table("users")]
[Index(nameof(Email), IsUnique = true)]
[Index(nameof(PhoneNumber), IsUnique = true)]
[Index(nameof(ICNumber), IsUnique = true)]
public class User
{
    [Key]
    [Column("user_id")]
    public Guid UserId { get; set; } = Guid.NewGuid();

    [Required, MaxLength(80)]
    [Column("user_name")]
    public string UserName { get; set; } = string.Empty;

    [Column("user_age")]
    public int? UserAge { get; set; }

    // FK → roles(role_id)
    [Required]
    [Column("user_role")]
    public Guid RoleId { get; set; }
    public Role Role { get; set; } = default!;

    // DEV/TEST ONLY: plaintext (switch to hash for prod)
    [Required, MaxLength(200)]
    [Column("user_password")]
    public string UserPassword { get; set; } = string.Empty;

    [MaxLength(25)]
    [Column("user_phone_number")]
    public string? PhoneNumber { get; set; }

    [MaxLength(120)]
    [Column("user_email")]
    public string? Email { get; set; }

    [Required, MaxLength(20)]
    [Column("user_ic_number")]
    public string ICNumber { get; set; } = string.Empty;

    // Fast login (DEV/TEST plaintext 6 digits)
    [MaxLength(6)]
    [Column("user_passcode")]
    public string? Passcode { get; set; }

    [Precision(18, 2)]
    [Column("user_balance")]
    public decimal Balance { get; set; } = 0m;

    // ⇩ New tracking fields
    [MaxLength(1024)]
    [Column("jwt_token")]
    public string? JwtToken { get; set; }

    [Column("last_login")]
    public DateTime? LastLogin { get; set; }

    [Column("last_update")]
    public DateTime LastUpdate { get; set; } = DateTime.UtcNow;

    [Column("is_deleted")]
    public bool IsDeleted { get; set; } = false;

    // Navigation
    public ICollection<BankAccount> BankAccounts { get; set; } = new List<BankAccount>();
    public Merchant? Merchant { get; set; }
}
