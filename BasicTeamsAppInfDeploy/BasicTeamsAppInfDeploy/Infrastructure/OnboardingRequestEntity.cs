using Azure;
using Azure.Data.Tables;
using BasicTeamsAppInfDeploy.Application;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class OnboardingRequestEntity : ITableEntity
{
    public string PartitionKey { get; set; } = "OnboardingRequest";

    public string RowKey { get; set; } = default!;

    public DateTimeOffset? Timestamp { get; set; }

    public ETag ETag { get; set; }

    public string FirstName { get; set; } = default!;

    public string LastName { get; set; } = default!;

    public string DisplayName { get; set; } = default!;

    public string UserPrincipalName { get; set; } = default!;

    public string? JobTitle { get; set; }

    public string? Department { get; set; }

    public string? ManagerEmail { get; set; }

    public string? StartDate { get; set; }

    public string? RequestedProfile { get; set; }

    public string? Notes { get; set; }

    public string Status { get; set; } = default!;

    public string? StatusMessage { get; set; }

    public string? ApprovalMethod { get; set; }

    public DateTimeOffset? ApprovedOrDeniedOn { get; set; }

    public DateTimeOffset CreatedOn { get; set; }

    public DateTimeOffset UpdatedOn { get; set; }

    public static OnboardingRequestEntity FromRecord(OnboardingRequestRecord request)
    {
        return new OnboardingRequestEntity
        {
            RowKey = request.Id.ToString("N"),
            FirstName = request.FirstName,
            LastName = request.LastName,
            DisplayName = request.DisplayName,
            UserPrincipalName = request.UserPrincipalName,
            JobTitle = request.JobTitle,
            Department = request.Department,
            ManagerEmail = request.ManagerEmail,
            StartDate = request.StartDate?.ToString("yyyy-MM-dd"),
            RequestedProfile = request.RequestedProfile,
            Notes = request.Notes,
            Status = request.Status.ToString(),
            StatusMessage = request.StatusMessage,
            ApprovalMethod = request.ApprovalMethod,
            ApprovedOrDeniedOn = request.ApprovedOrDeniedOn,
            CreatedOn = request.CreatedOn,
            UpdatedOn = request.UpdatedOn
        };
    }

    public OnboardingRequestRecord ToRecord()
    {
        return new OnboardingRequestRecord
        {
            Id = Guid.ParseExact(RowKey, "N"),
            FirstName = FirstName,
            LastName = LastName,
            DisplayName = DisplayName,
            UserPrincipalName = UserPrincipalName,
            JobTitle = JobTitle,
            Department = Department,
            ManagerEmail = ManagerEmail,
            StartDate = string.IsNullOrWhiteSpace(StartDate) ? null : DateOnly.ParseExact(StartDate, "yyyy-MM-dd"),
            RequestedProfile = RequestedProfile,
            Notes = Notes,
            Status = Enum.Parse<OnboardingRequestStatus>(Status),
            StatusMessage = StatusMessage,
            ApprovalMethod = ApprovalMethod,
            ApprovedOrDeniedOn = ApprovedOrDeniedOn,
            CreatedOn = CreatedOn,
            UpdatedOn = UpdatedOn
        };
    }
}
