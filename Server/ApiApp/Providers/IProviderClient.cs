// ApiApp/Providers/IProviderClient.cs
namespace ApiApp.Providers;
using ApiApp.Models;   // ✅ add this

public interface IProviderClient
{
    Task<decimal> GetBalanceAsync(BankLink link);
    Task<string>  TransferAsync(BankLink from, string toExternalRef, decimal amount, string? memo=null);
    Task<IReadOnlyList<object>> GetTransactionsAsync(BankLink link, DateTime from, DateTime to);
}
