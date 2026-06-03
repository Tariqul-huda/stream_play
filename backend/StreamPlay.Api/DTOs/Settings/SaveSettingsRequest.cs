namespace StreamPlay.Api.DTOs.Settings;

public sealed class SaveSettingsRequest
{
    public string? PreferredMusicFolderPath { get; set; }
    public string? Theme { get; set; }

    public string? GoogleEmail { get; set; }
    public string? GoogleName { get; set; }
    public bool? IsGoogleConnected { get; set; }

    public string? AudioQuality { get; set; }
    public bool? AutoplayNext { get; set; }
    public List<string>? YoutubeHistory { get; set; }
}

