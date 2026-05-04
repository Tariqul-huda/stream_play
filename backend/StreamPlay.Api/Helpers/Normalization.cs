namespace StreamPlay.Api.Helpers;

public static class Normalization
{
    public static string Norm(string value) => value.Trim().ToLowerInvariant();
}

