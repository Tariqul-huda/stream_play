namespace StreamPlay.Api.DTOs.Scan;

public sealed class ScanFolderResponse
{
    public int FilesDiscovered { get; set; }
    public int Inserted { get; set; }
    public int SkippedDuplicates { get; set; }
    public int Failed { get; set; }
}

