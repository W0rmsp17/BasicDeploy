using System.Text.RegularExpressions;

namespace BasicTeamsAppInfDeploy.Application;

public sealed partial record SubmitOnboardingRequest
{
    public string? FirstName { get; init; }

    public string? LastName { get; init; }

    public string? JobTitle { get; init; }

    public string? Department { get; init; }

    public string? ManagerEmail { get; init; }

    public DateOnly? StartDate { get; init; }

    public string? RequestedProfile { get; init; }

    public string? Notes { get; init; }

    public ValidationResult Validate(string defaultUserDomain)
    {
        List<string> errors = [];

        if (string.IsNullOrWhiteSpace(FirstName))
        {
            errors.Add("First name is required.");
        }

        if (string.IsNullOrWhiteSpace(LastName))
        {
            errors.Add("Last name is required.");
        }

        if (string.IsNullOrWhiteSpace(defaultUserDomain))
        {
            errors.Add("Default user domain is not configured.");
        }

        if (!string.IsNullOrWhiteSpace(ManagerEmail) && !EmailPattern().IsMatch(ManagerEmail))
        {
            errors.Add("Manager email must be a valid email address.");
        }

        if (StartDate is not null && StartDate.Value < DateOnly.FromDateTime(DateTime.UtcNow.Date))
        {
            errors.Add("Start date cannot be in the past.");
        }

        return errors.Count == 0
            ? ValidationResult.Valid()
            : ValidationResult.Invalid(errors);
    }

    public OnboardingRequestRecord ToRecord(string defaultUserDomain)
    {
        var firstName = FirstName!.Trim();
        var lastName = LastName!.Trim();
        var displayName = $"{firstName} {lastName}";
        var upnPrefix = $"{firstName}.{lastName}".ToLowerInvariant();
        var normalizedUpnPrefix = UpnUnsafeCharacters().Replace(upnPrefix, string.Empty);

        return new OnboardingRequestRecord
        {
            Id = Guid.NewGuid(),
            FirstName = firstName,
            LastName = lastName,
            DisplayName = displayName,
            UserPrincipalName = $"{normalizedUpnPrefix}@{defaultUserDomain.Trim()}",
            JobTitle = JobTitle?.Trim(),
            Department = Department?.Trim(),
            ManagerEmail = ManagerEmail?.Trim(),
            StartDate = StartDate,
            RequestedProfile = RequestedProfile?.Trim(),
            Notes = Notes?.Trim(),
            Status = OnboardingRequestStatus.PendingApproval,
            CreatedOn = DateTimeOffset.UtcNow,
            UpdatedOn = DateTimeOffset.UtcNow
        };
    }

    [GeneratedRegex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex EmailPattern();

    [GeneratedRegex("[^a-z0-9._-]", RegexOptions.Compiled)]
    private static partial Regex UpnUnsafeCharacters();
}
