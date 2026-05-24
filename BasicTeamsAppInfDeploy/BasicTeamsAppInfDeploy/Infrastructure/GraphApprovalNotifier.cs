using System.Net.Http.Json;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Identity.Client;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class GraphApprovalNotifier(
    IConfiguration configuration,
    HttpClient httpClient,
    ILogger<GraphApprovalNotifier> logger) : IApprovalNotifier
{
    private static readonly string[] Scopes = ["https://graph.microsoft.com/.default"];
    private readonly string _recipientEmail = configuration["Approval:RecipientEmail"]
        ?? throw new InvalidOperationException("Approval:RecipientEmail is required.");
    private readonly string _senderUserPrincipalName = configuration["Approval:SenderUserPrincipalName"]
        ?? throw new InvalidOperationException("Approval:SenderUserPrincipalName is required when Approval:Provider is Graph.");
    private readonly string _tenantId = configuration["Graph:TenantId"]
        ?? throw new InvalidOperationException("Graph:TenantId is required when Approval:Provider is Graph.");
    private readonly string _clientId = configuration["Graph:ClientId"]
        ?? throw new InvalidOperationException("Graph:ClientId is required when Approval:Provider is Graph.");
    private readonly string _clientSecret = configuration["Graph:ClientSecret"]
        ?? throw new InvalidOperationException("Graph:ClientSecret is required when Approval:Provider is Graph.");

    public async Task SendApprovalRequestAsync(
        OnboardingRequestRecord request,
        ApprovalLinks approvalLinks,
        CancellationToken cancellationToken)
    {
        var body = $"""
            <p>A new Microsoft 365 onboarding request is awaiting approval.</p>
            <table>
              <tr><td><strong>Name</strong></td><td>{Escape(request.DisplayName)}</td></tr>
              <tr><td><strong>UPN</strong></td><td>{Escape(request.UserPrincipalName)}</td></tr>
              <tr><td><strong>Job title</strong></td><td>{Escape(request.JobTitle)}</td></tr>
              <tr><td><strong>Department</strong></td><td>{Escape(request.Department)}</td></tr>
              <tr><td><strong>Manager</strong></td><td>{Escape(request.ManagerEmail)}</td></tr>
              <tr><td><strong>Start date</strong></td><td>{Escape(request.StartDate?.ToString("yyyy-MM-dd"))}</td></tr>
              <tr><td><strong>Requested profile</strong></td><td>{Escape(request.RequestedProfile)}</td></tr>
              <tr><td><strong>Notes</strong></td><td>{Escape(request.Notes)}</td></tr>
            </table>
            <p>
              <a href="{approvalLinks.ApproveUri}">Approve request</a>
              &nbsp;|&nbsp;
              <a href="{approvalLinks.DenyUri}">Deny request</a>
            </p>
            """;

        var accessToken = await GetAccessTokenAsync(cancellationToken);
        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post,
            $"https://graph.microsoft.com/v1.0/users/{Uri.EscapeDataString(_senderUserPrincipalName)}/sendMail");

        httpRequest.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
        httpRequest.Content = JsonContent.Create(new
        {
            message = new
            {
                subject = $"Onboarding approval required: {request.DisplayName}",
                body = new
                {
                    contentType = "HTML",
                    content = body
                },
                toRecipients = new[]
                {
                    new
                    {
                        emailAddress = new
                        {
                            address = _recipientEmail
                        }
                    }
                }
            },
            saveToSentItems = true
        });

        using var response = await httpClient.SendAsync(httpRequest, cancellationToken);
        response.EnsureSuccessStatusCode();

        logger.LogInformation(
            "Sent Graph approval email for onboarding request {RequestId} from {SenderUserPrincipalName} to {RecipientEmail}.",
            request.Id,
            _senderUserPrincipalName,
            _recipientEmail);
    }

    private async Task<string> GetAccessTokenAsync(CancellationToken cancellationToken)
    {
        var app = ConfidentialClientApplicationBuilder
            .Create(_clientId)
            .WithClientSecret(_clientSecret)
            .WithAuthority($"https://login.microsoftonline.com/{_tenantId}")
            .Build();

        var result = await app
            .AcquireTokenForClient(Scopes)
            .ExecuteAsync(cancellationToken);

        return result.AccessToken;
    }

    private static string Escape(string? value)
    {
        return System.Net.WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(value) ? "-" : value);
    }
}
