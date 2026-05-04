using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Auth;

public sealed class ResetPasswordRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = default!;

    [Required, RegularExpression(@"^\d{6}$")]
    public string Otp { get; set; } = default!;

    [Required, MinLength(8)]
    public string NewPassword { get; set; } = default!;
}

