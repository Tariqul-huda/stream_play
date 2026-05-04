using StreamPlay.Api.DTOs.Settings;

namespace StreamPlay.Api.Services;

public interface ISettingsService
{
    Task<SettingsResponse> GetAsync(string userId, CancellationToken ct = default);
    Task<SettingsResponse> SaveAsync(string userId, SaveSettingsRequest req, CancellationToken ct = default);
}

