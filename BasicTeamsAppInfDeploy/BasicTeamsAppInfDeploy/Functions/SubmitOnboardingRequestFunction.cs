using System.Net;
using System.Text.Json;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BasicTeamsAppInfDeploy.Functions;

public sealed class SubmitOnboardingRequestFunction(
    IConfiguration configuration,
    IOnboardingRequestStore requestStore,
    IApprovalTokenService approvalTokenService,
    IApprovalNotifier approvalNotifier,
    ILogger<SubmitOnboardingRequestFunction> logger)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Function(nameof(SubmitOnboardingRequest))]
    public async Task<HttpResponseData> SubmitOnboardingRequest(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "onboarding-requests")] HttpRequestData request,
        FunctionContext executionContext,
        CancellationToken cancellationToken)
    {
        var payload = await JsonSerializer.DeserializeAsync<SubmitOnboardingRequest>(
            request.Body,
            JsonOptions,
            cancellationToken);

        if (payload is null)
        {
            return await request.WriteJsonAsync(
                HttpStatusCode.BadRequest,
                new { errors = new[] { "Request body is required." } },
                cancellationToken);
        }

        var defaultUserDomain = configuration["Provisioning:DefaultUserDomain"] ?? string.Empty;
        var validation = payload.Validate(defaultUserDomain);
        if (!validation.IsValid)
        {
            return await request.WriteJsonAsync(
                HttpStatusCode.BadRequest,
                new { errors = validation.Errors },
                cancellationToken);
        }

        var onboardingRequest = payload.ToRecord(defaultUserDomain);
        await requestStore.AddAsync(onboardingRequest, cancellationToken);

        var approvalLinks = CreateApprovalLinks(onboardingRequest.Id);
        await approvalNotifier.SendApprovalRequestAsync(onboardingRequest, approvalLinks, cancellationToken);

        logger.LogInformation(
            "Created onboarding request {RequestId} for {UserPrincipalName}.",
            onboardingRequest.Id,
            onboardingRequest.UserPrincipalName);

        return await request.WriteJsonAsync(
            HttpStatusCode.Accepted,
            new
            {
                onboardingRequest.Id,
                onboardingRequest.Status,
                onboardingRequest.UserPrincipalName,
                approvalLinks.ApproveUri,
                approvalLinks.DenyUri
            },
            cancellationToken);
    }

    private ApprovalLinks CreateApprovalLinks(Guid requestId)
    {
        var baseUrl = configuration["Approval:BaseUrl"]?.TrimEnd('/')
            ?? throw new InvalidOperationException("Approval:BaseUrl is required.");
        var expiresOn = DateTimeOffset.UtcNow.AddDays(7);
        var approveToken = approvalTokenService.CreateToken(requestId, ApprovalAction.Approve, expiresOn);
        var denyToken = approvalTokenService.CreateToken(requestId, ApprovalAction.Deny, expiresOn);

        return new ApprovalLinks(
            new Uri($"{baseUrl}/api/onboarding-requests/approve?token={Uri.EscapeDataString(approveToken)}"),
            new Uri($"{baseUrl}/api/onboarding-requests/deny?token={Uri.EscapeDataString(denyToken)}"));
    }
}
