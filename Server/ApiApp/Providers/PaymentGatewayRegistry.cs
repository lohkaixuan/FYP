// ==================================================
// Program Name   : PaymentGatewayRegistry.cs
// Purpose        : Registers available payment gateway clients
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
namespace ApiApp.Providers;

public class PaymentGatewayRegistry
{
    private readonly Dictionary<string, IPaymentGatewayClient> _clients;

    public PaymentGatewayRegistry(IEnumerable<IPaymentGatewayClient> clients)
    {
        _clients = clients.ToDictionary(x => x.Name, StringComparer.OrdinalIgnoreCase);
    }

    public IPaymentGatewayClient Resolve(string name)
        => _clients.TryGetValue(name, out var c)
            ? c
            : throw new Exception($"No payment gateway client registered for '{name}'");
}
