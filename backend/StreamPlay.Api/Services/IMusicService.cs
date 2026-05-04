using StreamPlay.Api.DTOs.Common;
using StreamPlay.Api.DTOs.Music;

namespace StreamPlay.Api.Services;

public interface IMusicService
{
    Task<MusicResponse> CreateAsync(CreateMusicRequest req, CancellationToken ct = default);
    Task<PagedResponse<MusicResponse>> GetPagedAsync(int page, int pageSize, CancellationToken ct = default);
    Task<IReadOnlyList<MusicResponse>> GetByGenreAsync(string genre, CancellationToken ct = default);
    Task<IReadOnlyList<MusicResponse>> SearchAsync(string q, CancellationToken ct = default);
    Task DeleteAsync(string id, CancellationToken ct = default);
}

