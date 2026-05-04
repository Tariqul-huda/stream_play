using System.Net;
using StreamPlay.Api.DTOs.Auth;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Models;
using StreamPlay.Api.Repositories;

namespace StreamPlay.Api.Services;

public sealed class AuthService : IAuthService
{
    private static readonly TimeSpan OtpTtl = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan OtpMinResend = TimeSpan.FromSeconds(30);
    private const int OtpMaxFailedAttempts = 5;

    private readonly IUserRepository _users;
    private readonly IPasswordHasher _hasher;
    private readonly IOtpGenerator _otp;
    private readonly IJwtService _jwt;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IUserRepository users,
        IPasswordHasher hasher,
        IOtpGenerator otp,
        IJwtService jwt,
        ILogger<AuthService> logger)
    {
        _users = users;
        _hasher = hasher;
        _otp = otp;
        _jwt = jwt;
        _logger = logger;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest req, CancellationToken ct = default)
    {
        var email = req.Email.Trim();
        var emailNorm = Normalization.Norm(email);

        var existing = await _users.GetByEmailNormalizedAsync(emailNorm, ct);
        if (existing is not null)
            throw new ApiException(HttpStatusCode.Conflict, "Email already registered.");

        var user = new User
        {
            Email = email,
            EmailNormalized = emailNorm,
            PasswordHash = _hasher.Hash(req.Password),
            CreatedAtUtc = DateTime.UtcNow,
        };

        await _users.CreateAsync(user, ct);
        return _jwt.CreateToken(user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req, CancellationToken ct = default)
    {
        var emailNorm = Normalization.Norm(req.Email);
        var user = await _users.GetByEmailNormalizedAsync(emailNorm, ct);
        if (user is null)
            throw new ApiException(HttpStatusCode.Unauthorized, "Invalid email or password.");

        if (!_hasher.Verify(req.Password, user.PasswordHash))
            throw new ApiException(HttpStatusCode.Unauthorized, "Invalid email or password.");

        return _jwt.CreateToken(user);
    }

    public async Task<SendOtpResponse> SendOtpAsync(SendOtpRequest req, bool isDev, CancellationToken ct = default)
    {
        var emailNorm = Normalization.Norm(req.Email);
        var user = await _users.GetByEmailNormalizedAsync(emailNorm, ct);

        // Prevent account enumeration: behave the same if user not found.
        if (user is null)
        {
            await Task.Delay(200, ct);
            return new SendOtpResponse { Message = "OTP sent" };
        }

        var now = DateTime.UtcNow;
        if (user.ResetOtpLastSentAtUtc is not null && now - user.ResetOtpLastSentAtUtc.Value < OtpMinResend)
            throw new ApiException(HttpStatusCode.TooManyRequests, "Please wait before requesting another OTP.");

        var otp = _otp.Generate6Digits();
        user.ResetOtpHash = _hasher.Hash(otp);
        user.ResetOtpExpiresAtUtc = now.Add(OtpTtl);
        user.ResetOtpLastSentAtUtc = now;
        user.ResetOtpFailedAttempts = 0;

        await _users.UpdateAsync(user, ct);

        // TODO: integrate email sending (SendGrid/SMTP/etc.). For now we only log.
        _logger.LogInformation("Password reset OTP generated for {Email}. (DEV: {Otp})", user.Email, otp);

        return new SendOtpResponse
        {
            Message = "OTP sent",
            DevOtp = isDev ? otp : null,
        };
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest req, CancellationToken ct = default)
    {
        var emailNorm = Normalization.Norm(req.Email);
        var user = await _users.GetByEmailNormalizedAsync(emailNorm, ct);

        // Same anti-enumeration strategy.
        if (user is null)
            throw new ApiException(HttpStatusCode.BadRequest, "Invalid OTP or expired OTP.");

        if (user.ResetOtpExpiresAtUtc is null || user.ResetOtpHash is null)
            throw new ApiException(HttpStatusCode.BadRequest, "Invalid OTP or expired OTP.");

        if (DateTime.UtcNow > user.ResetOtpExpiresAtUtc.Value)
            throw new ApiException(HttpStatusCode.BadRequest, "Invalid OTP or expired OTP.");

        if (user.ResetOtpFailedAttempts >= OtpMaxFailedAttempts)
            throw new ApiException(HttpStatusCode.TooManyRequests, "Too many failed attempts. Request a new OTP.");

        if (!_hasher.Verify(req.Otp, user.ResetOtpHash))
        {
            user.ResetOtpFailedAttempts += 1;
            await _users.UpdateAsync(user, ct);
            throw new ApiException(HttpStatusCode.BadRequest, "Invalid OTP or expired OTP.");
        }

        user.PasswordHash = _hasher.Hash(req.NewPassword);
        user.ResetOtpHash = null;
        user.ResetOtpExpiresAtUtc = null;
        user.ResetOtpLastSentAtUtc = null;
        user.ResetOtpFailedAttempts = 0;

        await _users.UpdateAsync(user, ct);
    }
}

