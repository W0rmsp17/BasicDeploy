namespace BasicTeamsAppInfDeploy.Application;

public sealed record ApprovalTokenValidationResult(
    bool IsValid,
    Guid RequestId,
    ApprovalAction Action,
    string? Error)
{
    public static ApprovalTokenValidationResult Invalid(string error)
    {
        return new(false, Guid.Empty, ApprovalAction.Deny, error);
    }
}
