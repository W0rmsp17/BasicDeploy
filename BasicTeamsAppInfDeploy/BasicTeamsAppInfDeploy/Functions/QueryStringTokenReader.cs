using System.Net;
using Microsoft.Azure.Functions.Worker.Http;

namespace BasicTeamsAppInfDeploy.Functions;

internal static class QueryStringTokenReader
{
    public static string GetToken(HttpRequestData request)
    {
        var query = request.Url.Query.TrimStart('?');
        if (string.IsNullOrWhiteSpace(query))
        {
            return string.Empty;
        }

        foreach (var pair in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var parts = pair.Split('=', 2);
            if (parts.Length == 2 && parts[0].Equals("token", StringComparison.OrdinalIgnoreCase))
            {
                return WebUtility.UrlDecode(parts[1]);
            }
        }

        return string.Empty;
    }
}
