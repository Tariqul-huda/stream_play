using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace StreamPlay.Api.Models;

public sealed class MusicTrack
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = default!;

    public string Title { get; set; } = default!;
    public string TitleNormalized { get; set; } = default!;

    public string Artist { get; set; } = default!;
    public string ArtistNormalized { get; set; } = default!;

    public string? Album { get; set; }

    public string? Genre { get; set; }
    public string? GenreNormalized { get; set; }

    public string FilePath { get; set; } = default!;
    public string FilePathNormalized { get; set; } = default!;

    public double DurationSeconds { get; set; }

    public string? CoverImage { get; set; }

    public DateTime UploadedAtUtc { get; set; } = DateTime.UtcNow;

    public string? FileHashSha256 { get; set; }
}

