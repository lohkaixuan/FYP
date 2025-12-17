// ApiApp/Models/Provider.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ApiApp.Models;

[Table("providers")]
public class Provider : BaseTracked
{
    [Key, Column("provider_id")]
    public Guid ProviderId { get; set; } = Guid.NewGuid();

    [Required, MaxLength(80), Column("name")]
    public string Name { get; set; } = string.Empty; // e.g. "MockBank"

    [Column("owner_user_id")]
    public Guid? OwnerUserId { get; set; }

    [MaxLength(200), Column("base_url")]
    public string? BaseUrl { get; set; }
    // ✅ 新增：API URL（必填）
    [MaxLength(300), Column("api_url")]
    public string ApiUrl { get; set; } = string.Empty;

    // ✅ 新增：加密后的 public key（必填，Base64/文本）
    [MaxLength(1024), Column("public_key_enc")]
    public string PublicKeyEnc { get; set; } = string.Empty;

    // ✅ 新增：加密后的 secret / private key（必填，Base64/文本）
    [MaxLength(1024), Column("private_key_enc")]
    public string PrivateKeyEnc { get; set; } = string.Empty;


    [Column("enabled")]
    public bool Enabled { get; set; } = true;

    public ICollection<ProviderCredential> Credentials { get; set; } = new List<ProviderCredential>();
}

[Table("provider_credentials")]
[Index(nameof(ProviderId), nameof(Type), IsUnique = true)]
public class ProviderCredential : BaseTracked
{
    [Key, Column("cred_id")]
    public Guid CredId { get; set; } = Guid.NewGuid();

    [Required, Column("provider_id")]
    public Guid ProviderId { get; set; }
    public Provider Provider { get; set; } = default!;

    [MaxLength(60), Column("type")]
    public string Type { get; set; } = "api_key"; // api_key / oauth / basic

    // ======= TEST ONLY =======
    // Keeping as plaintext for test (e.g., api_key, basic password, oauth token)
    // TODO(PROD): Replace with AES-GCM ciphertext and nonce/tag columns.
    [MaxLength(512), Column("value_plain")]
    public string ValuePlain { get; set; } = string.Empty;
    // ======= /TEST ONLY =======
}
