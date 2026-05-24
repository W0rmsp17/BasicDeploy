using System.Text.RegularExpressions;

namespace BasicTeamsAppInfDeploy.Application;

public sealed partial record SubmitOnboardingRequest
{
    public string? FirstName { get; init; }

    public string? LastName { get; init; }

    public string? JobTitle { get; init; }

    public string? Department { get; init; }

    public string? ManagerEmail { get; init; }

    public string? StartDate { get; init; }

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

        var parsedStartDate = ParseStartDate();
        if (!string.IsNullOrWhiteSpace(StartDate) && parsedStartDate is null)
        {
            errors.Add("Start date must use yyyy-MM-dd format.");
        }

        if (parsedStartDate is not null && parsedStartDate.Value < DateOnly.FromDateTime(DateTime.UtcNow.Date))
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

        var parsedStartDate = ParseStartDate();

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
            StartDate = parsedStartDate,
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

    private DateOnly? ParseStartDate()
    {
        if (string.IsNullOrWhiteSpace(StartDate))
        {
            return null;
        }

        return DateOnly.TryParseExact(
            StartDate.Trim(),
            "yyyy-MM-dd",
            out var parsed)
            ? parsed
            : null;
    }
}
