// ==================================================
// Program Name   : Merchant.cs
// Purpose        : Merchant entity model
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
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

    [MaxLength(256)]
    [Column("merchant_doc")]
    public string? MerchantDocUrl { get; set; }

    [Column("merchant_doc_bytes")]
    public byte[]? MerchantDocBytes { get; set; }

    [MaxLength(128)]
    [Column("merchant_doc_content_type")]
    public string? MerchantDocContentType { get; set; }

    [Column("merchant_doc_size")]
    public long? MerchantDocSize { get; set; }

    [Column("owner_user_id")]
    public Guid? OwnerUserId { get; set; }
    public User? OwnerUser { get; set; }

    public ICollection<BankAccount> BankAccounts { get; set; } = new List<BankAccount>();
}
