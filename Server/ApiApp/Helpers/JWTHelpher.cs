// Helpers/JwtHelper.cs
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace ApiApp.Helpers;
// Helpers/JwtHelper.cs
public static class JwtToken
{
    public static string Issue(
        Guid userId,
        string userName,
        string roleName,
        string key,
        TimeSpan ttl,
        IDictionary<string, string>? extraClaims = null   
    )
    {
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Name, userName ?? string.Empty),
            new Claim(ClaimTypes.Role, roleName ?? "user")
        };

        
        if (extraClaims != null)
        {
            foreach (var kv in extraClaims)
            {
                if (!string.IsNullOrWhiteSpace(kv.Key) && kv.Value is not null)
                    claims.Add(new Claim(kv.Key, kv.Value));
            }
        }

        var creds = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
            SecurityAlgorithms.HmacSha256);

        var jwt = new JwtSecurityToken(
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.Add(ttl),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(jwt);
    }
}
