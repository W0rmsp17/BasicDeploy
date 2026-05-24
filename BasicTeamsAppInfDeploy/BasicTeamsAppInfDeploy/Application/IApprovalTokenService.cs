namespace BasicTeamsAppInfDeploy.Application;

public interface IApprovalTokenService
{
    string CreateToken(Guid requestId, ApprovalAction action, DateTimeOffset expiresOn);

    ApprovalTokenValidationResult ValidateToken(string token, ApprovalAction expectedAction);
}
