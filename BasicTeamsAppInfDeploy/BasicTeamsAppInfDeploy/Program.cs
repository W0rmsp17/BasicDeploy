using BasicTeamsAppInfDeploy.Application;
using BasicTeamsAppInfDeploy.Infrastructure;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        services.AddSingleton<IOnboardingRequestStore, TableStorageOnboardingRequestStore>();
        services.AddSingleton<IApprovalTokenService, HmacApprovalTokenService>();
        services.AddSingleton<IApprovalNotifier, LoggingApprovalNotifier>();
        services.AddSingleton<IUserProvisioningService, LoggingUserProvisioningService>();
    })
    .Build();

host.Run();
