// ApiApp/Models/Merchant.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ApiApp.Models;

[Table("merchants")]
public class Merchant : BaseTracked
{
    [Key]
    [Column("merchant_id")]
    public Guid MerchantId { get; set; } = Guid.NewGuid();

    [Required, MaxLength(120)]
    [Column("merchant_name")]
    public string MerchantName { get; set; } = string.Empty;

    [MaxLength(25)]
    [Column("merchant_phone_number")]
    public string? MerchantPhoneNumber { get; set; }

    // 原本就有的 URL（给前端列表用）
    [MaxLength(256)]
    [Column("merchant_doc")]
    public string? MerchantDocUrl { get; set; }

    // 🆕 文件二进制
    [Column("merchant_doc_bytes")]
    public byte[]? MerchantDocBytes { get; set; }

    // 🆕 MIME 类型，例如 "application/pdf" / "image/png"
    [MaxLength(128)]
    [Column("merchant_doc_content_type")]
    public string? MerchantDocContentType { get; set; }

    // 🆕 文件大小（字节）
    [Column("merchant_doc_size")]
    public long? MerchantDocSize { get; set; }

    [Column("owner_user_id")]
    public Guid? OwnerUserId { get; set; }
    public User? OwnerUser { get; set; }

    public ICollection<BankAccount> BankAccounts { get; set; } = new List<BankAccount>();
}
