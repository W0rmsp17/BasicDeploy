using System.Net;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace BasicTeamsAppInfDeploy.Functions;

public sealed class DenyOnboardingRequestFunction(
    IOnboardingRequestStore requestStore,
    IApprovalTokenService approvalTokenService,
    ILogger<DenyOnboardingRequestFunction> logger)
{
    [Function(nameof(DenyOnboardingRequest))]
    public async Task<HttpResponseData> DenyOnboardingRequest(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "onboarding-requests/deny")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        var validation = approvalTokenService.ValidateToken(
            GetToken(request),
            ApprovalAction.Deny);

        if (!validation.IsValid)
        {
            return await request.WriteJsonAsync(
                HttpStatusCode.BadRequest,
                new { error = validation.Error },
                cancellationToken);
        }

        var denied = await requestStore.TryUpdateStatusAsync(
            validation.RequestId,
            OnboardingRequestStatus.PendingApproval,
            OnboardingRequestStatus.Denied,
            "Denied by email callback.",
            "EmailLink",
            cancellationToken);

        if (!denied)
        {
            return await request.WriteJsonAsync(
                HttpStatusCode.Conflict,
                new { error = "Request is not pending approval or was already processed." },
                cancellationToken);
        }

        logger.LogInformation("Denied onboarding request {RequestId}.", validation.RequestId);

        return await request.WriteJsonAsync(
            HttpStatusCode.OK,
            new { validation.RequestId, status = OnboardingRequestStatus.Denied },
            cancellationToken);
    }

    private static string GetToken(HttpRequestData request)
    {
        return QueryStringTokenReader.GetToken(request);
    }
}
