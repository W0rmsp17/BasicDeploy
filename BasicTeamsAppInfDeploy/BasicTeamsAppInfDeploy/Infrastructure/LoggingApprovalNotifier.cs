using BasicTeamsAppInfDeploy.Application;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class LoggingApprovalNotifier(
    IConfiguration configuration,
    ILogger<LoggingApprovalNotifier> logger) : IApprovalNotifier
{
    private readonly string _recipientEmail = configuration["Approval:RecipientEmail"] ?? "not-configured";

    public Task SendApprovalRequestAsync(
        OnboardingRequestRecord request,
        ApprovalLinks approvalLinks,
        CancellationToken cancellationToken)
    {
        logger.LogInformation(
            "Approval requested for {DisplayName} ({UserPrincipalName}). Recipient: {RecipientEmail}. Approve: {ApproveUri}. Deny: {DenyUri}",
            request.DisplayName,
            request.UserPrincipalName,
            _recipientEmail,
            approvalLinks.ApproveUri,
            approvalLinks.DenyUri);

        return Task.CompletedTask;
    }
}
