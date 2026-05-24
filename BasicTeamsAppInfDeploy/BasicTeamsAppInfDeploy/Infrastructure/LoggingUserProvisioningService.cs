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
        var licenseAssignmentMode = configuration.GetValue(
            "Provisioning:LicenseAssignmentMode",
            LicenseAssignmentMode.None);
        var licenseGroupId = configuration["Provisioning:LicenseGroupId"];

        logger.LogInformation(
            "Provisioning stub for {DisplayName} ({UserPrincipalName}). CreateDisabledUsers: {CreateDisabledUsers}. LicenseAssignmentMode: {LicenseAssignmentMode}. LicenseGroupId: {LicenseGroupId}",
            request.DisplayName,
            request.UserPrincipalName,
            createDisabled,
            licenseAssignmentMode,
            string.IsNullOrWhiteSpace(licenseGroupId) ? "(none)" : licenseGroupId);

        return Task.CompletedTask;
    }
}
