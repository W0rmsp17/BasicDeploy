using System.Collections.Concurrent;
using BasicTeamsAppInfDeploy.Application;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class InMemoryOnboardingRequestStore : IOnboardingRequestStore
{
    private readonly ConcurrentDictionary<Guid, OnboardingRequestRecord> _requests = [];

    public Task AddAsync(OnboardingRequestRecord request, CancellationToken cancellationToken)
    {
        _requests[request.Id] = request;
        return Task.CompletedTask;
    }

    public Task<OnboardingRequestRecord?> GetAsync(Guid requestId, CancellationToken cancellationToken)
    {
        _requests.TryGetValue(requestId, out var request);
        return Task.FromResult(request);
    }

    public Task<bool> TryUpdateStatusAsync(
        Guid requestId,
        OnboardingRequestStatus expectedStatus,
        OnboardingRequestStatus newStatus,
        string? statusMessage,
        string? approvalMethod,
        CancellationToken cancellationToken)
    {
        if (!_requests.TryGetValue(requestId, out var current) || current.Status != expectedStatus)
        {
            return Task.FromResult(false);
        }

        var updated = current with
        {
            Status = newStatus,
            StatusMessage = statusMessage,
            ApprovalMethod = approvalMethod,
            ApprovedOrDeniedOn = newStatus is OnboardingRequestStatus.Approved or OnboardingRequestStatus.Denied
                ? DateTimeOffset.UtcNow
                : current.ApprovedOrDeniedOn,
            UpdatedOn = DateTimeOffset.UtcNow
        };

        return Task.FromResult(_requests.TryUpdate(requestId, updated, current));
    }
}
