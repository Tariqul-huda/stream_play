using System.Net;
using StreamPlay.Api.DTOs.Playlists;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Models;
using StreamPlay.Api.Repositories;

namespace StreamPlay.Api.Services;

public sealed class PlaylistService : IPlaylistService
{
    private readonly IPlaylistRepository _playlists;
    private readonly IMusicRepository _music;

    public PlaylistService(IPlaylistRepository playlists, IMusicRepository music)
    {
        _playlists = playlists;
        _music = music;
    }

    public async Task<PlaylistResponse> CreateAsync(string userId, CreatePlaylistRequest req, CancellationToken ct = default)
    {
        var playlist = new Playlist
        {
            UserId = userId,
            Name = req.Name.Trim(),
            MusicIds = new List<string>(),
            CreatedAtUtc = DateTime.UtcNow,
        };

        await _playlists.CreateAsync(playlist, ct);
        return await MapAsync(playlist, ct);
    }

    public async Task<IReadOnlyList<PlaylistResponse>> GetForUserAsync(string userId, CancellationToken ct = default)
    {
        var items = await _playlists.GetForUserAsync(userId, ct);
        var responses = new List<PlaylistResponse>();
        foreach (var item in items)
        {
            responses.Add(await MapAsync(item, ct));
        }
        return responses;
    }

    public async Task<PlaylistResponse> AddSongAsync(string userId, string playlistId, string musicId, CancellationToken ct = default)
    {
        var playlist = await RequireOwnedPlaylistAsync(userId, playlistId, ct);
        if (!playlist.MusicIds.Contains(musicId))
        {
            playlist.MusicIds.Add(musicId);
            await _playlists.UpdateAsync(playlist, ct);
        }
        return await MapAsync(playlist, ct);
    }

    public async Task<PlaylistResponse> RemoveSongAsync(string userId, string playlistId, string musicId, CancellationToken ct = default)
    {
        var playlist = await RequireOwnedPlaylistAsync(userId, playlistId, ct);
        playlist.MusicIds.RemoveAll(x => x == musicId);
        await _playlists.UpdateAsync(playlist, ct);
        return await MapAsync(playlist, ct);
    }

    public async Task DeleteAsync(string userId, string playlistId, CancellationToken ct = default)
    {
        var ok = await _playlists.DeleteAsync(playlistId, userId, ct);
        if (!ok) throw new ApiException(HttpStatusCode.NotFound, "Playlist not found.");
    }

    private async Task<Playlist> RequireOwnedPlaylistAsync(string userId, string playlistId, CancellationToken ct)
    {
        var playlist = await _playlists.GetByIdAsync(playlistId, ct);
        if (playlist is null) throw new ApiException(HttpStatusCode.NotFound, "Playlist not found.");
        if (playlist.UserId != userId) throw new ApiException(HttpStatusCode.Forbidden, "Forbidden.");
        return playlist;
    }

    private async Task<PlaylistResponse> MapAsync(Playlist x, CancellationToken ct)
    {
        var tracks = new List<StreamPlay.Api.DTOs.Music.MusicResponse>();
        foreach (var id in x.MusicIds)
        {
            var track = await _music.GetByIdAsync(id, ct);
            if (track != null)
            {
                tracks.Add(new StreamPlay.Api.DTOs.Music.MusicResponse
                {
                    Id = track.Id,
                    Title = track.Title,
                    Artist = track.Artist,
                    Album = track.Album,
                    Genre = track.Genre,
                    FilePath = track.FilePath,
                    DurationSeconds = track.DurationSeconds,
                    CoverImage = track.CoverImage,
                    UploadedAtUtc = track.UploadedAtUtc,
                    Labels = track.Labels,
                });
            }
        }
        return new PlaylistResponse
        {
            Id = x.Id,
            Name = x.Name,
            MusicIds = x.MusicIds,
            Tracks = tracks,
            CreatedAtUtc = x.CreatedAtUtc,
        };
    }
}

