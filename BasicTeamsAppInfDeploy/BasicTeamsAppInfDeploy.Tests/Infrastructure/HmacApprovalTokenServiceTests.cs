using BasicTeamsAppInfDeploy.Application;
using BasicTeamsAppInfDeploy.Infrastructure;
using Microsoft.Extensions.Configuration;

namespace BasicTeamsAppInfDeploy.Tests.Infrastructure;

public sealed class HmacApprovalTokenServiceTests
{
    [Fact]
    public void ValidateToken_ReturnsValidResult_ForMatchingActionAndUnexpiredToken()
    {
        var service = CreateService();
        var requestId = Guid.NewGuid();
        var token = service.CreateToken(
            requestId,
            ApprovalAction.Approve,
            DateTimeOffset.UtcNow.AddMinutes(5));

        var result = service.ValidateToken(token, ApprovalAction.Approve);

        Assert.True(result.IsValid);
        Assert.Equal(requestId, result.RequestId);
        Assert.Equal(ApprovalAction.Approve, result.Action);
    }

    [Fact]
    public void ValidateToken_ReturnsInvalidResult_WhenActionDoesNotMatch()
    {
        var service = CreateService();
        var token = service.CreateToken(
            Guid.NewGuid(),
            ApprovalAction.Approve,
            DateTimeOffset.UtcNow.AddMinutes(5));

        var result = service.ValidateToken(token, ApprovalAction.Deny);

        Assert.False(result.IsValid);
        Assert.Equal("Token action does not match the requested operation.", result.Error);
    }

    [Fact]
    public void ValidateToken_ReturnsInvalidResult_WhenTokenIsExpired()
    {
        var service = CreateService();
        var token = service.CreateToken(
            Guid.NewGuid(),
            ApprovalAction.Approve,
            DateTimeOffset.UtcNow.AddMinutes(-5));

        var result = service.ValidateToken(token, ApprovalAction.Approve);

        Assert.False(result.IsValid);
        Assert.Equal("Token has expired.", result.Error);
    }

    private static HmacApprovalTokenService CreateService()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Approval:TokenSigningKey"] = "unit-test-signing-key"
            })
            .Build();

        return new HmacApprovalTokenService(configuration);
    }
}
