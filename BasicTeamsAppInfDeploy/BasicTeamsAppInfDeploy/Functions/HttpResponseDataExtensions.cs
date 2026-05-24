using System.Net;
using Microsoft.Azure.Functions.Worker.Http;

namespace BasicTeamsAppInfDeploy.Functions;

internal static class HttpResponseDataExtensions
{
    public static async Task<HttpResponseData> WriteJsonAsync(
        this HttpRequestData request,
        HttpStatusCode statusCode,
        object body,
        CancellationToken cancellationToken)
    {
        var response = request.CreateResponse(statusCode);
        await response.WriteAsJsonAsync(body, cancellationToken);
        return response;
    }
}
