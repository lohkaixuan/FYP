// ==================================================
// Program Name   : IProviderClient.cs
// Purpose        : Interface definition for provider clients
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
namespace ApiApp.Providers;
using ApiApp.Models;   // âœ… add this
using System.Text.Json;
public interface IProviderClient
{
    string Name { get; } // "MockBank" / "Stripe" etc.

    Task<LoginResult> LoginAsync(Provider provider, string bankType, string username, string password);
    Task<JsonElement> GetBalanceAsync(Provider provider, string accessToken);
    Task<JsonElement> TransferAsync(Provider provider, string accessToken, decimal amount, string? note);
}

public record LoginResult(string AccessToken, string ExternalAccountId, JsonElement Raw);



