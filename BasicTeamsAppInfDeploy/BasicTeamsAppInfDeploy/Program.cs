using BasicTeamsAppInfDeploy.Application;
using BasicTeamsAppInfDeploy.Infrastructure;
using Microsoft.Extensions.Configuration;
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
        services.AddHttpClient<GraphApprovalNotifier>();
        services.AddSingleton<IApprovalNotifier>(serviceProvider =>
        {
            var configuration = serviceProvider.GetRequiredService<IConfiguration>();
            var provider = configuration["Approval:Provider"] ?? "Logging";

            return provider.Equals("Graph", StringComparison.OrdinalIgnoreCase)
                ? serviceProvider.GetRequiredService<GraphApprovalNotifier>()
                : serviceProvider.GetRequiredService<LoggingApprovalNotifier>();
        });
        services.AddSingleton<LoggingApprovalNotifier>();
        services.AddSingleton<IUserProvisioningService, LoggingUserProvisioningService>();
    })
    .Build();

host.Run();
