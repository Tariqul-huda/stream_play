using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.DTOs.Auth;
using StreamPlay.Api.Services;

namespace StreamPlay.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    private readonly IWebHostEnvironment _env;

    public AuthController(IAuthService auth, IWebHostEnvironment env)
    {
        _auth = auth;
        _env = env;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest req, CancellationToken ct)
        => Ok(await _auth.RegisterAsync(req, ct));

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest req, CancellationToken ct)
        => Ok(await _auth.LoginAsync(req, ct));

    [HttpPost("send-otp")]
    public async Task<ActionResult<SendOtpResponse>> SendOtp(SendOtpRequest req, CancellationToken ct)
    {
        var isDev = _env.IsDevelopment();
        return Ok(await _auth.SendOtpAsync(req, isDev, ct));
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest req, CancellationToken ct)
    {
        await _auth.ResetPasswordAsync(req, ct);
        return Ok(new { message = "Password updated" });
    }
}

