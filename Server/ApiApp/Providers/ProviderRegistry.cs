// File: ApiApp/Providers/ProviderRegistry.cs
namespace ApiApp.Providers;

public class ProviderRegistry
{
    private readonly Dictionary<string, IProviderClient> _clients;

    public ProviderRegistry(IEnumerable<IProviderClient> clients)
    {
        _clients = clients.ToDictionary(x => x.Name, StringComparer.OrdinalIgnoreCase);
    }

<<<<<<< HEAD
    public async Task<IProviderClient?> ResolveAsync(Guid providerId)
    {
        var p = await _db.Providers.FirstOrDefaultAsync(x => x.ProviderId == providerId && x.Enabled);
        if (p == null) return null;

        
        return p.Name switch
        {
            "MockBank" => _sp.GetRequiredService<MockBankClient>(),
            _ => null
        };
    }
=======
    public IProviderClient Resolve(string name)
        => _clients.TryGetValue(name, out var c)
            ? c
            : throw new Exception($"No bank provider client registered for '{name}'");
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
}
