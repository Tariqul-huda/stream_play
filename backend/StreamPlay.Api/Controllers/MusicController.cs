using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.DTOs.Common;
using StreamPlay.Api.DTOs.Music;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Services;

namespace StreamPlay.Api.Controllers;

[ApiController]
[Route("api/music")]
[Authorize]
public sealed class MusicController : ControllerBase
{
    private readonly IMusicService _music;
    private readonly ILogger<MusicController> _logger;

    public MusicController(IMusicService music, ILogger<MusicController> logger)
    {
        _music = music;
        _logger = logger;
    }

    [HttpPost]
    public async Task<ActionResult<MusicResponse>> Create(CreateMusicRequest req, CancellationToken ct)
        => Ok(await _music.CreateAsync(req, ct));

    [HttpPost("bulk")]
    public async Task<IActionResult> BulkCreate(List<CreateMusicRequest> requests, CancellationToken ct)
    {
        try
        {
            _logger.LogInformation("BulkCreate called with {Count} items", requests?.Count ?? 0);
            var result = await _music.BulkCreateAsync(User.GetUserId(), requests ?? new(), ct);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "BulkCreate failed");
            // Return error with CORS headers so the browser doesn't hide the message
            Response.Headers["Access-Control-Allow-Origin"] = "*";
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet]
    public async Task<ActionResult<PagedResponse<MusicResponse>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
        => Ok(await _music.GetPagedAsync(page, pageSize, ct));

    [HttpGet("genre/{genre}")]
    public async Task<ActionResult<IReadOnlyList<MusicResponse>>> ByGenre([FromRoute] string genre, CancellationToken ct)
        => Ok(await _music.GetByGenreAsync(genre, ct));

    [HttpGet("search")]
    public async Task<ActionResult<IReadOnlyList<MusicResponse>>> Search([FromQuery] string q, CancellationToken ct)
        => Ok(await _music.SearchAsync(q, ct));

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete([FromRoute] string id, CancellationToken ct)
    {
        await _music.DeleteAsync(id, ct);
        return NoContent();
    }

    [HttpGet("by-path")]
    public async Task<ActionResult<MusicResponse>> ByPath([FromQuery] string path, CancellationToken ct)
    {
        var track = await _music.FindByPathAsync(path, ct);
        if (track is null) return NotFound("Music not found for path.");
        return Ok(track);
    }

    [HttpPut("{id}/label")]
    public async Task<ActionResult<MusicResponse>> AddLabel([FromRoute] string id, AddLabelRequest req, CancellationToken ct)
        => Ok(await _music.AddLabelAsync(User.GetUserId(), id, req, ct));
}


