using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Music;

public sealed class AddLabelRequest
{
    [Required, MinLength(1), MaxLength(80)]
    public string Label { get; set; } = default!;
}
