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
        services.AddSingleton<IGraphTokenProvider, MsalGraphTokenProvider>();
        services.AddHttpClient<GraphApprovalNotifier>();
        services.AddHttpClient<GraphUserProvisioningService>();
        services.AddSingleton<IApprovalNotifier>(serviceProvider =>
        {
            var configuration = serviceProvider.GetRequiredService<IConfiguration>();
            var provider = configuration["Approval:Provider"] ?? "Logging";

            return provider.Equals("Graph", StringComparison.OrdinalIgnoreCase)
                ? serviceProvider.GetRequiredService<GraphApprovalNotifier>()
                : serviceProvider.GetRequiredService<LoggingApprovalNotifier>();
        });
        services.AddSingleton<LoggingApprovalNotifier>();
        services.AddSingleton<IUserProvisioningService>(serviceProvider =>
        {
            var configuration = serviceProvider.GetRequiredService<IConfiguration>();
            var provider = configuration["Provisioning:Provider"] ?? "Logging";

            return provider.Equals("Graph", StringComparison.OrdinalIgnoreCase)
                ? serviceProvider.GetRequiredService<GraphUserProvisioningService>()
                : serviceProvider.GetRequiredService<LoggingUserProvisioningService>();
        });
        services.AddSingleton<LoggingUserProvisioningService>();
    })
    .Build();

host.Run();
