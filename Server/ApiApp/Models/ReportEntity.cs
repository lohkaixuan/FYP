// File: ApiApp/Models/ReportEntity.cs

using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ApiApp.Models;

[Table("reports")]
public class Report : BaseTracked // 确保你的 BaseTracked 有 IsDeleted 和时间戳 (Ensure your BaseTracked has IsDeleted and timestamps)
{
    // C# GUID to map to DB UUID (PK)
    [Key, Column("id")]
    public Guid Id { get; set; } = Guid.NewGuid();

    // The role/owner who generated the report
    [Required, MaxLength(20), Column("role")]
    public string Role { get; set; } = default!; // 'user', 'merchant', 'thirdparty'

    // The month the report covers (stored as the first day of the month in UTC)
    [Column("month")]
    public DateTime Month { get; set; }

    // The ID of the user who is the subject/owner of the report (e.g. UserId for user role)
    [Column("created_by")]
    public Guid? CreatedBy { get; set; }

    // Binary PDF data
    [Column("pdf_data")]
    public byte[]? PdfData { get; set; }

    // File content type (e.g., 'application/pdf')
    [MaxLength(80), Column("content_type")]
    public string? ContentType { get; set; }

    // Store the generated chart data as JSON string for potential re-use or debugging
    [Column("chart_json")]
    public string? ChartJson { get; set; }

    // 假设你还需要一个唯一索引来防止重复生成:
    // This unique constraint needs to be configured in AppDbContext.cs
}