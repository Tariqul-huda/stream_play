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
    private readonly ILogger<PlaylistsController> _logger;

    public PlaylistsController(IPlaylistService playlists, ILogger<PlaylistsController> logger)
    {
        _playlists = playlists;
        _logger = logger;
    }

    [HttpPost]
    public async Task<ActionResult<PlaylistResponse>> Create(CreatePlaylistRequest req, CancellationToken ct)
        => Ok(await _playlists.CreateAsync(User.GetUserId(), req, ct));

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PlaylistResponse>>> GetMine(CancellationToken ct)
        => Ok(await _playlists.GetForUserAsync(User.GetUserId(), ct));

    [HttpPost("{id}/add")]
    public async Task<IActionResult> AddSong([FromRoute] string id, ModifyPlaylistSongRequest req, CancellationToken ct)
    {
        try
        {
            _logger.LogInformation("AddSong: playlist={Id}, musicId={MusicId}", id, req.MusicId);
            var result = await _playlists.AddSongAsync(User.GetUserId(), id, req.MusicId, ct);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AddSong failed for playlist {Id}", id);
            Response.Headers["Access-Control-Allow-Origin"] = "*";
            return StatusCode(500, new { error = ex.Message });
        }
    }

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

