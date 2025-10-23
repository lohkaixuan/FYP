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

    [MaxLength(200), Column("base_url")]
    public string? BaseUrl { get; set; }

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

[Table("bank_links")]
// A given user should have at most one active link per provider account ref.
[Index(nameof(UserId), nameof(ProviderId), nameof(ExternalAccountRef), IsUnique = true)]
public class BankLink : BaseTracked
{
    [Key, Column("link_id")]
    public Guid LinkId { get; set; } = Guid.NewGuid();

    [Column("user_id")]
    public Guid? UserId { get; set; }

    [Column("merchant_id")]
    public Guid? MerchantId { get; set; }

    [Required, Column("provider_id")]
    public Guid ProviderId { get; set; }
    public Provider Provider { get; set; } = default!;

    [MaxLength(120), Column("external_account_ref")]
    public string ExternalAccountRef { get; set; } = string.Empty; // e.g., bank acct no

    [MaxLength(120), Column("display_name")]
    public string? DisplayName { get; set; }
}
