namespace StreamPlay.Api.DTOs.Common;

public sealed class PagedResponse<T>
{
    public IReadOnlyList<T> Items { get; init; } = Array.Empty<T>();
    public long Total { get; init; }
    public int Page { get; init; }
    public int PageSize { get; init; }
}

