using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace StreamPlay.Api.Models;

public sealed class Playlist
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = default!;

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = default!;

    public string Name { get; set; } = default!;

    [BsonRepresentation(BsonType.ObjectId)]
    public List<string> MusicIds { get; set; } = new();

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

