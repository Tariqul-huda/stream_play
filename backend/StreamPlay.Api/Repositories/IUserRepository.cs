using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public interface IUserRepository
{
    Task<User?> GetByEmailNormalizedAsync(string emailNormalized, CancellationToken ct = default);
    Task<User?> GetByIdAsync(string userId, CancellationToken ct = default);
    Task CreateAsync(User user, CancellationToken ct = default);
    Task UpdateAsync(User user, CancellationToken ct = default);
}

