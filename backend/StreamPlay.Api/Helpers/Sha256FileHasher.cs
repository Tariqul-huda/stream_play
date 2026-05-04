using System.Security.Cryptography;

namespace StreamPlay.Api.Helpers;

public sealed class Sha256FileHasher : IFileHasher
{
    public async Task<string> Sha256Async(string path, CancellationToken ct = default)
    {
        await using var stream = File.OpenRead(path);
        using var sha = SHA256.Create();
        var hash = await sha.ComputeHashAsync(stream, ct);
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}

