using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;

namespace StreamPlay.Api.Helpers;

public static class ClaimsPrincipalExtensions
{
    public static string GetUserId(this ClaimsPrincipal user)
    {
        return user.FindFirstValue("uid")
               ?? user.FindFirstValue(JwtRegisteredClaimNames.Sub)
               ?? throw new ApiException(System.Net.HttpStatusCode.Unauthorized, "Missing user id claim.");
    }
}

