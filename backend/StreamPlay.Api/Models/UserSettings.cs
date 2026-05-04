using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace StreamPlay.Api.Models;

public sealed class UserSettings
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = default!;

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = default!;

    public string? PreferredMusicFolderPath { get; set; }
    public string? Theme { get; set; }
}

