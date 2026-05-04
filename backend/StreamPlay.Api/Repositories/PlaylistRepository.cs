using MongoDB.Driver;
using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public sealed class PlaylistRepository : IPlaylistRepository
{
    private readonly MongoDbContext _db;

    public PlaylistRepository(MongoDbContext db)
    {
        _db = db;
    }

    public async Task<Playlist> CreateAsync(Playlist playlist, CancellationToken ct = default)
    {
        await _db.Playlists.InsertOneAsync(playlist, cancellationToken: ct);
        return playlist;
    }

    public async Task<IReadOnlyList<Playlist>> GetForUserAsync(string userId, CancellationToken ct = default)
    {
        return await _db.Playlists.Find(x => x.UserId == userId)
            .SortByDescending(x => x.CreatedAtUtc)
            .ToListAsync(ct);
    }

    public async Task<Playlist?> GetByIdAsync(string playlistId, CancellationToken ct = default)
    {
        return await _db.Playlists.Find(x => x.Id == playlistId)
            .FirstOrDefaultAsync(ct);
    }

    public Task UpdateAsync(Playlist playlist, CancellationToken ct = default)
        => _db.Playlists.ReplaceOneAsync(x => x.Id == playlist.Id, playlist, cancellationToken: ct);

    public async Task<bool> DeleteAsync(string playlistId, string userId, CancellationToken ct = default)
    {
        var res = await _db.Playlists.DeleteOneAsync(x => x.Id == playlistId && x.UserId == userId, ct);
        return res.DeletedCount > 0;
    }
}

