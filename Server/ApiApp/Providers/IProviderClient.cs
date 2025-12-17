// ApiApp/Providers/IProviderClient.cs
namespace ApiApp.Providers;
using ApiApp.Models;   // ✅ add this
using System.Text.Json;
public interface IProviderClient
{
    string Name { get; } // "MockBank" / "Stripe" etc.

    Task<LoginResult> LoginAsync(Provider provider, string bankType, string username, string password);
    Task<JsonElement> GetBalanceAsync(Provider provider, string accessToken);
    Task<JsonElement> TransferAsync(Provider provider, string accessToken, decimal amount, string? note);
}

public record LoginResult(string AccessToken, string ExternalAccountId, JsonElement Raw);
