using System.Text.Json;
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
        // 1️⃣ 计算本月时间范围
        var mStart = new DateOnly(req.Month.Year, req.Month.Month, 1);
        var mEndExcl = mStart.AddMonths(1);

        var start = new DateTime(mStart.Year, mStart.Month, mStart.Day, 0, 0, 0, DateTimeKind.Utc);
        var endExcl = new DateTime(mEndExcl.Year, mEndExcl.Month, mEndExcl.Day, 0, 0, 0, DateTimeKind.Utc);

        // 基础 WHERE 条件：时间 + 成功交易
        var where = @"
t.transaction_timestamp >= @start
and t.transaction_timestamp <  @endExcl
and t.transaction_status = 'success'";

        // 因为要按 user / merchant 过滤，需要 join wallets
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

        // 角色过滤
        if (req.Role.Equals("user", StringComparison.OrdinalIgnoreCase) && req.UserId is not null)
        {
            where += " and (wf.user_id = @UserId or wt.user_id = @UserId)";
        }
        else if (req.Role.Equals("merchant", StringComparison.OrdinalIgnoreCase) && req.MerchantId is not null)
        {
            where += " and (wf.merchant_id = @MerchantId or wt.merchant_id = @MerchantId)";
        }
        // admin / thirdparty 暂时看全局（你以后要细分可以再加条件）

        // 2️⃣ Daily series：每天金额 + 笔数
        var dailySql = $@"
select
    date_trunc('day', t.transaction_timestamp) as day,
    coalesce(sum(t.transaction_amount), 0)    as total_amount,
    count(*)                                  as tx_count
{joinWallets}
where {where}
group by day
order by day;";

        // 2️⃣ Daily series：每天金额 + 笔数
        var dailyRows = await conn.QueryAsync(dailySql, param);

        var points = new List<ChartPoint>();
        foreach (var row in dailyRows)
        {
            DateTime day = row.day;
            decimal totalAmount = row.total_amount;
            int txCount = Convert.ToInt32(row.tx_count);   // ⭐ 显式转成 int

            points.Add(new ChartPoint(
                Day: DateOnly.FromDateTime(day),
                TotalAmount: totalAmount,
                TxCount: txCount
            ));
        }

        // 3️⃣ Aggregates：总金额 / 总笔数 / 平均 / 活跃用户 / 商家
        var aggSql = $@"
select
    coalesce(sum(t.transaction_amount), 0)                       as total_volume,
    count(*)                                                     as tx_count,
    coalesce(avg(nullif(t.transaction_amount, 0)), 0)            as avg_tx,
    count(distinct coalesce(wf.user_id, wt.user_id))             as active_users,
    count(distinct coalesce(wf.merchant_id, wt.merchant_id))     as active_merchants
{joinWallets}
where {where};";

        // 3️⃣ Aggregates：总金额 / 总笔数 / 平均 / 活跃用户 / 商家
        var agg = await conn.QuerySingleAsync(aggSql, param);

        decimal totalVolume = agg.total_volume;
        int txCountAgg = Convert.ToInt32(agg.tx_count);          // ⭐
        decimal avgTx = agg.avg_tx;
        int activeUsers = Convert.ToInt32(agg.active_users);      // ⭐
        int activeMerchants = Convert.ToInt32(agg.active_merchants);  // ⭐

        // 4️⃣ 组装成 MonthlyReportChart（PdfRenderer 用它来画表格）
        var chart = new MonthlyReportChart(
            Currency: "MYR",            // 先写死 MYR，有需要再从别表算
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
        CancellationToken ct)
    {
        // 1. Serialize chart to JSON
        var chartJson = JsonSerializer.Serialize(chart);
        
        // 2. Pre-generate ID (FIX for Dapper/NOT NULL constraint)
        var newReportId = Guid.NewGuid();
        const string contentType = "application/pdf";
        // ⭐ NEW: 获取当前时间 (Get current time)
        var nowUtc = DateTime.UtcNow; 

        // 3. Upsert into 'reports' table, INCLUDING PDF DATA, matching ReportEntity.cs
        // 🚨 FIX 1: Add 'created_at' to INSERT list.
        var upsertSql = @"
insert into reports (id, role, month, created_by, chart_json, pdf_data, content_type, created_at)
values (@id, @role, @month, @createdBy, @chartJson::jsonb, @pdfBytes, @contentType, @nowUtc)
on conflict (role, month, created_by) do update
set chart_json = excluded.chart_json,
    pdf_data = excluded.pdf_data,
    content_type = excluded.content_type,
    created_at = reports.created_at  -- ⭐ UPDATE: DO NOT change created_at on update
returning id;";

        var reportId = await conn.ExecuteScalarAsync<Guid>(
            new CommandDefinition(
                upsertSql,
                new
                {
                    id = newReportId,
                    role = req.Role.ToLowerInvariant(),
                    month = new DateTime(req.Month.Year, req.Month.Month, 1),
                    createdBy,
                    chartJson,
                    pdfBytes = pdf,
                    contentType,
                    nowUtc // 👈 FIX: Pass the current time parameter
                },
                cancellationToken: ct));
        
        return reportId;
    }

    public async Task<(string ContentType, byte[] Bytes, Guid? CreatedBy, string Role)?>
        GetPdfAsync(NpgsqlConnection conn, Guid reportId, CancellationToken ct)
    {
        // 🚨 FIX: 从 reports 表获取 PDF 字节和类型 (Get PDF bytes and type from reports table)
        var sql = @"
select
    r.content_type,
    r.pdf_data as bytes, -- 👈 字段名对齐 (Aligning column name)
    r.created_by,
    r.role
from reports r
where r.id = @id;";

        var row = await conn.QuerySingleOrDefaultAsync(sql, new { id = reportId });

        if (row is null || row.bytes is null) return null; // 🚨 FIX: 检查 bytes 是否为空 (Check if bytes is null)

        string contentType = row.content_type ?? "application/pdf";
        byte[] bytes = row.bytes;
        Guid? createdBy = row.created_by is null ? (Guid?)null : (Guid)row.created_by;
        string role = row.role;

        return (contentType, bytes, createdBy, role);
    }
}