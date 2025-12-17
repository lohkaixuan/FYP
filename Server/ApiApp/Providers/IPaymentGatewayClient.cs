using ApiApp.Models;
using System.Text.Json;

namespace ApiApp.Providers;

public interface IPaymentGatewayClient
{
    string Name { get; } // "Stripe", "PayPal", etc.

    Task<JsonElement> CreateCheckoutAsync(Provider provider, decimal amount, string currency, string successUrl, string cancelUrl);
    Task<JsonElement> GetPaymentAsync(Provider provider, string paymentRef);
}
