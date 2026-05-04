using MongoDB.Driver;
using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public sealed class MusicRepository : IMusicRepository
{
    private readonly MongoDbContext _db;

    public MusicRepository(MongoDbContext db)
    {
        _db = db;
    }

    public async Task<MusicTrack> CreateAsync(MusicTrack track, CancellationToken ct = default)
    {
        await _db.Music.InsertOneAsync(track, cancellationToken: ct);
        return track;
    }

    public async Task<(IReadOnlyList<MusicTrack> Items, long Total)> GetPagedAsync(int page, int pageSize, CancellationToken ct = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100;

        var filter = Builders<MusicTrack>.Filter.Empty;
        var total = await _db.Music.CountDocumentsAsync(filter, cancellationToken: ct);
        var items = await _db.Music.Find(filter)
            .SortByDescending(x => x.UploadedAtUtc)
            .Skip((page - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync(ct);
        return (items, total);
    }

    public async Task<IReadOnlyList<MusicTrack>> GetByGenreAsync(string genreNormalized, CancellationToken ct = default)
    {
        return await _db.Music.Find(x => x.GenreNormalized == genreNormalized)
            .SortByDescending(x => x.UploadedAtUtc)
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<MusicTrack>> SearchAsync(string qNormalized, int limit, CancellationToken ct = default)
    {
        if (limit < 1) limit = 20;
        if (limit > 100) limit = 100;

        // Simple prefix-ish search using normalized fields.
        var filter = Builders<MusicTrack>.Filter.Or(
            Builders<MusicTrack>.Filter.Regex(x => x.TitleNormalized, new MongoDB.Bson.BsonRegularExpression(qNormalized)),
            Builders<MusicTrack>.Filter.Regex(x => x.ArtistNormalized, new MongoDB.Bson.BsonRegularExpression(qNormalized))
        );

        return await _db.Music.Find(filter)
            .Limit(limit)
            .ToListAsync(ct);
    }

    public async Task<bool> DeleteAsync(string id, CancellationToken ct = default)
    {
        var res = await _db.Music.DeleteOneAsync(x => x.Id == id, ct);
        return res.DeletedCount > 0;
    }

    public async Task<bool> ExistsByFilePathAsync(string filePathNormalized, CancellationToken ct = default)
    {
        var count = await _db.Music.CountDocumentsAsync(x => x.FilePathNormalized == filePathNormalized, cancellationToken: ct);
        return count > 0;
    }
}

