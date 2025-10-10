// Helpers/ResponseHelpher.cs  (keep filename if you prefer)
// If you want to fix the typo, rename the file/class to ResponseHelper everywhere.
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace ApiApp.Helpers;

public record ApiResponse<T>(int code, bool success, string message, T? data);

public static class ResponseHelper
{
    /* ===============================
       ✅ SUCCESS (2xx)
       =============================== */
    public static IResult Ok<T>(T? data, string message = "OK") => // 200
        Results.Json(new ApiResponse<T>(StatusCodes.Status200OK, true, message, data),
                     statusCode: StatusCodes.Status200OK);

    // 201 — overload WITH location header (matches Api.cs usage)
    public static IResult Created<T>(string location, T? data, string message = "Created") =>
        Results.Created(location, new ApiResponse<T>(
            StatusCodes.Status201Created, true, message, data));


    // 201 — overload WITHOUT location header
    public static IResult Created<T>(T? data, string message = "Created") =>
        Results.Json(new ApiResponse<T>(StatusCodes.Status201Created, true, message, data),
                     statusCode: StatusCodes.Status201Created);

    public static IResult NoContent(string message = "No content") => // 204
        Results.Json(new ApiResponse<object?>(StatusCodes.Status204NoContent, true, message, null),
                     statusCode: StatusCodes.Status204NoContent);

    /* ===============================
       ⚠️ CLIENT ERRORS (4xx)
       =============================== */
    public static IResult BadRequest(string message = "Bad request") => // 400
        Results.Json(new ApiResponse<object?>(StatusCodes.Status400BadRequest, false, message, null),
                     statusCode: StatusCodes.Status400BadRequest);

    public static IResult Unauthorized(string message = "Unauthorized") => // 401
        Results.Json(new ApiResponse<object?>(StatusCodes.Status401Unauthorized, false, message, null),
                     statusCode: StatusCodes.Status401Unauthorized);

    public static IResult Forbidden(string message = "Forbidden") => // 403
        Results.Json(new ApiResponse<object?>(StatusCodes.Status403Forbidden, false, message, null),
                     statusCode: StatusCodes.Status403Forbidden);

    public static IResult NotFound(string message = "Not found") => // 404
        Results.Json(new ApiResponse<object?>(StatusCodes.Status404NotFound, false, message, null),
                     statusCode: StatusCodes.Status404NotFound);

    public static IResult RequestTimeout(string message = "Request timeout") => // 408
        Results.Json(new ApiResponse<object?>(StatusCodes.Status408RequestTimeout, false, message, null),
                     statusCode: StatusCodes.Status408RequestTimeout);

    /* ===============================
       💥 SERVER ERRORS (5xx)
       =============================== */
    public static IResult ServerError(string message = "Server error") => // 500
        Results.Json(new ApiResponse<object?>(StatusCodes.Status500InternalServerError, false, message, null),
                     statusCode: StatusCodes.Status500InternalServerError);

    public static IResult GatewayTimeout(string message = "Gateway timeout") => // 504
        Results.Json(new ApiResponse<object?>(StatusCodes.Status504GatewayTimeout, false, message, null),
                     statusCode: StatusCodes.Status504GatewayTimeout);

    /* ===============================
       🎯 Controller-friendly
       =============================== */
    public static IActionResult OkResult<T>(ControllerBase c, T? data, string message = "OK") =>
        c.Ok(new ApiResponse<T>(StatusCodes.Status200OK, true, message, data));
}
