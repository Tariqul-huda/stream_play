using StreamPlay.Api.DTOs.Settings;
using StreamPlay.Api.Models;
using StreamPlay.Api.Repositories;

namespace StreamPlay.Api.Services;

public sealed class SettingsService : ISettingsService
{
    private readonly ISettingsRepository _repo;

    public SettingsService(ISettingsRepository repo)
    {
        _repo = repo;
    }

    public async Task<SettingsResponse> GetAsync(string userId, CancellationToken ct = default)
    {
        var s = await _repo.GetForUserAsync(userId, ct);
        return new SettingsResponse
        {
            PreferredMusicFolderPath = s?.PreferredMusicFolderPath,
            Theme = s?.Theme,
            GoogleEmail = s?.GoogleEmail,
            GoogleName = s?.GoogleName,
            IsGoogleConnected = s?.IsGoogleConnected ?? false,
            AudioQuality = s?.AudioQuality ?? "High",
            AutoplayNext = s?.AutoplayNext ?? true,
            YoutubeHistory = s?.YoutubeHistory ?? new(),
        };
    }

    public async Task<SettingsResponse> SaveAsync(string userId, SaveSettingsRequest req, CancellationToken ct = default)
    {
        var existing = await _repo.GetForUserAsync(userId, ct);
        var settings = existing ?? new UserSettings { UserId = userId };

        settings.PreferredMusicFolderPath = string.IsNullOrWhiteSpace(req.PreferredMusicFolderPath)
            ? null
            : req.PreferredMusicFolderPath.Trim();
        settings.Theme = string.IsNullOrWhiteSpace(req.Theme) ? null : req.Theme.Trim();

        settings.GoogleEmail = string.IsNullOrWhiteSpace(req.GoogleEmail) ? null : req.GoogleEmail.Trim();
        settings.GoogleName = string.IsNullOrWhiteSpace(req.GoogleName) ? null : req.GoogleName.Trim();
        if (req.IsGoogleConnected.HasValue)
        {
            settings.IsGoogleConnected = req.IsGoogleConnected.Value;
        }
        if (!string.IsNullOrWhiteSpace(req.AudioQuality))
        {
            settings.AudioQuality = req.AudioQuality.Trim();
        }
        if (req.AutoplayNext.HasValue)
        {
            settings.AutoplayNext = req.AutoplayNext.Value;
        }
        if (req.YoutubeHistory != null)
        {
            settings.YoutubeHistory = req.YoutubeHistory;
        }

        var saved = await _repo.UpsertAsync(settings, ct);
        return new SettingsResponse
        {
            PreferredMusicFolderPath = saved.PreferredMusicFolderPath,
            Theme = saved.Theme,
            GoogleEmail = saved.GoogleEmail,
            GoogleName = saved.GoogleName,
            IsGoogleConnected = saved.IsGoogleConnected,
            AudioQuality = saved.AudioQuality,
            AutoplayNext = saved.AutoplayNext,
            YoutubeHistory = saved.YoutubeHistory,
        };
    }
}

