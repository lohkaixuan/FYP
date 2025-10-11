using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ApiApp.Models;

[Table("roles")]
public class Role
{
    [Key]
    [Column("role_id")]
    public Guid RoleId { get; set; } = Guid.NewGuid();

    [Required, MaxLength(50)]
    [Column("role_name")]
    public string RoleName { get; set; } = string.Empty;

    public ICollection<User> Users { get; set; } = new List<User>();
}
