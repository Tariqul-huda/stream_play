using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Playlists;

public sealed class ModifyPlaylistSongRequest
{
    [Required]
    public string MusicId { get; set; } = default!;
}

