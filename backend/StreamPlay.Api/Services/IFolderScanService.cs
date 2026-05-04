using StreamPlay.Api.DTOs.Scan;

namespace StreamPlay.Api.Services;

public interface IFolderScanService
{
    Task<ScanFolderResponse> ScanAsync(ScanFolderRequest req, CancellationToken ct = default);
}

