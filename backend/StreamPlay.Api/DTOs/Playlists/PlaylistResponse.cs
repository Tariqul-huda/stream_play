namespace StreamPlay.Api.DTOs.Playlists;

public sealed class PlaylistResponse
{
    public string Id { get; set; } = default!;
    public string Name { get; set; } = default!;
    public List<string> MusicIds { get; set; } = new();
    public DateTime CreatedAtUtc { get; set; }
}

