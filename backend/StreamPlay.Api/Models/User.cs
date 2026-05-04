using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace StreamPlay.Api.Models;

public sealed class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = default!;

    public string Email { get; set; } = default!;
    public string EmailNormalized { get; set; } = default!;

    public string PasswordHash { get; set; } = default!;

    // Password reset OTP fields (OTP is never stored in plaintext)
    public string? ResetOtpHash { get; set; }
    public DateTime? ResetOtpExpiresAtUtc { get; set; }
    public DateTime? ResetOtpLastSentAtUtc { get; set; }
    public int ResetOtpFailedAttempts { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

