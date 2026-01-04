// ==================================================
// Program Name   : NeonHelpher.cs
// Purpose        : Utilities for Neon payment integrations
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using Npgsql;
using System.Text;
using System.Text.RegularExpressions;

namespace ApiApp.Helpers;

// Simple Neon-like interface: Add / Read / Update / Delete
public interface INeonCrud
{
    Task<int> Add(string table, IDictionary<string, object> data);
    Task<List<Dictionary<string, object>>> Read(
        string table,
        string? where = null,
        IDictionary<string, object>? parameters = null,
        int? limit = null);
    Task<int> Update(string table, object id, IDictionary<string, object> data, string idColumn = "id");
    Task<int> Delete(string table, object id, string idColumn = "id");
}

public class NeonHelper : INeonCrud
{
    private readonly string _conn;

    public NeonHelper(string connectionString) => _conn = connectionString;
    private static readonly Regex Ident = new(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);
    private static string QI(string name)
    {
        if (!Ident.IsMatch(name)) throw new ArgumentException($"Invalid identifier: {name}");
        return $"\"{name}\"";
    }

    public async Task<int> Add(string table, IDictionary<string, object> data)
    {
        if (data.Count == 0) throw new ArgumentException("No columns provided");
        var cols = data.Keys.Select(QI).ToArray();
        var paramNames = data.Keys.Select((_, i) => $"@p{i}").ToArray();
        var sql = $"INSERT INTO {QI(table)} ({string.Join(",", cols)}) VALUES ({string.Join(",", paramNames)})";
        await using var conn = new NpgsqlConnection(_conn);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand(sql, conn);
        int i = 0;
        foreach (var kv in data)
            cmd.Parameters.AddWithValue(paramNames[i++], kv.Value ?? DBNull.Value);
        return await cmd.ExecuteNonQueryAsync();
    }

    public async Task<List<Dictionary<string, object>>> Read(
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
        var result = new List<Dictionary<string, object>>(capacity: 64);
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

    public async Task<int> Update(string table, object id, IDictionary<string, object> data, string idColumn = "id")
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

    public async Task<int> Delete(string table, object id, string idColumn = "id")
    {
        var sql = $"DELETE FROM {QI(table)} WHERE {QI(idColumn)}=@id";
        await using var conn = new NpgsqlConnection(_conn);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@id", id);
        return await cmd.ExecuteNonQueryAsync();
    }
}
