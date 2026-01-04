// ==================================================
// Program Name   : JWTHelpher.cs
// Purpose        : JWT token creation and validation helpers
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
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
