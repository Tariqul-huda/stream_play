using MongoDB.Driver;
using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public sealed class UserRepository : IUserRepository
{
    private readonly MongoDbContext _db;

    public UserRepository(MongoDbContext db)
    {
        _db = db;
    }

    public async Task<User?> GetByEmailNormalizedAsync(string emailNormalized, CancellationToken ct = default)
    {
        return await _db.Users
            .Find(x => x.EmailNormalized == emailNormalized)
            .FirstOrDefaultAsync(ct);
    }

    public async Task<User?> GetByIdAsync(string userId, CancellationToken ct = default)
    {
        return await _db.Users
            .Find(x => x.Id == userId)
            .FirstOrDefaultAsync(ct);
    }

    public Task CreateAsync(User user, CancellationToken ct = default)
        => _db.Users.InsertOneAsync(user, cancellationToken: ct);

    public Task UpdateAsync(User user, CancellationToken ct = default)
        => _db.Users.ReplaceOneAsync(x => x.Id == user.Id, user, cancellationToken: ct);
}

