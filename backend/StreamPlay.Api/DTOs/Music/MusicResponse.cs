namespace StreamPlay.Api.DTOs.Music;

public sealed class MusicResponse
{
    public string Id { get; set; } = default!;
    public string Title { get; set; } = default!;
    public string Artist { get; set; } = default!;
    public string? Album { get; set; }
    public string? Genre { get; set; }
    public string FilePath { get; set; } = default!;
    public double DurationSeconds { get; set; }
    public string? CoverImage { get; set; }
    public DateTime UploadedAtUtc { get; set; }
}

