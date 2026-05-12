using System.Net;
using StreamPlay.Api.DTOs.Folders;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Models;
using StreamPlay.Api.Repositories;

namespace StreamPlay.Api.Services;

public sealed class FolderService : IFolderService
{
    private readonly IFolderRepository _folders;

    public FolderService(IFolderRepository folders)
    {
        _folders = folders;
    }

    public async Task<FolderResponse> CreateAsync(string userId, CreateFolderRequest req, CancellationToken ct = default)
    {
        var folder = new Folder
        {
            UserId = userId,
            Name = req.Name.Trim(),
            PlaylistIds = new List<string>(),
            CreatedAtUtc = DateTime.UtcNow,
        };

        await _folders.CreateAsync(folder, ct);
        return Map(folder);
    }

    public async Task<IReadOnlyList<FolderResponse>> GetForUserAsync(string userId, CancellationToken ct = default)
    {
        var items = await _folders.GetForUserAsync(userId, ct);
        return items.Select(Map).ToList();
    }

    public async Task<FolderResponse> AddPlaylistAsync(string userId, string folderId, string playlistId, CancellationToken ct = default)
    {
        var folder = await RequireOwnedFolderAsync(userId, folderId, ct);
        if (!folder.PlaylistIds.Contains(playlistId))
        {
            folder.PlaylistIds.Add(playlistId);
            await _folders.UpdateAsync(folder, ct);
        }
        return Map(folder);
    }

    public async Task<FolderResponse> RemovePlaylistAsync(string userId, string folderId, string playlistId, CancellationToken ct = default)
    {
        var folder = await RequireOwnedFolderAsync(userId, folderId, ct);
        folder.PlaylistIds.RemoveAll(x => x == playlistId);
        await _folders.UpdateAsync(folder, ct);
        return Map(folder);
    }

    public async Task DeleteAsync(string userId, string folderId, CancellationToken ct = default)
    {
        var ok = await _folders.DeleteAsync(folderId, userId, ct);
        if (!ok) throw new ApiException(HttpStatusCode.NotFound, "Folder not found.");
    }

    private async Task<Folder> RequireOwnedFolderAsync(string userId, string folderId, CancellationToken ct)
    {
        var folder = await _folders.GetByIdAsync(folderId, ct);
        if (folder is null) throw new ApiException(HttpStatusCode.NotFound, "Folder not found.");
        if (folder.UserId != userId) throw new ApiException(HttpStatusCode.Forbidden, "Forbidden.");
        return folder;
    }

    private static FolderResponse Map(Folder x) => new()
    {
        Id = x.Id,
        Name = x.Name,
        PlaylistIds = x.PlaylistIds,
        CreatedAtUtc = x.CreatedAtUtc,
    };
}
