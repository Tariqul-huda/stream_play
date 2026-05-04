using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Auth;

public sealed class SendOtpRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = default!;
}

