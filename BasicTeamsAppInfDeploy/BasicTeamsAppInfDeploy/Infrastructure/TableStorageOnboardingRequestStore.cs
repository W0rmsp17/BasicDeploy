using Azure;
using Azure.Data.Tables;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Extensions.Configuration;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class TableStorageOnboardingRequestStore : IOnboardingRequestStore
{
    private const string PartitionKey = "OnboardingRequest";
    private readonly TableClient _tableClient;

    public TableStorageOnboardingRequestStore(IConfiguration configuration)
    {
        var connectionString = configuration["Storage:ConnectionString"]
            ?? configuration["AzureWebJobsStorage"]
            ?? throw new InvalidOperationException("Storage:ConnectionString or AzureWebJobsStorage is required.");

        var tableName = configuration["Storage:OnboardingRequestsTableName"];
        if (string.IsNullOrWhiteSpace(tableName))
        {
            tableName = "OnboardingRequests";
        }

        _tableClient = new TableClient(connectionString, tableName);
    }

    public async Task AddAsync(OnboardingRequestRecord request, CancellationToken cancellationToken)
    {
        await _tableClient.CreateIfNotExistsAsync(cancellationToken);
        await _tableClient.AddEntityAsync(OnboardingRequestEntity.FromRecord(request), cancellationToken);
    }

    public async Task<OnboardingRequestRecord?> GetAsync(Guid requestId, CancellationToken cancellationToken)
    {
        await _tableClient.CreateIfNotExistsAsync(cancellationToken);

        try
        {
            var response = await _tableClient.GetEntityAsync<OnboardingRequestEntity>(
                PartitionKey,
                requestId.ToString("N"),
                cancellationToken: cancellationToken);

            return response.Value.ToRecord();
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return null;
        }
    }

    public async Task<bool> TryUpdateStatusAsync(
        Guid requestId,
        OnboardingRequestStatus expectedStatus,
        OnboardingRequestStatus newStatus,
        string? statusMessage,
        CancellationToken cancellationToken)
    {
        await _tableClient.CreateIfNotExistsAsync(cancellationToken);

        try
        {
            var response = await _tableClient.GetEntityAsync<OnboardingRequestEntity>(
                PartitionKey,
                requestId.ToString("N"),
                cancellationToken: cancellationToken);

            var entity = response.Value;
            if (!Enum.TryParse<OnboardingRequestStatus>(entity.Status, out var currentStatus)
                || currentStatus != expectedStatus)
            {
                return false;
            }

            entity.Status = newStatus.ToString();
            entity.StatusMessage = statusMessage;
            entity.UpdatedOn = DateTimeOffset.UtcNow;

            await _tableClient.UpdateEntityAsync(
                entity,
                entity.ETag,
                TableUpdateMode.Replace,
                cancellationToken);

            return true;
        }
        catch (RequestFailedException ex) when (ex.Status is 404 or 412)
        {
            return false;
        }
    }
}
