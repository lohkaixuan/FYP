// File: ApiApp/Providers/ProviderRegistry.cs
namespace ApiApp.Providers;

public class ProviderRegistry
{
    private readonly Dictionary<string, IProviderClient> _clients;

    public ProviderRegistry(IEnumerable<IProviderClient> clients)
    {
        _clients = clients.ToDictionary(x => x.Name, StringComparer.OrdinalIgnoreCase);
    }

    public IProviderClient Resolve(string name)
        => _clients.TryGetValue(name, out var c)
            ? c
            : throw new Exception($"No bank provider client registered for '{name}'");
}
