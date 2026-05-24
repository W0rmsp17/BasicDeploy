namespace BasicTeamsAppInfDeploy.Application;

public interface IApprovalNotifier
{
    Task SendApprovalRequestAsync(
        OnboardingRequestRecord request,
        ApprovalLinks approvalLinks,
        CancellationToken cancellationToken);
}
