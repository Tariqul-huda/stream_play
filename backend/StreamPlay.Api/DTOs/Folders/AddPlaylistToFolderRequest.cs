using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Folders;

public sealed class AddPlaylistToFolderRequest
{
    [Required]
    public string PlaylistId { get; set; } = default!;
}
