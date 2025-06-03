using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Azure.Monitor.OpenTelemetry.AspNetCore;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

// Configure OpenTelemetry with Azure Monitor (Application Insights)
builder.Services.AddOpenTelemetry()
    .UseAzureMonitor();

// Add structured logging
builder.Services.AddLogging();

builder.Build().Run();
