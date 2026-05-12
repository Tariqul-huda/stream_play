using StreamPlay.Api.Models;

namespace StreamPlay.Api.Repositories;

public interface IFolderRepository
{
    Task<Folder> CreateAsync(Folder folder, CancellationToken ct = default);
    Task<IReadOnlyList<Folder>> GetForUserAsync(string userId, CancellationToken ct = default);
    Task<Folder?> GetByIdAsync(string folderId, CancellationToken ct = default);
    Task UpdateAsync(Folder folder, CancellationToken ct = default);
    Task<bool> DeleteAsync(string folderId, string userId, CancellationToken ct = default);
}
