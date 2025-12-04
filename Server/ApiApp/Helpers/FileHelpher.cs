using Microsoft.AspNetCore.Http;
namespace ApiApp.Helpers;
public static class FileStorage
{
    public static async Task<(string path, long size)> SaveFormFileAsync(
        IWebHostEnvironment env, IFormFile file, string fileNameIfAny = null)
    {
        var (uploads, _) = ResolveUploadRoot(env);
        Directory.CreateDirectory(uploads);

        var safeName = SanitizeFileName(fileNameIfAny ?? Path.GetFileName(file.FileName));
        var uniqueName = EnsureUnique(Path.Combine(uploads, safeName));

        await using (var fs = System.IO.File.Create(uniqueName))
            await file.CopyToAsync(fs);

        var urlPath = $"/uploads/{Path.GetFileName(uniqueName)}";
        return (urlPath, file.Length);
    }

    public static async Task<(string path, long size)> SaveBytesAsync(
        IWebHostEnvironment env, byte[] bytes, string fileName)
    {
        var (uploads, _) = ResolveUploadRoot(env);
        Directory.CreateDirectory(uploads);

        var safeName = SanitizeFileName(fileName);
        var full = EnsureUnique(Path.Combine(uploads, safeName));

        await System.IO.File.WriteAllBytesAsync(full, bytes);
        var urlPath = $"/uploads/{Path.GetFileName(full)}";
        return (urlPath, bytes.LongLength);
    }

    public static (string fullPath, bool exists) Resolve(IWebHostEnvironment env, string urlPath)
    {
        var (_, rootPrefix) = ResolveUploadRoot(env);
        var full = Path.Combine(rootPrefix, urlPath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        return (full, System.IO.File.Exists(full));
    }

    private static (string uploadsPath, string rootPrefix) ResolveUploadRoot(IWebHostEnvironment env)
    {
        var root = !string.IsNullOrWhiteSpace(env.WebRootPath)
            ? env.WebRootPath
            : Path.Combine(env.ContentRootPath ?? Directory.GetCurrentDirectory(), "wwwroot");
        return (Path.Combine(root, "uploads"), root);
    }

    private static string EnsureUnique(string fullPath)
    {
        if (!System.IO.File.Exists(fullPath)) return fullPath;

        var dir = Path.GetDirectoryName(fullPath) ?? "";
        var fileName = Path.GetFileNameWithoutExtension(fullPath);
        var ext = Path.GetExtension(fullPath);
        var counter = 1;
        string candidate;
        do
        {
            candidate = Path.Combine(dir, $"{fileName}_{counter}{ext}");
            counter++;
        } while (System.IO.File.Exists(candidate));

        return candidate;
    }

    private static string SanitizeFileName(string name) =>
        string.IsNullOrWhiteSpace(name) ? $"{Guid.NewGuid():N}" : Path.GetFileName(name);
}
