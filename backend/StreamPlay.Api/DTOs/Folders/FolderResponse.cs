namespace StreamPlay.Api.DTOs.Folders;

public sealed class FolderResponse
{
    public string Id { get; set; } = default!;
    public string Name { get; set; } = default!;
    public List<string> PlaylistIds { get; set; } = new();
    public DateTime CreatedAtUtc { get; set; }
}
