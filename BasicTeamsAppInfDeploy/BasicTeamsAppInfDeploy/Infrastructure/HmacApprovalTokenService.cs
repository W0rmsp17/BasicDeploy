using System.Security.Cryptography;
using System.Text;
using BasicTeamsAppInfDeploy.Application;
using Microsoft.Extensions.Configuration;

namespace BasicTeamsAppInfDeploy.Infrastructure;

public sealed class HmacApprovalTokenService(IConfiguration configuration) : IApprovalTokenService
{
    private const char Separator = '.';
    private readonly string _signingKey = configuration["Approval:TokenSigningKey"]
        ?? throw new InvalidOperationException("Approval:TokenSigningKey is required.");

    public string CreateToken(Guid requestId, ApprovalAction action, DateTimeOffset expiresOn)
    {
        var payload = $"{requestId:N}|{action}|{expiresOn.ToUnixTimeSeconds()}";
        var signature = Sign(payload);

        return $"{Base64UrlEncode(payload)}{Separator}{Base64UrlEncode(signature)}";
    }

    public ApprovalTokenValidationResult ValidateToken(string token, ApprovalAction expectedAction)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return ApprovalTokenValidationResult.Invalid("Token is required.");
        }

        var parts = token.Split(Separator);
        if (parts.Length != 2)
        {
            return ApprovalTokenValidationResult.Invalid("Token format is invalid.");
        }

        var payload = Base64UrlDecodeToString(parts[0]);
        var suppliedSignature = Base64UrlDecodeToString(parts[1]);
        var expectedSignature = Sign(payload);

        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(suppliedSignature),
                Encoding.UTF8.GetBytes(expectedSignature)))
        {
            return ApprovalTokenValidationResult.Invalid("Token signature is invalid.");
        }

        var payloadParts = payload.Split('|');
        if (payloadParts.Length != 3)
        {
            return ApprovalTokenValidationResult.Invalid("Token payload is invalid.");
        }

        if (!Guid.TryParseExact(payloadParts[0], "N", out var requestId))
        {
            return ApprovalTokenValidationResult.Invalid("Token request id is invalid.");
        }

        if (!Enum.TryParse<ApprovalAction>(payloadParts[1], out var action))
        {
            return ApprovalTokenValidationResult.Invalid("Token action is invalid.");
        }

        if (action != expectedAction)
        {
            return ApprovalTokenValidationResult.Invalid("Token action does not match the requested operation.");
        }

        if (!long.TryParse(payloadParts[2], out var expiresUnix))
        {
            return ApprovalTokenValidationResult.Invalid("Token expiry is invalid.");
        }

        var expiresOn = DateTimeOffset.FromUnixTimeSeconds(expiresUnix);
        if (expiresOn <= DateTimeOffset.UtcNow)
        {
            return ApprovalTokenValidationResult.Invalid("Token has expired.");
        }

        return new ApprovalTokenValidationResult(true, requestId, action, null);
    }

    private string Sign(string payload)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_signingKey));
        return Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(payload)));
    }

    private static string Base64UrlEncode(string value)
    {
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(value))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
    }

    private static string Base64UrlDecodeToString(string value)
    {
        var padded = value.Replace('-', '+').Replace('_', '/');
        padded = padded.PadRight(padded.Length + ((4 - (padded.Length % 4)) % 4), '=');
        return Encoding.UTF8.GetString(Convert.FromBase64String(padded));
    }
}
