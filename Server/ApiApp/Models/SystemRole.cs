namespace ApiApp.Models;

public static class SystemRoles
{
    public static readonly Guid Admin        = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-000000000001");
    public static readonly Guid BankProvider = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-000000000002");
    public static readonly Guid Merchant     = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-000000000003");
    public static readonly Guid User         = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-000000000004");
}
