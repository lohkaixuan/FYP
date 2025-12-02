// File: ApiApp/Helpers/AesCryptoService.cs
using System.Security.Cryptography;
using System.Text;

namespace ApiApp.Helpers;

public interface ICryptoService
{
    string Encrypt(string plainText);
    string Decrypt(string cipherText);
}

public class AesCryptoService : ICryptoService
{
    private readonly byte[] _key;

    public AesCryptoService(IConfiguration cfg)
    {
        var secret = cfg["Crypto:AesKey"] 
                     ?? throw new InvalidOperationException("Crypto:AesKey missing");
        // 用 SHA256 把字符串变成 32 bytes key
        _key = SHA256.HashData(Encoding.UTF8.GetBytes(secret));
    }

    public string Encrypt(string plainText)
    {
        if (string.IsNullOrEmpty(plainText)) return string.Empty;

        using var aes = Aes.Create();
        aes.Key = _key;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;
        aes.GenerateIV();

        var iv = aes.IV;
        using var encryptor = aes.CreateEncryptor(aes.Key, iv);
        var plainBytes = Encoding.UTF8.GetBytes(plainText);
        var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

        // 存成 IV:Cipher 的 Base64 字符串
        return $"{Convert.ToBase64String(iv)}:{Convert.ToBase64String(cipherBytes)}";
    }

    public string Decrypt(string cipherText)
    {
        if (string.IsNullOrEmpty(cipherText)) return string.Empty;

        var parts = cipherText.Split(':', 2);
        if (parts.Length != 2) throw new FormatException("Invalid cipher format");

        var iv = Convert.FromBase64String(parts[0]);
        var cipherBytes = Convert.FromBase64String(parts[1]);

        using var aes = Aes.Create();
        aes.Key = _key;
        aes.IV = iv;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        using var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);
        var plainBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);
        return Encoding.UTF8.GetString(plainBytes);
    }
}
