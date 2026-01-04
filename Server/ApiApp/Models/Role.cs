// ==================================================
// Program Name   : Role.cs
// Purpose        : Role entity model
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
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
