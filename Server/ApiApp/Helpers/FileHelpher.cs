using Microsoft.AspNetCore.Http;
namespace ApiApp.Helpers;
public static class FileStorage
{
    public static async Task<(string path, long size)> SaveFormFileAsync(
        IWebHostEnvironment env, IFormFile file, string fileNameIfAny = null)
    {
        var root = env.WebRootPath ?? "wwwroot";
        var uploads = Path.Combine(root, "uploads");
        Directory.CreateDirectory(uploads);
var safeName = fileNameIfAny ?? Path.GetFileName(file.FileName);
        var full = Path.Combine(uploads, safeName);
        await using (var fs = System.IO.File.Create(full))
            await file.CopyToAsync(fs);
var urlPath = $"/uploads/{safeName}";
        return (urlPath, file.Length);
    }
public static async Task<(string path, long size)> SaveBytesAsync(
        IWebHostEnvironment env, byte[] bytes, string fileName)
    {
        var root = env.WebRootPath ?? "wwwroot";
        var uploads = Path.Combine(root, "uploads");
        Directory.CreateDirectory(uploads);
var full = Path.Combine(uploads, fileName);
        await System.IO.File.WriteAllBytesAsync(full, bytes);
var urlPath = $"/uploads/{fileName}";
        return (urlPath, bytes.LongLength);
    }
public static (string fullPath, bool exists) Resolve(IWebHostEnvironment env, string urlPath)
    {
        var root = env.WebRootPath ?? "wwwroot";
        var full = Path.Combine(root, urlPath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        return (full, System.IO.File.Exists(full));
    }
}

