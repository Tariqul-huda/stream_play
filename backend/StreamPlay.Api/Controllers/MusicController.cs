using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.DTOs.Common;
using StreamPlay.Api.DTOs.Music;
using StreamPlay.Api.Services;

namespace StreamPlay.Api.Controllers;

[ApiController]
[Route("api/music")]
[Authorize]
public sealed class MusicController : ControllerBase
{
    private readonly IMusicService _music;

    public MusicController(IMusicService music)
    {
        _music = music;
    }

    [HttpPost]
    public async Task<ActionResult<MusicResponse>> Create(CreateMusicRequest req, CancellationToken ct)
        => Ok(await _music.CreateAsync(req, ct));

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
}

