using Microsoft.Extensions.Configuration;
using Microsoft.Identity.Client;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class MsalGraphTokenProvider(IConfiguration configuration) : IGraphTokenProvider
{
    private static readonly string[] Scopes = ["https://graph.microsoft.com/.default"];
    private readonly string _tenantId = configuration["Graph:TenantId"]
        ?? throw new InvalidOperationException("Graph:TenantId is required for Graph operations.");
    private readonly string _clientId = configuration["Graph:ClientId"]
        ?? throw new InvalidOperationException("Graph:ClientId is required for Graph operations.");
    private readonly string _clientSecret = configuration["Graph:ClientSecret"]
        ?? throw new InvalidOperationException("Graph:ClientSecret is required for Graph operations.");

    public async Task<string> GetAccessTokenAsync(CancellationToken cancellationToken)
    {
        var app = ConfidentialClientApplicationBuilder
            .Create(_clientId)
            .WithClientSecret(_clientSecret)
            .WithAuthority($"https://login.microsoftonline.com/{_tenantId}")
            .Build();

        var result = await app
            .AcquireTokenForClient(Scopes)
            .ExecuteAsync(cancellationToken);

        return result.AccessToken;
    }
}
