using System.Net;
using StreamPlay.Api.DTOs.Common;
using StreamPlay.Api.DTOs.Music;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Models;
using StreamPlay.Api.Repositories;

namespace StreamPlay.Api.Services;

public sealed class MusicService : IMusicService
{
    private readonly IMusicRepository _music;

    public MusicService(IMusicRepository music)
    {
        _music = music;
    }

    public async Task<MusicResponse> CreateAsync(CreateMusicRequest req, CancellationToken ct = default)
    {
        var filePathNorm = Normalization.Norm(req.FilePath);
        if (await _music.ExistsByFilePathAsync(filePathNorm, ct))
            throw new ApiException(HttpStatusCode.Conflict, "Music already exists for this file path.");

        var track = new MusicTrack
        {
            Title = req.Title.Trim(),
            TitleNormalized = Normalization.Norm(req.Title),
            Artist = req.Artist.Trim(),
            ArtistNormalized = Normalization.Norm(req.Artist),
            Album = string.IsNullOrWhiteSpace(req.Album) ? null : req.Album.Trim(),
            Genre = string.IsNullOrWhiteSpace(req.Genre) ? null : req.Genre.Trim(),
            GenreNormalized = string.IsNullOrWhiteSpace(req.Genre) ? null : Normalization.Norm(req.Genre),
            FilePath = req.FilePath.Trim(),
            FilePathNormalized = filePathNorm,
            DurationSeconds = req.DurationSeconds,
            CoverImage = req.CoverImage,
            UploadedAtUtc = DateTime.UtcNow,
        };

        await _music.CreateAsync(track, ct);
        return Map(track);
    }

    public async Task<PagedResponse<MusicResponse>> GetPagedAsync(int page, int pageSize, CancellationToken ct = default)
    {
        var (items, total) = await _music.GetPagedAsync(page, pageSize, ct);
        return new PagedResponse<MusicResponse>
        {
            Items = items.Select(Map).ToList(),
            Total = total,
            Page = page < 1 ? 1 : page,
            PageSize = pageSize < 1 ? 20 : Math.Min(pageSize, 100),
        };
    }

    public async Task<IReadOnlyList<MusicResponse>> GetByGenreAsync(string genre, CancellationToken ct = default)
    {
        var items = await _music.GetByGenreAsync(Normalization.Norm(genre), ct);
        return items.Select(Map).ToList();
    }

    public async Task<IReadOnlyList<MusicResponse>> SearchAsync(string q, CancellationToken ct = default)
    {
        var query = Normalization.Norm(q);
        if (query.Length < 2) return Array.Empty<MusicResponse>();

        // For regex, keep it simple: escape special chars.
        var safe = System.Text.RegularExpressions.Regex.Escape(query);
        var items = await _music.SearchAsync(safe, limit: 50, ct);
        return items.Select(Map).ToList();
    }

    public async Task DeleteAsync(string id, CancellationToken ct = default)
    {
        var ok = await _music.DeleteAsync(id, ct);
        if (!ok) throw new ApiException(HttpStatusCode.NotFound, "Music not found.");
    }

    private static MusicResponse Map(MusicTrack x) => new()
    {
        Id = x.Id,
        Title = x.Title,
        Artist = x.Artist,
        Album = x.Album,
        Genre = x.Genre,
        FilePath = x.FilePath,
        DurationSeconds = x.DurationSeconds,
        CoverImage = x.CoverImage,
        UploadedAtUtc = x.UploadedAtUtc,
    };
}

