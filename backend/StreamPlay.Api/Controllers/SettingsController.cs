using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StreamPlay.Api.DTOs.Settings;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Services;

namespace StreamPlay.Api.Controllers;

[ApiController]
[Route("api/settings")]
[Authorize]
public sealed class SettingsController : ControllerBase
{
    private readonly ISettingsService _settings;

    public SettingsController(ISettingsService settings)
    {
        _settings = settings;
    }

    [HttpGet]
    public async Task<ActionResult<SettingsResponse>> Get(CancellationToken ct)
        => Ok(await _settings.GetAsync(User.GetUserId(), ct));

    [HttpPost]
    public async Task<ActionResult<SettingsResponse>> Save(SaveSettingsRequest req, CancellationToken ct)
        => Ok(await _settings.SaveAsync(User.GetUserId(), req, ct));
}

