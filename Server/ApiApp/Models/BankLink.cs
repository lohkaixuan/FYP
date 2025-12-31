
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace ApiApp.Models;

[Table("bank_links")]
public class BankLink : BaseTracked
{
    [Key]
    [Column("link_id")]
    public Guid LinkId { get; set; }

    [Column("user_id")]
    public Guid? UserId { get; set; }

    [Column("merchant_id")]
    public Guid? MerchantId { get; set; }

    [Required]
    [Column("provider_id")]
    public Guid ProviderId { get; set; }

    [Required]
    [Column("external_account_ref")]
    public string ExternalAccountRef { get; set; } = "";

    [Column("display_name")]
    public string DisplayName { get; set; } = "";

    // 🔐 NEW: encrypted access token
    [Column("external_access_token_enc")]
    public string? ExternalAccessTokenEnc { get; set; }

    // ⏰ optional expiry
    [Column("external_token_expires_at")]
    public DateTime? ExternalTokenExpiresAt { get; set; }

    // 🧾 raw login JSON (debug / audit)
    [Column("external_raw_json")]
    public JsonDocument? ExternalRawJson { get; set; }

    // navigation (optional)
    public Provider? Provider { get; set; }
}

