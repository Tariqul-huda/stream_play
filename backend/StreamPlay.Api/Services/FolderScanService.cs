using System.Net;
using StreamPlay.Api.DTOs.Scan;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Models;
using StreamPlay.Api.Repositories;

namespace StreamPlay.Api.Services;

public sealed class FolderScanService : IFolderScanService
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".mp3", ".wav", ".flac"
    };

    private readonly IMusicRepository _music;
    private readonly IFileHasher _hasher;
    private readonly ILogger<FolderScanService> _logger;

    public FolderScanService(IMusicRepository music, IFileHasher hasher, ILogger<FolderScanService> logger)
    {
        _music = music;
        _hasher = hasher;
        _logger = logger;
    }

    public async Task<ScanFolderResponse> ScanAsync(ScanFolderRequest req, CancellationToken ct = default)
    {
        var folder = req.FolderPath.Trim();
        if (string.IsNullOrWhiteSpace(folder))
            throw new ApiException(HttpStatusCode.BadRequest, "FolderPath is required.");

        if (!Directory.Exists(folder))
            throw new ApiException(HttpStatusCode.BadRequest, "FolderPath does not exist on the server.");

        var resp = new ScanFolderResponse();

        foreach (var file in Directory.EnumerateFiles(folder, "*.*", SearchOption.AllDirectories))
        {
            ct.ThrowIfCancellationRequested();

            try
            {
                var ext = Path.GetExtension(file);
                if (!AllowedExtensions.Contains(ext)) continue;

                resp.FilesDiscovered++;

                var filePathNorm = Normalization.Norm(file);
                if (await _music.ExistsByFilePathAsync(filePathNorm, ct))
                {
                    resp.SkippedDuplicates++;
                    continue;
                }

                using var tagFile = TagLib.File.Create(file);
                var title = string.IsNullOrWhiteSpace(tagFile.Tag.Title)
                    ? Path.GetFileNameWithoutExtension(file)
                    : tagFile.Tag.Title;
                var artist = (tagFile.Tag.Performers?.FirstOrDefault() ?? "Unknown").Trim();
                var album = tagFile.Tag.Album;
                var genre = tagFile.Tag.Genres?.FirstOrDefault();
                var duration = tagFile.Properties.Duration.TotalSeconds;

                var track = new MusicTrack
                {
                    Title = title.Trim(),
                    TitleNormalized = Normalization.Norm(title),
                    Artist = artist,
                    ArtistNormalized = Normalization.Norm(artist),
                    Album = string.IsNullOrWhiteSpace(album) ? null : album.Trim(),
                    Genre = string.IsNullOrWhiteSpace(genre) ? null : genre.Trim(),
                    GenreNormalized = string.IsNullOrWhiteSpace(genre) ? null : Normalization.Norm(genre),
                    FilePath = file,
                    FilePathNormalized = filePathNorm,
                    DurationSeconds = duration,
                    UploadedAtUtc = DateTime.UtcNow,
                    FileHashSha256 = req.ComputeFileHash ? await _hasher.Sha256Async(file, ct) : null,
                };

                await _music.CreateAsync(track, ct);
                resp.Inserted++;
            }
            catch (Exception ex)
            {
                resp.Failed++;
                _logger.LogWarning(ex, "Scan failed for file {File}", file);
            }
        }

        return resp;
    }
}

