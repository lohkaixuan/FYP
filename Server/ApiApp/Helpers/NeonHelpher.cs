using Npgsql;
using System.Text;
using System.Text.RegularExpressions;

namespace ApiApp.Services;

public interface ISqlCrudHelper
{
    Task<int> InsertAsync(string table, IDictionary<string, object> data);
    Task<int> UpdateByIdAsync(string table, int id, IDictionary<string, object> data, string idColumn = "id");
    Task<int> DeleteByIdAsync(string table, int id, string idColumn = "id");
    Task<List<Dictionary<string, object>>> QueryAsync(
        string table,
        string? where = null,
        IDictionary<string, object>? parameters = null,
        int? limit = null);
}

public class SqlCrudHelper : ISqlCrudHelper
{
    private readonly string _conn;

    public SqlCrudHelper(string connectionString) => _conn = connectionString;

    static readonly Regex Ident = new(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);

    private static string QI(string name)
    {
        if (!Ident.IsMatch(name)) throw new ArgumentException($"Invalid identifier: {name}");
        return $"\"{name}\""; // quote identifiers safely
    }

    public async Task<int> InsertAsync(string table, IDictionary<string, object> data)
    {
        if (data.Count == 0) throw new ArgumentException("No columns provided");

        var cols = data.Keys.Select(QI).ToArray();
        var paramNames = data.Keys.Select((k, i) => $"@p{i}").ToArray();

        var sql = $"INSERT INTO {QI(table)} ({string.Join(",", cols)}) VALUES ({string.Join(",", paramNames)})";

        await using var conn = new NpgsqlConnection(_conn);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(sql, conn);
        int i = 0;
        foreach (var kv in data)
            cmd.Parameters.AddWithValue(paramNames[i++], kv.Value ?? DBNull.Value);

        return await cmd.ExecuteNonQueryAsync();
    }

    public async Task<int> UpdateByIdAsync(string table, int id, IDictionary<string, object> data, string idColumn = "id")
    {
        if (data.Count == 0) throw new ArgumentException("No columns provided");

        var sets = data.Keys.Select((k, i) => $"{QI(k)}=@p{i}").ToArray();
        var sql = $"UPDATE {QI(table)} SET {string.Join(",", sets)} WHERE {QI(idColumn)}=@id";

        await using var conn = new NpgsqlConnection(_conn);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(sql, conn);
        int i = 0;
        foreach (var kv in data)
            cmd.Parameters.AddWithValue($"@p{i++}", kv.Value ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@id", id);

        return await cmd.ExecuteNonQueryAsync();
    }

    public async Task<int> DeleteByIdAsync(string table, int id, string idColumn = "id")
    {
        var sql = $"DELETE FROM {QI(table)} WHERE {QI(idColumn)}=@id";
        await using var conn = new NpgsqlConnection(_conn);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@id", id);
        return await cmd.ExecuteNonQueryAsync();
    }

    public async Task<List<Dictionary<string, object>>> QueryAsync(
        string table,
        string? where = null,
        IDictionary<string, object>? parameters = null,
        int? limit = null)
    {
        var sb = new StringBuilder($"SELECT * FROM {QI(table)}");
        if (!string.IsNullOrWhiteSpace(where)) sb.Append(" WHERE ").Append(where);
        if (limit is int l) sb.Append(" LIMIT ").Append(l);

        await using var conn = new NpgsqlConnection(_conn);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(sb.ToString(), conn);
        if (parameters is not null)
        {
            foreach (var (k, v) in parameters)
            {
                if (!k.StartsWith("@")) throw new ArgumentException("Parameter keys must start with @");
                cmd.Parameters.AddWithValue(k, v ?? DBNull.Value);
            }
        }

        var result = new List<Dictionary<string, object>>();
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var row = new Dictionary<string, object>(reader.FieldCount, StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < reader.FieldCount; i++)
                row[reader.GetName(i)] = await reader.IsDBNullAsync(i) ? null! : reader.GetValue(i);
            result.Add(row);
        }
        return result;
    }
}
