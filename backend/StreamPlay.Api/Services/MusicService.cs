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
    private readonly IPlaylistRepository _playlists;

    public MusicService(IMusicRepository music, IPlaylistRepository playlists)
    {
        _music = music;
        _playlists = playlists;
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

    public async Task<IReadOnlyList<MusicResponse>> BulkCreateAsync(string userId, IReadOnlyList<CreateMusicRequest> requests, CancellationToken ct = default)
    {
        var created = new List<MusicTrack>();

        foreach (var req in requests)
        {
            if (string.IsNullOrWhiteSpace(req.FilePath) || string.IsNullOrWhiteSpace(req.Title))
                continue;

            var filePathNorm = Normalization.Norm(req.FilePath);
            if (await _music.ExistsByFilePathAsync(filePathNorm, ct))
            {
                // Already exists – look it up so we can still add to playlist
                var existing = await _music.GetByFilePathAsync(filePathNorm, ct);
                if (existing is not null) created.Add(existing);
                continue;
            }

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
            created.Add(track);
        }

        // Auto-create / update "Local" playlist
        if (created.Count > 0)
        {
            var userPlaylists = await _playlists.GetForUserAsync(userId, ct);
            var localPlaylist = userPlaylists.FirstOrDefault(p => p.Name.Equals("Local", StringComparison.OrdinalIgnoreCase));

            var newIds = created.Select(t => t.Id).ToList();

            if (localPlaylist is null)
            {
                localPlaylist = new Playlist
                {
                    UserId = userId,
                    Name = "Local",
                    MusicIds = newIds,
                    CreatedAtUtc = DateTime.UtcNow,
                };
                await _playlists.CreateAsync(localPlaylist, ct);
            }
            else
            {
                foreach (var id in newIds)
                {
                    if (!localPlaylist.MusicIds.Contains(id))
                        localPlaylist.MusicIds.Add(id);
                }
                await _playlists.UpdateAsync(localPlaylist, ct);
            }
        }

        return created.Select(Map).ToList();
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

    public async Task<MusicResponse> AddLabelAsync(string userId, string musicId, AddLabelRequest req, CancellationToken ct = default)
    {
        var track = await _music.GetByIdAsync(musicId, ct);
        if (track is null) throw new ApiException(HttpStatusCode.NotFound, "Music not found.");

        var label = req.Label.Trim();

        // Add label to the track if not already present
        if (!track.Labels.Any(l => l.Equals(label, StringComparison.OrdinalIgnoreCase)))
        {
            track.Labels.Add(label);
            await _music.UpdateAsync(track, ct);
        }

        // Find or create a playlist matching this label for the user
        var userPlaylists = await _playlists.GetForUserAsync(userId, ct);
        var playlist = userPlaylists.FirstOrDefault(p => p.Name.Equals(label, StringComparison.OrdinalIgnoreCase));

        if (playlist is null)
        {
            playlist = new Playlist
            {
                UserId = userId,
                Name = label,
                MusicIds = new List<string> { musicId },
                CreatedAtUtc = DateTime.UtcNow,
            };
            await _playlists.CreateAsync(playlist, ct);
        }
        else if (!playlist.MusicIds.Contains(musicId))
        {
            playlist.MusicIds.Add(musicId);
            await _playlists.UpdateAsync(playlist, ct);
        }

        return Map(track);
    }

    public async Task<MusicResponse?> FindByPathAsync(string filePath, CancellationToken ct = default)
    {
        var track = await _music.GetByFilePathAsync(Normalization.Norm(filePath), ct);
        return track is null ? null : Map(track);
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
        Labels = x.Labels,
    };
}
