namespace BasicTeamsAppInfDeploy.Application;

public sealed record ValidationResult(bool IsValid, IReadOnlyCollection<string> Errors)
{
    public static ValidationResult Valid()
    {
        return new(true, Array.Empty<string>());
    }

    public static ValidationResult Invalid(IReadOnlyCollection<string> errors)
    {
        return new(false, errors);
    }
}
