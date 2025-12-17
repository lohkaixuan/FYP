// File: ApiApp/Providers/PaymentGatewayRegistry.cs
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
