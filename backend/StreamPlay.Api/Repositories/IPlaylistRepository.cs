using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public interface IPlaylistRepository
{
    Task<Playlist> CreateAsync(Playlist playlist, CancellationToken ct = default);
    Task<IReadOnlyList<Playlist>> GetForUserAsync(string userId, CancellationToken ct = default);
    Task<Playlist?> GetByIdAsync(string playlistId, CancellationToken ct = default);
    Task UpdateAsync(Playlist playlist, CancellationToken ct = default);
    Task<bool> DeleteAsync(string playlistId, string userId, CancellationToken ct = default);
}

