using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.DTOs.Folders;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Services;

namespace StreamPlay.Api.Controllers;

[ApiController]
[Route("api/folders")]
[Authorize]
public sealed class FoldersController : ControllerBase
{
    private readonly IFolderService _folders;

    public FoldersController(IFolderService folders)
    {
        _folders = folders;
    }

    [HttpPost]
    public async Task<ActionResult<FolderResponse>> Create(CreateFolderRequest req, CancellationToken ct)
        => Ok(await _folders.CreateAsync(User.GetUserId(), req, ct));

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<FolderResponse>>> GetMine(CancellationToken ct)
        => Ok(await _folders.GetForUserAsync(User.GetUserId(), ct));

    [HttpPost("{id}/add-playlist")]
    public async Task<ActionResult<FolderResponse>> AddPlaylist([FromRoute] string id, AddPlaylistToFolderRequest req, CancellationToken ct)
        => Ok(await _folders.AddPlaylistAsync(User.GetUserId(), id, req.PlaylistId, ct));

    [HttpPost("{id}/remove-playlist")]
    public async Task<ActionResult<FolderResponse>> RemovePlaylist([FromRoute] string id, AddPlaylistToFolderRequest req, CancellationToken ct)
        => Ok(await _folders.RemovePlaylistAsync(User.GetUserId(), id, req.PlaylistId, ct));

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete([FromRoute] string id, CancellationToken ct)
    {
        await _folders.DeleteAsync(User.GetUserId(), id, ct);
        return NoContent();
    }
}
