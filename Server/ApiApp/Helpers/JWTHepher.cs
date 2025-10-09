// Helpers/JwtHelper.cs
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace ApiApp.Helpers;

public static class JwtHelper
{
    public static string IssueToken(Guid userId, string jwtKey, TimeSpan? ttl = null)
    {
        var now = DateTime.UtcNow;
        var handler = new JwtSecurityTokenHandler();
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            claims: new[] { new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()) },
            notBefore: now,
            expires: now.Add(ttl ?? TimeSpan.FromHours(2)),
            signingCredentials: creds
        );
        return handler.WriteToken(token);
    }
}
