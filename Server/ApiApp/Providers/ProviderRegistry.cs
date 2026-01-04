// ==================================================
// Program Name   : ProviderRegistry.cs
// Purpose        : Registers available provider clients
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
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
