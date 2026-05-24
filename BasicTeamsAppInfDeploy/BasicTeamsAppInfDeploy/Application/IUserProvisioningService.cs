namespace BasicTeamsAppInfDeploy.Application;

public interface IUserProvisioningService
{
    Task ProvisionUserAsync(OnboardingRequestRecord request, CancellationToken cancellationToken);
}
