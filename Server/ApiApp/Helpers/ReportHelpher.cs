using Dapper;
using Npgsql;
using System.Text.Json;

public interface IReportRepository
{
    Task<MonthlyReportChart> BuildMonthlyChartAsync(NpgsqlConnection conn, MonthlyReportRequest req, CancellationToken ct);
    Task<Guid> UpsertReportAndFileAsync(NpgsqlConnection conn, MonthlyReportRequest req, MonthlyReportChart chart, byte[] pdf, Guid? createdBy, CancellationToken ct);
    Task<(string ContentType, byte[] Bytes)?> GetPdfAsync(NpgsqlConnection conn, Guid reportId, CancellationToken ct);
}

public class ReportRepository : IReportRepository
{
    public async Task<MonthlyReportChart> BuildMonthlyChartAsync(NpgsqlConnection conn, MonthlyReportRequest req, CancellationToken ct)
    {
        var mStart = new DateOnly(req.Month.Year, req.Month.Month, 1);
        var mEndExcl = mStart.AddMonths(1);

        // base filters
        var where = @"
            t.created_at >= @mStart
            and t.created_at <  @mEndExcl
            and t.status = 'settled'";

        var p = new DynamicParameters(new {
            mStart = new DateTime(mStart.Year, mStart.Month, mStart.Day),
            mEndExcl = new DateTime(mEndExcl.Year, mEndExcl.Month, mEndExcl.Day),
            req.UserId,
            req.MerchantId
        });

        if (req.Role.Equals("user", StringComparison.OrdinalIgnoreCase))
        {
            where += " and t.user_id = @UserId";
        }
        else if (req.Role.Equals("merchant", StringComparison.OrdinalIgnoreCase))
        {
            where += " and t.merchant_id = @MerchantId";
        }

        // Daily series
        var dailySql = $@"
with days as (
  select generate_series(@mStart::date, (@mEndExcl::date - interval '1 day')::date, interval '1 day')::date as day
)
select d.day,
       coalesce(sum(t.amount_cents)/100.0, 0) as total_amount,
       count(t.id) as tx_count
from days d
left join transactions t on t.created_at::date = d.day
  and {where}
group by d.day
order by d.day";

        var daily = await conn.QueryAsync(dailySql, p);

        // Aggregates
        var aggSql = $@"
select
  coalesce(sum(t.amount_cents)/100.0, 0) as total_volume,
  count(*) as tx_count,
  coalesce(avg(nullif(t.amount_cents,0))/100.0, 0) as avg_tx,
  count(distinct t.user_id) as active_users,
  count(distinct t.merchant_id) as active_merchants
from transactions t
where {where}";

        var agg = await conn.QuerySingleAsync(aggSql, p);

        // Currency: if single currency in system, set "MYR"; else query.
        var currency = "MYR";

        var points = new List<ChartPoint>();
        foreach (var row in daily)
        {
            var day = (DateTime)row.day;
            points.Add(new ChartPoint(DateOnly.FromDateTime(day), (decimal)row.total_amount, (int)row.tx_count));
        }

        return new MonthlyReportChart(
            Currency: currency,
            Daily: points,
            TotalVolume: (decimal)agg.total_volume,
            TxCount: (int)agg.tx_count,
            AvgTx: (decimal)agg.avg_tx,
            ActiveUsers: (int)agg.active_users,
            ActiveMerchants: (int)agg.active_merchants
        );
    }

    public async Task<Guid> UpsertReportAndFileAsync(NpgsqlConnection conn, MonthlyReportRequest req, MonthlyReportChart chart, byte[] pdf, Guid? createdBy, CancellationToken ct)
    {
        // Ensure we have a metadata row; re-create or update same (role, month, created_by) “slot”.
        var chartJson = JsonSerializer.Serialize(chart);

        // If you scope by user/merchant, add those columns and into the WHERE/INSERT below.
        var upsertSql = @"
insert into reports (role, month, created_by, chart_json)
values (@role, @month, @createdBy, @chartJson::jsonb)
on conflict (role, month, created_by) do update
set chart_json = excluded.chart_json,
    created_at = now()
returning id;";

        var reportId = await conn.ExecuteScalarAsync<Guid>(new CommandDefinition(
            upsertSql,
            new {
                role = req.Role.ToLowerInvariant(),
                month = new DateTime(req.Month.Year, req.Month.Month, 1),
                createdBy,
                chartJson
            },
            cancellationToken: ct));

        // Upsert file
        var upsertFile = @"
insert into report_files (report_id, content, size_bytes)
values (@rid, @bytes, @size)
on conflict (report_id) do update
set content = excluded.content,
    size_bytes = excluded.size_bytes,
    created_at = now();";

        await conn.ExecuteAsync(new CommandDefinition(
            upsertFile,
            new { rid = reportId, bytes = pdf, size = pdf.Length },
            cancellationToken: ct));

        return reportId;
    }

    public async Task<(string ContentType, byte[] Bytes)?> GetPdfAsync(NpgsqlConnection conn, Guid reportId, CancellationToken ct)
    {
        var sql = "select content_type, content from report_files where report_id = @id";
        var row = await conn.QuerySingleOrDefaultAsync(sql, new { id = reportId });
        if (row is null) return null;
        return ((string)row.content_type, (byte[])row.content);
    }
}
