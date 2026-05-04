using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public interface ISettingsRepository
{
    Task<UserSettings?> GetForUserAsync(string userId, CancellationToken ct = default);
    Task<UserSettings> UpsertAsync(UserSettings settings, CancellationToken ct = default);
}

