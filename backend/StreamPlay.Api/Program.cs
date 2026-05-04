using System.Text;
using System.Security.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using MongoDB.Driver;
using Serilog;
using StreamPlay.Api;
using StreamPlay.Api.Config;
using StreamPlay.Api.Helpers;
using StreamPlay.Api.Middleware;
using StreamPlay.Api.Repositories;
using StreamPlay.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((ctx, logger) =>
{
    logger.ReadFrom.Configuration(ctx.Configuration);
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.Configure<MongoDbSettings>(builder.Configuration.GetSection("MongoDb"));
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("Jwt"));

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "FlutterDev",
        policy => policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowAnyOrigin()
    );
});

builder.Services.AddSingleton<IMongoClient>(_ =>
{
    var settings = builder.Configuration.GetSection("MongoDb").Get<MongoDbSettings>()
                   ?? throw new InvalidOperationException("MongoDb settings missing.");
    var mongoSettings = MongoClientSettings.FromConnectionString(settings.ConnectionString);

    // Atlas uses TLS. On some Windows setups, negotiation can fail unless we pin protocols.
    mongoSettings.SslSettings = new SslSettings
    {
        EnabledSslProtocols = SslProtocols.Tls12 | SslProtocols.Tls13,
        CheckCertificateRevocation = true,
    };

    mongoSettings.ServerSelectionTimeout = TimeSpan.FromSeconds(10);
    return new MongoClient(mongoSettings);
});

builder.Services.AddSingleton<MongoDbContext>();

builder.Services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
builder.Services.AddSingleton<IOtpGenerator, OtpGenerator>();
builder.Services.AddSingleton<IFileHasher, Sha256FileHasher>();

builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IMusicRepository, MusicRepository>();
builder.Services.AddScoped<IPlaylistRepository, PlaylistRepository>();
builder.Services.AddScoped<ISettingsRepository, SettingsRepository>();

builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IMusicService, MusicService>();
builder.Services.AddScoped<IPlaylistService, PlaylistService>();
builder.Services.AddScoped<ISettingsService, SettingsService>();
builder.Services.AddScoped<IFolderScanService, FolderScanService>();

// JWT auth
var jwtSettings = builder.Configuration.GetSection("Jwt").Get<JwtSettings>()
                 ?? throw new InvalidOperationException("Jwt settings missing.");
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.SigningKey));

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings.Issuer,
            ValidAudience = jwtSettings.Audience,
            IssuerSigningKey = signingKey,
            ClockSkew = TimeSpan.FromSeconds(30),
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseSerilogRequestLogging();
app.UseMiddleware<ErrorHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("FlutterDev");

// Only redirect to HTTPS when the app is actually bound to an HTTPS endpoint.
// This avoids noisy warnings when running HTTP-only in dev.
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();

// Ensure Mongo indexes exist
try
{
    await app.Services.GetRequiredService<MongoDbContext>().EnsureIndexesAsync();
}
catch (Exception ex)
{
    // Don’t hard-crash the API if MongoDB is temporarily unreachable.
    // Endpoints that need Mongo will still fail until connectivity is fixed.
    app.Logger.LogError(ex, "MongoDB unavailable; index creation skipped at startup.");
}

// Simple root + health endpoints (so "/" doesn't 404 in dev)
app.MapGet("/", () => Results.Ok(new { name = "StreamPlay.Api", status = "running" }));
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapControllers();

app.Run();
