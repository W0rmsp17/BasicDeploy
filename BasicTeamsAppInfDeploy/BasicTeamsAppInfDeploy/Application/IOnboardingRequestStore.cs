namespace BasicTeamsAppInfDeploy.Application;

public interface IOnboardingRequestStore
{
    Task AddAsync(OnboardingRequestRecord request, CancellationToken cancellationToken);

    Task<OnboardingRequestRecord?> GetAsync(Guid requestId, CancellationToken cancellationToken);

    Task<bool> TryUpdateStatusAsync(
        Guid requestId,
        OnboardingRequestStatus expectedStatus,
        OnboardingRequestStatus newStatus,
        string? statusMessage,
        string? approvalMethod,
        CancellationToken cancellationToken);
}
