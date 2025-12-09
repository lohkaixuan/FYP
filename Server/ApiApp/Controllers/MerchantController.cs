// File: ApiApp/Controllers/MerchantController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ApiApp.Models;
using ApiApp.Helpers;

namespace ApiApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MerchantController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IWebHostEnvironment _env;

    public MerchantController(AppDbContext db, IWebHostEnvironment env)
    {
        _db = db;
        _env = env;
    }

    
    [Authorize(Roles = "admin")]
    [HttpGet("{merchantId:guid}/doc")]
    public async Task<IResult> GetMerchantDoc(Guid merchantId)
    {
        var merchant = await _db.Merchants.AsNoTracking()
            .FirstOrDefaultAsync(m => m.MerchantId == merchantId);

        if (merchant is null)
            return Results.NotFound(new { message = "merchant not found" });

        
        if (merchant.MerchantDocBytes is not null && merchant.MerchantDocBytes.Length > 0)
        {
            var contentType = string.IsNullOrWhiteSpace(merchant.MerchantDocContentType)
                ? "application/octet-stream"
                : merchant.MerchantDocContentType;

            var downloadName = string.IsNullOrWhiteSpace(merchant.MerchantName)
                ? "merchant-document"
                : $"{merchant.MerchantName}-document";

            
            if (contentType.Equals("application/pdf", StringComparison.OrdinalIgnoreCase))
                downloadName += ".pdf";

            return Results.File(merchant.MerchantDocBytes, contentType, downloadName);
        }

        
        if (!string.IsNullOrWhiteSpace(merchant.MerchantDocUrl))
        {
            var (fullPath, exists) = FileStorage.Resolve(_env, merchant.MerchantDocUrl);
            if (!exists)
                return Results.NotFound(new { message = "file not found on disk" });

            var bytes = await System.IO.File.ReadAllBytesAsync(fullPath);
            var contentType = string.IsNullOrWhiteSpace(merchant.MerchantDocContentType)
                ? "application/octet-stream"
                : merchant.MerchantDocContentType;

            var downloadName = Path.GetFileName(fullPath);
            return Results.File(bytes, contentType, downloadName);
        }

        
        return Results.NotFound(new { message = "merchant has no document" });
    }
}
