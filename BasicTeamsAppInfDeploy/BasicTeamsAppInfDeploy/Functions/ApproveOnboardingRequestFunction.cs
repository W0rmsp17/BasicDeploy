using System.Net;
using System.Text.Json;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace BasicTeamsAppInfDeploy.Functions;

public sealed class ApproveOnboardingRequestFunction(
    IOnboardingRequestStore requestStore,
    IApprovalTokenService approvalTokenService,
    ILogger<ApproveOnboardingRequestFunction> logger)
{
    [Function(nameof(ApproveOnboardingRequest))]
    public async Task<ApprovalFunctionOutput> ApproveOnboardingRequest(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "onboarding-requests/approve")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        var validation = approvalTokenService.ValidateToken(
            GetToken(request),
            ApprovalAction.Approve);

        if (!validation.IsValid)
        {
            return new ApprovalFunctionOutput
            {
                HttpResponse = await request.WriteJsonAsync(
                    HttpStatusCode.BadRequest,
                    new { error = validation.Error },
                    cancellationToken)
            };
        }

        var approved = await requestStore.TryUpdateStatusAsync(
            validation.RequestId,
            OnboardingRequestStatus.PendingApproval,
            OnboardingRequestStatus.Approved,
            "Approved by email callback.",
            cancellationToken);

        if (!approved)
        {
            return new ApprovalFunctionOutput
            {
                HttpResponse = await request.WriteJsonAsync(
                    HttpStatusCode.Conflict,
                    new { error = "Request is not pending approval or was already processed." },
                    cancellationToken)
            };
        }

        logger.LogInformation("Approved onboarding request {RequestId}.", validation.RequestId);

        var command = JsonSerializer.Serialize(new CreateUserCommand(validation.RequestId));
        return new ApprovalFunctionOutput
        {
            CreateUserCommand = command,
            HttpResponse = await request.WriteJsonAsync(
                HttpStatusCode.Accepted,
                new { validation.RequestId, status = OnboardingRequestStatus.Approved },
                cancellationToken)
        };
    }

    private static string GetToken(HttpRequestData request)
    {
        return QueryStringTokenReader.GetToken(request);
    }
}
