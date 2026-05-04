using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Playlists;

public sealed class CreatePlaylistRequest
{
    [Required, MinLength(1), MaxLength(80)]
    public string Name { get; set; } = default!;
}

