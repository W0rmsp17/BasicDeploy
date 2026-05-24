using System.Text.Json;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace BasicTeamsAppInfDeploy.Functions;

public sealed class CreateUserFunction(
    IOnboardingRequestStore requestStore,
    IUserProvisioningService userProvisioningService,
    ILogger<CreateUserFunction> logger)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Function(nameof(CreateUser))]
    public async Task CreateUser(
        [QueueTrigger("create-user", Connection = "AzureWebJobsStorage")] string message,
        CancellationToken cancellationToken)
    {
        var command = JsonSerializer.Deserialize<CreateUserCommand>(message, JsonOptions)
            ?? throw new InvalidOperationException("Create user command message is empty.");

        var request = await requestStore.GetAsync(command.RequestId, cancellationToken)
            ?? throw new InvalidOperationException($"Onboarding request {command.RequestId} was not found.");

        var markedProvisioning = await requestStore.TryUpdateStatusAsync(
            request.Id,
            OnboardingRequestStatus.Approved,
            OnboardingRequestStatus.Provisioning,
            "Provisioning started.",
            null,
            cancellationToken);

        if (!markedProvisioning)
        {
            logger.LogWarning(
                "Skipping onboarding request {RequestId}; it is not in Approved status.",
                request.Id);
            return;
        }

        try
        {
            await userProvisioningService.ProvisionUserAsync(request, cancellationToken);

            await requestStore.TryUpdateStatusAsync(
                request.Id,
                OnboardingRequestStatus.Provisioning,
                OnboardingRequestStatus.Provisioned,
                "Provisioning completed.",
                null,
                cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Provisioning failed for onboarding request {RequestId}.", request.Id);

            await requestStore.TryUpdateStatusAsync(
                request.Id,
                OnboardingRequestStatus.Provisioning,
                OnboardingRequestStatus.ProvisioningFailed,
                ex.Message,
                null,
                cancellationToken);

            throw;
        }
    }
}
