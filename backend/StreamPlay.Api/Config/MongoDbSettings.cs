namespace StreamPlay.Api.Config;

public sealed class MongoDbSettings
{
    public string ConnectionString { get; init; } = default!;
    public string DatabaseName { get; init; } = default!;
}

