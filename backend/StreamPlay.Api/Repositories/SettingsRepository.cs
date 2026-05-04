using MongoDB.Driver;
using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public sealed class SettingsRepository : ISettingsRepository
{
    private readonly MongoDbContext _db;

    public SettingsRepository(MongoDbContext db)
    {
        _db = db;
    }

    public async Task<UserSettings?> GetForUserAsync(string userId, CancellationToken ct = default)
        => await _db.Settings.Find(x => x.UserId == userId).FirstOrDefaultAsync(ct);

    public async Task<UserSettings> UpsertAsync(UserSettings settings, CancellationToken ct = default)
    {
        var filter = Builders<UserSettings>.Filter.Eq(x => x.UserId, settings.UserId);
        await _db.Settings.ReplaceOneAsync(
            filter,
            settings,
            new ReplaceOptions { IsUpsert = true },
            ct
        );

        // Re-read so we have Id after upsert.
        return await GetForUserAsync(settings.UserId, ct) ?? settings;
    }
}

