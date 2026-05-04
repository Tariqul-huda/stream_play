using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Auth;

public sealed class RegisterRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = default!;

    [Required, MinLength(8)]
    public string Password { get; set; } = default!;
}

