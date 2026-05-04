using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Music;

public sealed class CreateMusicRequest
{
    [Required]
    public string Title { get; set; } = default!;

    [Required]
    public string Artist { get; set; } = default!;

    public string? Album { get; set; }
    public string? Genre { get; set; }

    [Required]
    public string FilePath { get; set; } = default!;

    [Range(0, double.MaxValue)]
    public double DurationSeconds { get; set; }

    public string? CoverImage { get; set; }
}

