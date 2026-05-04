using Microsoft.Extensions.Options;
using MongoDB.Driver;
using StreamPlay.Api.Config;
using StreamPlay.Api.Models;

namespace StreamPlay.Api;

public sealed class MongoDbContext
{
    private readonly IMongoDatabase _db;

    public MongoDbContext(IMongoClient client, IOptions<MongoDbSettings> options)
    {
        var settings = options.Value;
        _db = client.GetDatabase(settings.DatabaseName);
    }

    public IMongoCollection<User> Users => _db.GetCollection<User>("users");
    public IMongoCollection<MusicTrack> Music => _db.GetCollection<MusicTrack>("music");
    public IMongoCollection<Playlist> Playlists => _db.GetCollection<Playlist>("playlists");
    public IMongoCollection<UserSettings> Settings => _db.GetCollection<UserSettings>("settings");

    public async Task EnsureIndexesAsync()
    {
        // Users: unique email
        await Users.Indexes.CreateOneAsync(
            new CreateIndexModel<User>(
                Builders<User>.IndexKeys.Ascending(x => x.EmailNormalized),
                new CreateIndexOptions { Unique = true, Name = "uniq_email" }
            )
        );

        // Music: search indexes + unique file path
        await Music.Indexes.CreateManyAsync(new[]
        {
            new CreateIndexModel<MusicTrack>(
                Builders<MusicTrack>.IndexKeys.Ascending(x => x.GenreNormalized),
                new CreateIndexOptions { Name = "idx_genre" }
            ),
            new CreateIndexModel<MusicTrack>(
                Builders<MusicTrack>.IndexKeys.Ascending(x => x.TitleNormalized),
                new CreateIndexOptions { Name = "idx_title" }
            ),
            new CreateIndexModel<MusicTrack>(
                Builders<MusicTrack>.IndexKeys.Ascending(x => x.ArtistNormalized),
                new CreateIndexOptions { Name = "idx_artist" }
            ),
            new CreateIndexModel<MusicTrack>(
                Builders<MusicTrack>.IndexKeys.Ascending(x => x.FilePathNormalized),
                new CreateIndexOptions { Unique = true, Name = "uniq_filepath" }
            )
        });

        // Playlists: user lookup
        await Playlists.Indexes.CreateOneAsync(
            new CreateIndexModel<Playlist>(
                Builders<Playlist>.IndexKeys.Ascending(x => x.UserId),
                new CreateIndexOptions { Name = "idx_playlist_user" }
            )
        );

        // Settings: unique per user
        await Settings.Indexes.CreateOneAsync(
            new CreateIndexModel<UserSettings>(
                Builders<UserSettings>.IndexKeys.Ascending(x => x.UserId),
                new CreateIndexOptions { Unique = true, Name = "uniq_settings_user" }
            )
        );
    }
}

