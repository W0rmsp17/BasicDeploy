using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;

namespace BasicTeamsAppInfDeploy.Functions;

public sealed class ApprovalFunctionOutput
{
    [QueueOutput("create-user", Connection = "AzureWebJobsStorage")]
    public string? CreateUserCommand { get; init; }

    public required HttpResponseData HttpResponse { get; init; }
}
