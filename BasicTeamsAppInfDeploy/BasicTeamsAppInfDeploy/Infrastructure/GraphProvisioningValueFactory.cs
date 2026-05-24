using System.Security.Cryptography;
using BasicTeamsAppInfDeploy.Application;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public static class GraphProvisioningValueFactory
{
    private const string Lower = "abcdefghijkmnopqrstuvwxyz";
    private const string Upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    private const string Digits = "23456789";
    private const string Symbols = "!@$%*-_";

    public static string CreateMailNickname(OnboardingRequestRecord request)
    {
        var upnPrefix = request.UserPrincipalName.Split('@', 2)[0];
        var sanitized = new string(upnPrefix
            .Where(character => char.IsLetterOrDigit(character) || character is '.' or '_' or '-')
            .ToArray());

        return string.IsNullOrWhiteSpace(sanitized)
            ? $"user{request.Id:N}"[..20]
            : sanitized;
    }

    public static string CreateTemporaryPassword()
    {
        Span<char> password = stackalloc char[20];
        password[0] = Upper[RandomNumberGenerator.GetInt32(Upper.Length)];
        password[1] = Lower[RandomNumberGenerator.GetInt32(Lower.Length)];
        password[2] = Digits[RandomNumberGenerator.GetInt32(Digits.Length)];
        password[3] = Symbols[RandomNumberGenerator.GetInt32(Symbols.Length)];

        var all = Lower + Upper + Digits + Symbols;
        for (var index = 4; index < password.Length; index++)
        {
            password[index] = all[RandomNumberGenerator.GetInt32(all.Length)];
        }

        RandomNumberGenerator.Shuffle(password);

        return new string(password);
    }
}
