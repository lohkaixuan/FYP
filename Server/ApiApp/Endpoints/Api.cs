
// Endpoints/Api.cs
using Microsoft.AspNetCore.Builder;
using ApiApp.Services;

namespace ApiApp.Endpoints;

public static class Api
{
    // call this from Program.cs: app.MapApi(port);
    public static void MapApi(this WebApplication app, string port)
    {
        var neonConn = Environment.GetEnvironmentVariable("NEON_CONN")
                        ?? throw new InvalidOperationException("NEON_CONN is not set in environment or .env file.");
       

        // ---- Health ----
        app.MapGet("/healthaefe", () => Results.Ok(new { status = "OK", port }));
    }
}

// keep NoteDto here or in a shared file
public record NoteDto(string Text);
