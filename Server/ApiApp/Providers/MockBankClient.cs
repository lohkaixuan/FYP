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
        // Demo: 返回固定余额；你也可以映射到本地 BankAccount/Wallet 做模拟
        return Task.FromResult(1000.00m);
    }

    public Task<string> TransferAsync(BankLink from, string toExternalRef, decimal amount, string? memo = null)
    {
        // Demo: 返回一个成功的reference
        return Task.FromResult($"MOCK-TX-{Guid.NewGuid():N}");
    }

    public Task<IReadOnlyList<object>> GetTransactionsAsync(BankLink link, DateTime from, DateTime to)
    {
        // Demo: 返回两条假交易
        var list = new List<object> {
            new { ts = DateTime.UtcNow.AddDays(-1), amt = -12.30m, desc = "Mock Coffee" },
            new { ts = DateTime.UtcNow.AddDays(-2), amt = +200.00m, desc = "Mock Topup" }
        };
        return Task.FromResult<IReadOnlyList<object>>(list);
    }
}
