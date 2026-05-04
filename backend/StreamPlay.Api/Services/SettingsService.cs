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

        var saved = await _repo.UpsertAsync(settings, ct);
        return new SettingsResponse
        {
            PreferredMusicFolderPath = saved.PreferredMusicFolderPath,
            Theme = saved.Theme,
        };
    }
}

