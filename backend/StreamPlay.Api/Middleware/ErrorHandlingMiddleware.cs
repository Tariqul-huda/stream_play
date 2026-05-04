using System.Net;
using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.Helpers;

namespace StreamPlay.Api.Middleware;

public sealed class ErrorHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ErrorHandlingMiddleware> _logger;

    public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task Invoke(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ApiException ex)
        {
            context.Response.ContentType = "application/problem+json";
            context.Response.StatusCode = (int)ex.StatusCode;

            var problem = new ProblemDetails
            {
                Status = context.Response.StatusCode,
                Title = "Request failed",
                Detail = ex.Message,
            };

            await context.Response.WriteAsJsonAsync(problem);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception");

            context.Response.ContentType = "application/problem+json";
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

            var problem = new ProblemDetails
            {
                Status = context.Response.StatusCode,
                Title = "Server error",
                Detail = context.RequestServices.GetRequiredService<IHostEnvironment>().IsDevelopment()
                    ? ex.ToString()
                    : "An unexpected error occurred.",
            };

            await context.Response.WriteAsJsonAsync(problem);
        }
    }
}

