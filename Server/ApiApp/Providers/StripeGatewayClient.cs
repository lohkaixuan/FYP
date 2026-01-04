// ==================================================
// Program Name   : StripeGatewayClient.cs
// Purpose        : Stripe payment gateway client implementation
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using ApiApp.Models;
using Stripe;
using Stripe.Checkout;
using System.Text.Json;

namespace ApiApp.Providers;

public class StripeGatewayClient : IPaymentGatewayClient
{
    public string Name => "Stripe";

    public Task<JsonElement> CreateCheckoutAsync(
        Provider provider,
        decimal amount,
        string currency,
        string successUrl,
        string cancelUrl)
    {
        StripeConfiguration.ApiKey = provider.PrivateKeyEnc;

        var options = new SessionCreateOptions
        {
            Mode = "payment",
            SuccessUrl = successUrl,
            CancelUrl = cancelUrl,
            LineItems = new List<SessionLineItemOptions>
            {
                new SessionLineItemOptions
                {
                    Quantity = 1,
                    PriceData = new SessionLineItemPriceDataOptions
                    {
                        Currency = currency,
                        UnitAmount = (long)(amount * 100),
                        ProductData = new SessionLineItemPriceDataProductDataOptions
                        {
                            Name = "Wallet Top-Up"
                        }
                    }
                }
            }
        };

        var service = new SessionService();
        var session = service.Create(options);
        var json = JsonSerializer.SerializeToElement(new
        {
            id = session.Id,
            url = session.Url
        });

        return Task.FromResult(json);
    }

    public Task<JsonElement> GetPaymentAsync(Provider provider, string paymentRef)
    {
        StripeConfiguration.ApiKey = provider.PrivateKeyEnc;
        var service = new SessionService();
        var session = service.Get(paymentRef);
        var json = JsonSerializer.SerializeToElement(new
        {
            id = session.Id,
            payment_status = session.PaymentStatus,
            amount_total = session.AmountTotal,
            currency = session.Currency
        });
        return Task.FromResult(json);
    }
}
