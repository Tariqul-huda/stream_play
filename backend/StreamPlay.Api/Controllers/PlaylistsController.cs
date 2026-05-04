using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.DTOs.Playlists;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Services;

namespace StreamPlay.Api.Controllers;

[ApiController]
[Route("api/playlists")]
[Authorize]
public sealed class PlaylistsController : ControllerBase
{
    private readonly IPlaylistService _playlists;

    public PlaylistsController(IPlaylistService playlists)
    {
        _playlists = playlists;
    }

    [HttpPost]
    public async Task<ActionResult<PlaylistResponse>> Create(CreatePlaylistRequest req, CancellationToken ct)
        => Ok(await _playlists.CreateAsync(User.GetUserId(), req, ct));

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PlaylistResponse>>> GetMine(CancellationToken ct)
        => Ok(await _playlists.GetForUserAsync(User.GetUserId(), ct));

    [HttpPost("{id}/add")]
    public async Task<ActionResult<PlaylistResponse>> AddSong([FromRoute] string id, ModifyPlaylistSongRequest req, CancellationToken ct)
        => Ok(await _playlists.AddSongAsync(User.GetUserId(), id, req.MusicId, ct));

    [HttpPost("{id}/remove")]
    public async Task<ActionResult<PlaylistResponse>> RemoveSong([FromRoute] string id, ModifyPlaylistSongRequest req, CancellationToken ct)
        => Ok(await _playlists.RemoveSongAsync(User.GetUserId(), id, req.MusicId, ct));

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete([FromRoute] string id, CancellationToken ct)
    {
        await _playlists.DeleteAsync(User.GetUserId(), id, ct);
        return NoContent();
    }
}

