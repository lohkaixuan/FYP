// ==================================================
// Program Name   : MockBankClient.cs
// Purpose        : Mock bank provider client for testing
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using ApiApp.Models;

namespace ApiApp.Providers;
using System.Net.Http.Json;
using System.Text.Json;

public class MockBankClient : IProviderClient
{
    public string Name => "MockBank";

    public async Task<LoginResult> LoginAsync(Provider provider, string bankType, string username, string password)
    {
        using var client = new HttpClient { BaseAddress = new Uri(provider.BaseUrl.TrimEnd('/')) };

        var resp = await client.PostAsJsonAsync("/auth/login", new
        {
            bank_type = bankType,
            bank_username = username,
            bank_userpassword = password
        });

        var text = await resp.Content.ReadAsStringAsync();
        if (!resp.IsSuccessStatusCode)
            throw new Exception($"MockBank login failed: {text}");

        var json = JsonSerializer.Deserialize<JsonElement>(text);

        if (!json.TryGetProperty("access_token", out var tokenEl))
            throw new Exception($"MockBank missing access_token. Raw: {text}");
        if (!json.TryGetProperty("bank_account_id", out var idEl))
            throw new Exception($"MockBank missing bank_account_id. Raw: {text}");

        return new LoginResult(
            tokenEl.GetString() ?? "",
            idEl.GetString() ?? "",
            json
        );
    }

    public async Task<JsonElement> GetBalanceAsync(Provider provider, string accessToken)
    {
        using var client = new HttpClient { BaseAddress = new Uri(provider.BaseUrl.TrimEnd('/')) };
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

        var resp = await client.GetAsync("/accounts/balance");
        var text = await resp.Content.ReadAsStringAsync();
        if (!resp.IsSuccessStatusCode) throw new Exception(text);

        return JsonSerializer.Deserialize<JsonElement>(text);
    }

    public async Task<JsonElement> TransferAsync(Provider provider, string accessToken, decimal amount, string? note)
    {
        using var client = new HttpClient { BaseAddress = new Uri(provider.BaseUrl.TrimEnd('/')) };
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

        var resp = await client.PostAsJsonAsync("/payments/transfer", new
        {
            amount = amount,
            note = note ?? "transfer"
        });

        var text = await resp.Content.ReadAsStringAsync();
        if (!resp.IsSuccessStatusCode) throw new Exception(text);

        return JsonSerializer.Deserialize<JsonElement>(text);
    }
}

