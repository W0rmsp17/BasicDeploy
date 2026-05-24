namespace BasicTeamsAppInfDeploy.Infrastructure;

public interface IGraphTokenProvider
{
    Task<string> GetAccessTokenAsync(CancellationToken cancellationToken);
}
