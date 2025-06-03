# Blob Event Processor Function App

A .NET 8.0 Azure Function App that processes blob creation events delivered via Event Hub and logs structured data to Application Insights using OpenTelemetry.

## Features

- **Event Hub Trigger**: Processes blob creation events from Event Grid delivered via Event Hub
- **Structured Logging**: Uses OpenTelemetry integration with Application Insights for comprehensive observability
- **Health Check Endpoints**: Provides HTTP endpoints for application health monitoring
- **Isolated Worker Model**: Uses the latest .NET 8.0 isolated process model for Azure Functions

## Functions

### 1. ProcessBlobEvents (Event Hub Trigger)
- **Trigger**: Event Hub named `evh-evgblobpvt-westus2`
- **Purpose**: Processes blob creation events and logs structured data
- **Logged Information**:
  - Blob name and container
  - Event timestamp
  - Blob URL and size
  - Event correlation data

### 2. HealthCheck (HTTP Trigger)
- **Endpoint**: `GET /api/health`
- **Purpose**: Returns detailed health status of the Function App
- **Response**: JSON with status, timestamp, version, and environment information

### 3. Ping (HTTP Trigger)
- **Endpoint**: `GET /api/ping`
- **Purpose**: Simple endpoint for basic availability checks
- **Response**: Plain text "pong"

## Configuration

### Local Development
Update `local.settings.json` with the following connection strings:

```json
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
        "EventHubConnection": "Endpoint=sb://your-eventhub-namespace.servicebus.windows.net/;SharedAccessKeyName=key-name;SharedAccessKey=key-value",
        "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=your-instrumentation-key;IngestionEndpoint=https://region.in.applicationinsights.azure.com/;LiveEndpoint=https://region.livediagnostics.monitor.azure.com/"
    }
}
```

### Azure Deployment
Configure the following application settings in your Function App:

- `EventHubConnection`: Connection string to your Event Hub namespace
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights connection string

## Dependencies

- Microsoft.Azure.Functions.Worker (2.0.0)
- Microsoft.Azure.Functions.Worker.Extensions.EventHubs (6.3.6)
- Azure.Monitor.OpenTelemetry.AspNetCore (1.3.0)
- Microsoft.Extensions.Logging (9.0.0)

## Running Locally

1. Ensure you have the Azure Functions Core Tools installed
2. Update `local.settings.json` with your connection strings
3. Run the Function App:
   ```powershell
   func start
   ```

## Testing

### Health Check
```powershell
curl http://localhost:7071/api/health
```

### Ping
```powershell
curl http://localhost:7071/api/ping
```

## Monitoring

The Function App uses OpenTelemetry to send structured logs and telemetry to Application Insights. You can monitor:

- Function execution metrics
- Blob processing events with correlation data
- Custom logging scopes with blob metadata
- Performance and error tracking

## Event Processing Flow

1. Blob created in Azure Storage
2. Event Grid captures the event
3. Event is forwarded to Event Hub
4. Function App processes the event from Event Hub
5. Structured logging to Application Insights via OpenTelemetry

## Troubleshooting

- Verify Event Hub connection string in application settings
- Check Application Insights connection string configuration  
- Monitor Application Insights for function execution logs
- Use health check endpoints to verify Function App availability
