// ==================================================
// Program Name   : Report.cs
// Purpose        : Report entity model
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
using ApiApp.Models; 

// -------------------- Core DTOs --------------------
// Request body when user generates report
public record MonthlyReportRequest(
    string Role,            // user | merchant | admin | thirdparty
    DateOnly Month,         
    Guid? UserId = null,    
    Guid? MerchantId = null,
    Guid? ProviderId = null 
);

public record ChartPoint(DateOnly Day, decimal TotalAmount, int TxCount);

public record CategoryTotal(string Category, decimal Amount);

public record DailyCount(DateOnly Day, int Count);

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

public class Report
{
    [Column("pdf_url")]
    [MaxLength(256)] 
    public string? PdfUrl { get; set; }
}