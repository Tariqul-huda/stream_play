using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace StreamPlay.Api.Models;

public sealed class Folder
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = default!;

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = default!;

    public string Name { get; set; } = default!;

    [BsonRepresentation(BsonType.ObjectId)]
    public List<string> PlaylistIds { get; set; } = new();

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
