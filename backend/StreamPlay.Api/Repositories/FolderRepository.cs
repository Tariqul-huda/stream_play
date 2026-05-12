using MongoDB.Driver;
using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public sealed class FolderRepository : IFolderRepository
{
    private readonly MongoDbContext _db;

    public FolderRepository(MongoDbContext db)
    {
        _db = db;
    }

    public async Task<Folder> CreateAsync(Folder folder, CancellationToken ct = default)
    {
        await _db.Folders.InsertOneAsync(folder, cancellationToken: ct);
        return folder;
    }

    public async Task<IReadOnlyList<Folder>> GetForUserAsync(string userId, CancellationToken ct = default)
    {
        return await _db.Folders.Find(x => x.UserId == userId)
            .SortByDescending(x => x.CreatedAtUtc)
            .ToListAsync(ct);
    }

    public async Task<Folder?> GetByIdAsync(string folderId, CancellationToken ct = default)
    {
        return await _db.Folders.Find(x => x.Id == folderId)
            .FirstOrDefaultAsync(ct);
    }

    public Task UpdateAsync(Folder folder, CancellationToken ct = default)
        => _db.Folders.ReplaceOneAsync(x => x.Id == folder.Id, folder, cancellationToken: ct);

    public async Task<bool> DeleteAsync(string folderId, string userId, CancellationToken ct = default)
    {
        var res = await _db.Folders.DeleteOneAsync(x => x.Id == folderId && x.UserId == userId, ct);
        return res.DeletedCount > 0;
    }
}
