using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class GraphUserProvisioningService(
    IConfiguration configuration,
    HttpClient httpClient,
    IGraphTokenProvider graphTokenProvider,
    ILogger<GraphUserProvisioningService> logger) : IUserProvisioningService
{
    private readonly bool _createDisabledUsers = configuration.GetValue("Provisioning:CreateDisabledUsers", true);
    private readonly string? _licenseGroupId = configuration["Provisioning:LicenseGroupId"];

    public async Task ProvisionUserAsync(OnboardingRequestRecord request, CancellationToken cancellationToken)
    {
        var accessToken = await graphTokenProvider.GetAccessTokenAsync(cancellationToken);
        var userId = await CreateUserAsync(request, accessToken, cancellationToken);

        if (!string.IsNullOrWhiteSpace(_licenseGroupId))
        {
            await AddUserToGroupAsync(userId, _licenseGroupId, accessToken, cancellationToken);
        }

        logger.LogInformation(
            "Provisioned user {DisplayName} ({UserPrincipalName}) with Graph user id {UserId}.",
            request.DisplayName,
            request.UserPrincipalName,
            userId);
    }

    private async Task<string> CreateUserAsync(
        OnboardingRequestRecord request,
        string accessToken,
        CancellationToken cancellationToken)
    {
        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "https://graph.microsoft.com/v1.0/users");
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        httpRequest.Content = JsonContent.Create(new
        {
            accountEnabled = !_createDisabledUsers,
            displayName = request.DisplayName,
            givenName = request.FirstName,
            surname = request.LastName,
            jobTitle = request.JobTitle,
            department = request.Department,
            mailNickname = GraphProvisioningValueFactory.CreateMailNickname(request),
            userPrincipalName = request.UserPrincipalName,
            passwordProfile = new
            {
                forceChangePasswordNextSignIn = true,
                password = GraphProvisioningValueFactory.CreateTemporaryPassword()
            }
        });

        using var response = await httpClient.SendAsync(httpRequest, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Graph user creation failed with status {(int)response.StatusCode}: {responseBody}");
        }

        var createdUser = await response.Content.ReadFromJsonAsync<CreatedGraphUser>(
            cancellationToken: cancellationToken);

        if (createdUser?.Id is null)
        {
            throw new InvalidOperationException("Graph user creation response did not include a user id.");
        }

        return createdUser.Id;
    }

    private async Task AddUserToGroupAsync(
        string userId,
        string groupId,
        string accessToken,
        CancellationToken cancellationToken)
    {
        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post,
            $"https://graph.microsoft.com/v1.0/groups/{Uri.EscapeDataString(groupId)}/members/$ref");

        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        httpRequest.Content = JsonContent.Create(
            new DirectoryReference($"https://graph.microsoft.com/v1.0/directoryObjects/{userId}"));

        using var response = await httpClient.SendAsync(httpRequest, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Graph group assignment failed with status {(int)response.StatusCode}: {responseBody}");
        }
    }

    private sealed record CreatedGraphUser(string? Id);

    private sealed record DirectoryReference(
        [property: JsonPropertyName("@odata.id")] string ODataId);
}
