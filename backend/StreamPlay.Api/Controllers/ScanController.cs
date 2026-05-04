using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.DTOs.Scan;
using StreamPlay.Api.Services;

namespace StreamPlay.Api.Controllers;

[ApiController]
[Route("api")]
[Authorize]
public sealed class ScanController : ControllerBase
{
    private readonly IFolderScanService _scan;

    public ScanController(IFolderScanService scan)
    {
        _scan = scan;
    }

    [HttpPost("scan-folder")]
    public async Task<ActionResult<ScanFolderResponse>> ScanFolder(ScanFolderRequest req, CancellationToken ct)
        => Ok(await _scan.ScanAsync(req, ct));
}

