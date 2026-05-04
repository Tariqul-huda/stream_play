using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Auth;

public sealed class LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = default!;

    [Required]
    public string Password { get; set; } = default!;
}

