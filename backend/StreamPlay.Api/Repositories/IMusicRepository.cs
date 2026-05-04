using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public interface IMusicRepository
{
    Task<MusicTrack> CreateAsync(MusicTrack track, CancellationToken ct = default);
    Task<(IReadOnlyList<MusicTrack> Items, long Total)> GetPagedAsync(int page, int pageSize, CancellationToken ct = default);
    Task<IReadOnlyList<MusicTrack>> GetByGenreAsync(string genreNormalized, CancellationToken ct = default);
    Task<IReadOnlyList<MusicTrack>> SearchAsync(string qNormalized, int limit, CancellationToken ct = default);
    Task<bool> DeleteAsync(string id, CancellationToken ct = default);
    Task<bool> ExistsByFilePathAsync(string filePathNormalized, CancellationToken ct = default);
}

