// ==================================================
// Program Name   : ReportHelpher.cs
// Purpose        : Helper utilities for report generation
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using Npgsql;

// ===== Interface =====
public interface IReportRepository
{
    Task<MonthlyReportChart> BuildMonthlyChartAsync(
        NpgsqlConnection conn,
        MonthlyReportRequest req,
        CancellationToken ct);
    Task<Guid> UpsertReportAndFileAsync(
        NpgsqlConnection conn,
        MonthlyReportRequest req,
        MonthlyReportChart chart,
        byte[] pdf,
        Guid? createdBy,
        string pdfUrl,
        CancellationToken ct);
    Task<(string ContentType, byte[] Bytes, Guid? CreatedBy, string Role)?>
        GetPdfAsync(NpgsqlConnection conn, Guid reportId, CancellationToken ct);
}

// ===== Implementation =====
public sealed class ReportRepository : IReportRepository
{
    public async Task<MonthlyReportChart> BuildMonthlyChartAsync(
        NpgsqlConnection conn,
        MonthlyReportRequest req,
        CancellationToken ct)
    {
        var mStart = new DateOnly(req.Month.Year, req.Month.Month, 1);
        var mEndExcl = mStart.AddMonths(1);
        var start = new DateTime(mStart.Year, mStart.Month, mStart.Day, 0, 0, 0, DateTimeKind.Utc);
        var endExcl = new DateTime(mEndExcl.Year, mEndExcl.Month, mEndExcl.Day, 0, 0, 0, DateTimeKind.Utc);
        var where = @"
t.transaction_timestamp >= @start
and t.transaction_timestamp <  @endExcl
and t.transaction_status = 'success'";

        var joinWallets = @"
from transactions t
left join wallets wf on wf.wallet_id = t.from_wallet_id
left join wallets wt on wt.wallet_id = t.to_wallet_id
";

        var param = new DynamicParameters(new
        {
            start,
            endExcl,
            req.UserId,
            req.MerchantId
        });

        if (req.Role.Equals("user", StringComparison.OrdinalIgnoreCase) && req.UserId is not null)
        {
            where += " and (wf.user_id = @UserId or wt.user_id = @UserId)";
        }
        else if (req.Role.Equals("merchant", StringComparison.OrdinalIgnoreCase) && req.MerchantId is not null)
        {
            where += " and (wf.merchant_id = @MerchantId or wt.merchant_id = @MerchantId)";
        }

        var dailySql = $@"
select
    date_trunc('day', t.transaction_timestamp) as day,
    coalesce(sum(t.transaction_amount), 0)     as total_amount,
    count(*)                                   as tx_count
{joinWallets}
where {where}
group by day
order by day;";

        var dailyRows = await conn.QueryAsync(dailySql, param);

        var points = new List<ChartPoint>();
        foreach (var row in dailyRows)
        {
            DateTime day = row.day;
            decimal totalAmount = row.total_amount;
            int txCount = Convert.ToInt32(row.tx_count);

            points.Add(new ChartPoint(
                Day: DateOnly.FromDateTime(day),
                TotalAmount: totalAmount,
                TxCount: txCount
            ));
        }

        var aggSql = $@"
select
    coalesce(sum(t.transaction_amount), 0)                       as total_volume,
    count(*)                                                     as tx_count,
    coalesce(avg(nullif(t.transaction_amount, 0)), 0)            as avg_tx,
    count(distinct coalesce(wf.user_id, wt.user_id))             as active_users,
    count(distinct coalesce(wf.merchant_id, wt.merchant_id))     as active_merchants
{joinWallets}
where {where};";

        var agg = await conn.QuerySingleAsync(aggSql, param);

        decimal totalVolume = agg.total_volume;
        int txCountAgg = Convert.ToInt32(agg.tx_count);
        decimal avgTx = agg.avg_tx;
        int activeUsers = Convert.ToInt32(agg.active_users);
        int activeMerchants = Convert.ToInt32(agg.active_merchants);

        var chart = new MonthlyReportChart(
            Currency: "MYR",
            Daily: points,
            TotalVolume: totalVolume,
            TxCount: txCountAgg,
            AvgTx: avgTx,
            ActiveUsers: activeUsers,
            ActiveMerchants: activeMerchants
        );
        return chart;
    }

    public async Task<Guid> UpsertReportAndFileAsync(
        NpgsqlConnection conn,
        MonthlyReportRequest req,
        MonthlyReportChart chart,
        byte[] pdf,
        Guid? createdBy,
        string pdfUrl,
        CancellationToken ct)
    {
        var chartJson = JsonSerializer.Serialize(chart);
        var newId = Guid.NewGuid();

        const string contentType = "application/pdf";

        var upsertSql = @"
insert into reports (
    id, role, month, created_by,
    chart_json,
    pdf_data, content_type, pdf_url,
    created_at, last_update
)
values (
    @id, @role, @month, @createdBy,
    @chartJson::jsonb,
    @pdf, @contentType, @pdfUrl,
    now(), now()
)
on conflict (role, month, created_by) do update
set chart_json   = excluded.chart_json,
    pdf_data     = excluded.pdf_data,
    content_type = excluded.content_type,
    pdf_url      = excluded.pdf_url,
    last_update  = now()
returning id;";

        var reportId = await conn.ExecuteScalarAsync<Guid>(
            new CommandDefinition(
                upsertSql,
                new
                {
                    id = newId,
                    role = req.Role.ToLowerInvariant(),
                    month = new DateTime(req.Month.Year, req.Month.Month, 1),
                    createdBy = createdBy,
                    chartJson = chartJson,
                    pdf = pdf,
                    contentType,
                    pdfUrl = pdfUrl
                },
                cancellationToken: ct));

        return reportId;
    }

    public async Task<(string ContentType, byte[] Bytes, Guid? CreatedBy, string Role)?>
        GetPdfAsync(NpgsqlConnection conn, Guid reportId, CancellationToken ct)
    {
        var sql = @"
select
    pdf_data,
    content_type,
    created_by,
    role
from reports
where id = @id";

        var row = await conn.QuerySingleOrDefaultAsync(sql, new { id = reportId });

        if (row is null)
            return null;

        string contentType = row.content_type ?? "application/pdf";
        byte[] bytes = row.pdf_data;
        Guid? createdBy = row.created_by is null ? (Guid?)null : (Guid)row.created_by;
        string role = row.role;

        return (contentType, bytes, createdBy, role);
    }
}
