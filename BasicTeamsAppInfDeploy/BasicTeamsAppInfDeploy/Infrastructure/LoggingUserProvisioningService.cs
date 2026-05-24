using BasicTeamsAppInfDeploy.Application;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class LoggingUserProvisioningService(
    IConfiguration configuration,
    ILogger<LoggingUserProvisioningService> logger) : IUserProvisioningService
{
    public Task ProvisionUserAsync(OnboardingRequestRecord request, CancellationToken cancellationToken)
    {
        var createDisabled = configuration.GetValue("Provisioning:CreateDisabledUsers", true);
        var licenseGroupId = configuration["Provisioning:LicenseGroupId"];

        logger.LogInformation(
            "Provisioning stub for {DisplayName} ({UserPrincipalName}). CreateDisabledUsers: {CreateDisabledUsers}. LicenseGroupId: {LicenseGroupId}",
            request.DisplayName,
            request.UserPrincipalName,
            createDisabled,
            string.IsNullOrWhiteSpace(licenseGroupId) ? "(none)" : licenseGroupId);

        return Task.CompletedTask;
    }
}
