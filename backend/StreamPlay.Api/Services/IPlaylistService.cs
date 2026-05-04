using StreamPlay.Api.DTOs.Playlists;

namespace StreamPlay.Api.Services;

public interface IPlaylistService
{
    Task<PlaylistResponse> CreateAsync(string userId, CreatePlaylistRequest req, CancellationToken ct = default);
    Task<IReadOnlyList<PlaylistResponse>> GetForUserAsync(string userId, CancellationToken ct = default);
    Task<PlaylistResponse> AddSongAsync(string userId, string playlistId, string musicId, CancellationToken ct = default);
    Task<PlaylistResponse> RemoveSongAsync(string userId, string playlistId, string musicId, CancellationToken ct = default);
    Task DeleteAsync(string userId, string playlistId, CancellationToken ct = default);
}

