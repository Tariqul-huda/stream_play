namespace StreamPlay.Api.DTOs.Auth;

public sealed class SendOtpResponse
{
    public string Message { get; set; } = "OTP sent";

    // DEV ONLY: return OTP so you can test UI before email integration.
    public string? DevOtp { get; set; }
}

