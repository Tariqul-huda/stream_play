using System.ComponentModel.DataAnnotations;

namespace StreamPlay.Api.DTOs.Scan;

public sealed class ScanFolderRequest
{
    [Required]
    public string FolderPath { get; set; } = default!;

    public bool ComputeFileHash { get; set; } = false;
}

