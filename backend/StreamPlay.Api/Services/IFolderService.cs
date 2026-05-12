using StreamPlay.Api.DTOs.Folders;

namespace StreamPlay.Api.Services;

public interface IFolderService
{
    Task<FolderResponse> CreateAsync(string userId, CreateFolderRequest req, CancellationToken ct = default);
    Task<IReadOnlyList<FolderResponse>> GetForUserAsync(string userId, CancellationToken ct = default);
    Task<FolderResponse> AddPlaylistAsync(string userId, string folderId, string playlistId, CancellationToken ct = default);
    Task<FolderResponse> RemovePlaylistAsync(string userId, string folderId, string playlistId, CancellationToken ct = default);
    Task DeleteAsync(string userId, string folderId, CancellationToken ct = default);
}
