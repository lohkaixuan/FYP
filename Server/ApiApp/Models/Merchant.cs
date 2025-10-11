using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ApiApp.Models;

[Table("merchants")]
public class Merchant
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

    [Column("owner_user_id")]
    public Guid? OwnerUserId { get; set; }
    public User? OwnerUser { get; set; }
    
    [Column("last_update")]
    public DateTime last_update { get; set; } = DateTime.UtcNow;

    public ICollection<BankAccount> BankAccounts { get; set; } = new List<BankAccount>();
}
