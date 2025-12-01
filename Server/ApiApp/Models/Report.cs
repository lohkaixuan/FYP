using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
// Make sure this matches your actual EF Core model namespace if different
using ApiApp.Models; 

// -------------------- Core DTOs --------------------

// Request body when user generates report
public record MonthlyReportRequest(
    string Role,            // user | merchant | admin | thirdparty
    DateOnly Month,         // e.g. 2025-11-01 (first day of month)
    Guid? UserId = null,    // used for Role=user
    Guid? MerchantId = null,// used for Role=merchant
    Guid? ProviderId = null // used for Role=thirdparty
);

// Simplified structure of a point on daily chart
public record ChartPoint(DateOnly Day, decimal TotalAmount, int TxCount);

// Simple category breakdown for user (F&B vs Others)
public record CategoryTotal(string Category, decimal Amount);

// For admin/thirdparty daily unique counts
public record DailyCount(DateOnly Day, int Count);

// Main structure for any monthly chart report
public record MonthlyReportChart(
    string Currency,
    List<ChartPoint> Daily,          // daily total per day
    decimal TotalVolume,             // sum of all tx in the month
    int TxCount,                     // total # of transactions
    decimal AvgTx,                   // average transaction size
    int ActiveUsers,                 // # of distinct users in month
    int ActiveMerchants,             // # of distinct merchants in month

    // Role-specific extras
    List<CategoryTotal>? CategoryTotals = null,   // user: F&B vs Others
    decimal? GrossSales = null,                   // merchant
    decimal? Refunds = null,                      // merchant
    decimal? NetSales = null,                     // merchant
    List<DailyCount>? AdminDailyUsers = null,     // admin
    List<DailyCount>? ThirdPartyDailyUsers = null // thirdparty
);

// Response returned by API after generation
public record MonthlyReportResponse(
    Guid ReportId,
    string Role,
    DateOnly Month,
    string PdfDownloadUrl
);

// -------------------- EF Core Entity (Assuming it's here or in ApiApp.Models) --------------------

// Assuming this class is used for EF Core mapping to the 'reports' table.
// If your Report model is in a separate file (e.g., ApiApp/Models/Report.cs), copy only the property part there.
public class Report
{
    // These existing properties should be defined in your actual Report entity class
    // public Guid Id { get; set; }
    // [Column("chart_json")] public string? ChartJson { get; set; }
    // [Column("pdf_data")] public byte[]? PdfData { get; set; }
    // ... other Report properties ...

    // ✨ NEW: Property for the Download Link
    [Column("pdf_url")]
    [MaxLength(256)] 
    public string? PdfUrl { get; set; }

    // ... other properties (CreatedAt, LastUpdate, IsDeleted) ...
}