namespace StreamPlay.Api.Helpers;

public interface IFileHasher
{
    Task<string> Sha256Async(string path, CancellationToken ct = default);
}

