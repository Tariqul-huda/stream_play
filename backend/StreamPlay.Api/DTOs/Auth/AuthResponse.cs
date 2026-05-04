namespace StreamPlay.Api.DTOs.Auth;

public sealed class AuthResponse
{
    public string AccessToken { get; set; } = default!;
    public int ExpiresInSeconds { get; set; }
    public string UserId { get; set; } = default!;
    public string Email { get; set; } = default!;
}

