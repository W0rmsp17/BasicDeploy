using BasicTeamsAppInfDeploy.Application;
using BasicTeamsAppInfDeploy.Infrastructure;

namespace BasicTeamsAppInfDeploy.Tests.Infrastructure;

public sealed class GraphProvisioningValueFactoryTests
{
    [Fact]
    public void CreateMailNickname_UsesSanitizedUpnPrefix()
    {
        var request = CreateRequest("alex.wilber+contractor@CholbingDevoutlook.onmicrosoft.com");

        var nickname = GraphProvisioningValueFactory.CreateMailNickname(request);

        Assert.Equal("alex.wilbercontractor", nickname);
    }

    [Fact]
    public void CreateTemporaryPassword_IncludesRequiredCharacterClasses()
    {
        var password = GraphProvisioningValueFactory.CreateTemporaryPassword();

        Assert.Equal(20, password.Length);
        Assert.Contains(password, char.IsUpper);
        Assert.Contains(password, char.IsLower);
        Assert.Contains(password, char.IsDigit);
        Assert.Contains(password, character => "!@$%*-_".Contains(character));
    }

    private static OnboardingRequestRecord CreateRequest(string userPrincipalName)
    {
        return new OnboardingRequestRecord
        {
            Id = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
            FirstName = "Alex",
            LastName = "Wilber",
            DisplayName = "Alex Wilber",
            UserPrincipalName = userPrincipalName,
            Status = OnboardingRequestStatus.PendingApproval,
            CreatedOn = DateTimeOffset.UtcNow
        };
    }
}
