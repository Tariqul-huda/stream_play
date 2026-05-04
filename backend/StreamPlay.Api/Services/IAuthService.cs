using StreamPlay.Api.DTOs.Auth;

namespace StreamPlay.Api.Services;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest req, CancellationToken ct = default);
    Task<AuthResponse> LoginAsync(LoginRequest req, CancellationToken ct = default);
    Task<SendOtpResponse> SendOtpAsync(SendOtpRequest req, bool isDev, CancellationToken ct = default);
    Task ResetPasswordAsync(ResetPasswordRequest req, CancellationToken ct = default);
}

