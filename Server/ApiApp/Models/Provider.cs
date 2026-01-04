// ==================================================
// Program Name   : Provider.cs
// Purpose        : Provider entity model
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
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
    public string Name { get; set; } = string.Empty; 

    [Column("owner_user_id")]
    public Guid? OwnerUserId { get; set; }

    [MaxLength(200), Column("base_url")]
    public string? BaseUrl { get; set; }

    [MaxLength(300), Column("api_url")]
    public string ApiUrl { get; set; } = string.Empty;

    [MaxLength(1024), Column("public_key_enc")]
    public string PublicKeyEnc { get; set; } = string.Empty;

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
    public string Type { get; set; } = "api_key"; 
    
    [MaxLength(512), Column("value_plain")]
    public string ValuePlain { get; set; } = string.Empty;
}
