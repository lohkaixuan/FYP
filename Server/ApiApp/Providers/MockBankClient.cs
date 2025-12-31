// File: ApiApp/Providers/MockBankClient.cs
using ApiApp.Models;

namespace ApiApp.Providers;

public class MockBankClient : IProviderClient
{
    private readonly AppDbContext _db;

    public MockBankClient(AppDbContext db)
    {
        _db = db;
    }

    public Task<decimal> GetBalanceAsync(BankLink link)
    {
        
        return Task.FromResult(1000.00m);
    }

    public Task<string> TransferAsync(BankLink from, string toExternalRef, decimal amount, string? memo = null)
    {
        
        return Task.FromResult($"MOCK-TX-{Guid.NewGuid():N}");
    }

    public Task<IReadOnlyList<object>> GetTransactionsAsync(BankLink link, DateTime from, DateTime to)
    {
        
        var list = new List<object> {
            new { ts = DateTime.UtcNow.AddDays(-1), amt = -12.30m, desc = "Mock Coffee" },
            new { ts = DateTime.UtcNow.AddDays(-2), amt = +200.00m, desc = "Mock Topup" }
        };
        return Task.FromResult<IReadOnlyList<object>>(list);
    }
}
