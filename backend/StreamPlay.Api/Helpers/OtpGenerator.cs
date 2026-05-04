using System.Security.Cryptography;

namespace StreamPlay.Api.Helpers;

public sealed class OtpGenerator : IOtpGenerator
{
    public string Generate6Digits()
    {
        // Cryptographically strong random 6-digit OTP
        var value = RandomNumberGenerator.GetInt32(0, 1_000_000);
        return value.ToString("D6");
    }
}

