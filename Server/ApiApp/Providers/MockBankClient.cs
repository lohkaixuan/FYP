// File: ApiApp/Providers/MockBankClient.cs
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

        // safer than GetProperty (won't crash -> can throw cleanly)
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
<<<<<<< HEAD
        
        return Task.FromResult(1000.00m);
=======
        using var client = new HttpClient { BaseAddress = new Uri(provider.BaseUrl.TrimEnd('/')) };
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

        var resp = await client.GetAsync("/accounts/balance");
        var text = await resp.Content.ReadAsStringAsync();
        if (!resp.IsSuccessStatusCode) throw new Exception(text);

        return JsonSerializer.Deserialize<JsonElement>(text);
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
    }

    public async Task<JsonElement> TransferAsync(Provider provider, string accessToken, decimal amount, string? note)
    {
<<<<<<< HEAD
        
        return Task.FromResult($"MOCK-TX-{Guid.NewGuid():N}");
    }

    public Task<IReadOnlyList<object>> GetTransactionsAsync(BankLink link, DateTime from, DateTime to)
    {
        
        var list = new List<object> {
            new { ts = DateTime.UtcNow.AddDays(-1), amt = -12.30m, desc = "Mock Coffee" },
            new { ts = DateTime.UtcNow.AddDays(-2), amt = +200.00m, desc = "Mock Topup" }
        };
        return Task.FromResult<IReadOnlyList<object>>(list);
=======
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
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
    }
}

