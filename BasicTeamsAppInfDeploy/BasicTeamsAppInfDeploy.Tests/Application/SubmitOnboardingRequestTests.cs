using BasicTeamsAppInfDeploy.Application;

namespace BasicTeamsAppInfDeploy.Tests.Application;

public sealed class SubmitOnboardingRequestTests
{
    [Fact]
    public void Validate_ReturnsErrors_WhenRequiredFieldsAreMissing()
    {
        var request = new SubmitOnboardingRequest();

        var result = request.Validate("CholbingDevoutlook.onmicrosoft.com");

        Assert.False(result.IsValid);
        Assert.Contains("First name is required.", result.Errors);
        Assert.Contains("Last name is required.", result.Errors);
    }

    [Fact]
    public void Validate_ReturnsError_WhenManagerEmailIsInvalid()
    {
        var request = new SubmitOnboardingRequest
        {
            FirstName = "Alex",
            LastName = "Wilber",
            ManagerEmail = "not-an-email"
        };

        var result = request.Validate("CholbingDevoutlook.onmicrosoft.com");

        Assert.False(result.IsValid);
        Assert.Contains("Manager email must be a valid email address.", result.Errors);
    }

    [Fact]
    public void Validate_ReturnsError_WhenStartDateIsInPast()
    {
        var request = new SubmitOnboardingRequest
        {
            FirstName = "Alex",
            LastName = "Wilber",
            StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-1)).ToString("yyyy-MM-dd")
        };

        var result = request.Validate("CholbingDevoutlook.onmicrosoft.com");

        Assert.False(result.IsValid);
        Assert.Contains("Start date cannot be in the past.", result.Errors);
    }

    [Fact]
    public void Validate_ReturnsError_WhenStartDateFormatIsInvalid()
    {
        var request = new SubmitOnboardingRequest
        {
            FirstName = "Alex",
            LastName = "Wilber",
            StartDate = "tomorrow"
        };

        var result = request.Validate("CholbingDevoutlook.onmicrosoft.com");

        Assert.False(result.IsValid);
        Assert.Contains("Start date must use yyyy-MM-dd format.", result.Errors);
    }

    [Fact]
    public void ToRecord_NormalizesDisplayNameAndUserPrincipalName()
    {
        var request = new SubmitOnboardingRequest
        {
            FirstName = " Alex ",
            LastName = " Wilber ",
            JobTitle = " Support Analyst ",
            Department = " Operations ",
            ManagerEmail = " manager@CholbingDevoutlook.onmicrosoft.com ",
            StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(7)).ToString("yyyy-MM-dd"),
            RequestedProfile = " Standard ",
            Notes = " Test onboarding request "
        };

        var record = request.ToRecord("CholbingDevoutlook.onmicrosoft.com");

        Assert.Equal("Alex Wilber", record.DisplayName);
        Assert.Equal("alex.wilber@CholbingDevoutlook.onmicrosoft.com", record.UserPrincipalName);
        Assert.Equal("Support Analyst", record.JobTitle);
        Assert.Equal("Operations", record.Department);
        Assert.Equal("manager@CholbingDevoutlook.onmicrosoft.com", record.ManagerEmail);
        Assert.Equal("Standard", record.RequestedProfile);
        Assert.Equal("Test onboarding request", record.Notes);
        Assert.Equal(OnboardingRequestStatus.PendingApproval, record.Status);
    }

    [Fact]
    public void ToRecord_UsesProvidedUserPrincipalNamePrefix()
    {
        var request = new SubmitOnboardingRequest
        {
            FirstName = "Alex",
            LastName = "Wilber",
            UserPrincipalNamePrefix = " a.wilber ",
            StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(7)).ToString("yyyy-MM-dd")
        };

        var record = request.ToRecord("CholbingDevoutlook.onmicrosoft.com");

        Assert.Equal("a.wilber@CholbingDevoutlook.onmicrosoft.com", record.UserPrincipalName);
    }

    [Fact]
    public void Validate_ReturnsError_WhenUserPrincipalNamePrefixContainsInvalidCharacters()
    {
        var request = new SubmitOnboardingRequest
        {
            FirstName = "Alex",
            LastName = "Wilber",
            UserPrincipalNamePrefix = "alex@wilber"
        };

        var result = request.Validate("CholbingDevoutlook.onmicrosoft.com");

        Assert.False(result.IsValid);
        Assert.Contains("UPN prefix can contain only letters, numbers, periods, underscores, and hyphens.", result.Errors);
    }
}
