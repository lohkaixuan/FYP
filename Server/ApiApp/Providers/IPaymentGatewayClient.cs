// ==================================================
// Program Name   : IPaymentGatewayClient.cs
// Purpose        : Interface for payment gateway client implementations
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using ApiApp.Models;
using System.Text.Json;

namespace ApiApp.Providers;

public interface IPaymentGatewayClient
{
    string Name { get; } // "Stripe", "PayPal", etc.

    Task<JsonElement> CreateCheckoutAsync(Provider provider, decimal amount, string currency, string successUrl, string cancelUrl);
    Task<JsonElement> GetPaymentAsync(Provider provider, string paymentRef);
}
