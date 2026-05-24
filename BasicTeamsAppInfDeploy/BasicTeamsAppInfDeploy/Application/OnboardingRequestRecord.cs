namespace BasicTeamsAppInfDeploy.Application;

public sealed record OnboardingRequestRecord
{
    public required Guid Id { get; init; }

    public required string FirstName { get; init; }

    public required string LastName { get; init; }

    public required string DisplayName { get; init; }

    public required string UserPrincipalName { get; init; }

    public string? JobTitle { get; init; }

    public string? Department { get; init; }

    public string? ManagerEmail { get; init; }

    public DateOnly? StartDate { get; init; }

    public string? RequestedProfile { get; init; }

    public string? Notes { get; init; }

    public required OnboardingRequestStatus Status { get; init; }

    public string? StatusMessage { get; init; }

    public string? ApprovalMethod { get; init; }

    public DateTimeOffset? ApprovedOrDeniedOn { get; init; }

    public required DateTimeOffset CreatedOn { get; init; }

    public DateTimeOffset UpdatedOn { get; init; }
}
