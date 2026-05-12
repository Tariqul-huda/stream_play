using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Folders;

public sealed class CreateFolderRequest
{
    [Required, MinLength(1), MaxLength(80)]
    public string Name { get; set; } = default!;
}
