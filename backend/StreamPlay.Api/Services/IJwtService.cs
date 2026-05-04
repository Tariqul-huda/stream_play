using StreamPlay.Api.DTOs.Auth;
using StreamPlay.Api.Models;

namespace StreamPlay.Api.Services;

public interface IJwtService
{
    AuthResponse CreateToken(User user);
}

