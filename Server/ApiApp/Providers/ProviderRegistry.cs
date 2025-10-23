// File: ApiApp/Providers/ProviderRegistry.cs
using ApiApp.Models;
using Microsoft.EntityFrameworkCore;
using ApiApp.Providers;
namespace ApiApp.Providers;

public class ProviderRegistry
{
    private readonly AppDbContext _db;
    private readonly IServiceProvider _sp;

    public ProviderRegistry(AppDbContext db, IServiceProvider sp)
    {
        _db = db; _sp = sp;
    }

    public async Task<IProviderClient?> ResolveAsync(Guid providerId)
    {
        var p = await _db.Providers.FirstOrDefaultAsync(x => x.ProviderId == providerId && x.Enabled);
        if (p == null) return null;

        // 简单路由：按名称匹配；后续可改为配置映射或反射
        return p.Name switch
        {
            "MockBank" => _sp.GetRequiredService<MockBankClient>(),
            _ => null
        };
    }
}
