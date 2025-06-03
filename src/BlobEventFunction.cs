using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Azure.Messaging.EventHubs;

namespace BlobEventProcessor;

/// <summary>
/// Azure Function that processes Event Grid blob creation events delivered via
/// Event Hub.
/// Performs structured logging to Application Insights using OpenTelemetry.
/// </summary>
public class BlobEventFunction
{
    private readonly ILogger<BlobEventFunction> _logger;

    /// <summary>
    /// Constructor for dependency injection of logger.
    /// </summary>
    public BlobEventFunction(ILogger<BlobEventFunction> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Azure Function entry point. Triggered by Event Hub messages containing
    /// Event Grid events.
    /// </summary>
    /// <param name="events">Array of EventData from Event Hub.</param>
    [Function("ProcessBlobEvents")]
    public void Run(
        [EventHubTrigger("%EVENTHUB_NAME%", Connection = "EventHubConnection")]
        EventData[] events)
    {
        foreach (var eventData in events)
        {
            try
            {
                // Parse the Event Grid event from Event Hub Body
                var eventJsonString = System.Text.Encoding.UTF8.GetString(
                    eventData.Body.Span);

                // Event Hub messages contain an array of Event Grid events
                var eventGridEvents = JsonSerializer
                    .Deserialize<EventGridEvent[]>(eventJsonString);

                if (eventGridEvents != null)
                {
                    foreach (var eventGridEvent in eventGridEvents)
                    {
                        if (eventGridEvent?.EventType ==
                            "Microsoft.Storage.BlobCreated")
                        {
                            // Deserialize the Data property from JsonElement
                            var blobData = JsonSerializer
                                .Deserialize<BlobCreatedEventData>(
                                    eventGridEvent.Data.GetRawText());

                            // Extract blob name from the URL
                            var blobName =
                                ExtractBlobNameFromUrl(blobData?.Url);

                            // Structured logging with OpenTelemetry
                            _logger.LogInformation(
                                "Blob created event processed: {BlobName} in " +
                                "container {ContainerName} at {EventTime}",
                                blobName,
                                GetContainerNameFromUrl(blobData?.Url),
                                eventGridEvent.EventTime);
                        }
                        else
                        {
                            _logger.LogWarning(
                                "Received unexpected event type: {EventType}",
                                eventGridEvent?.EventType);
                        }
                    }
                }
            }
            catch (JsonException ex)
            {
                _logger.LogError(
                    ex, "Failed to parse event data from Event Hub");
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex, "Error processing blob event from Event Hub");
            }
        }
    }

    /// <summary>
    /// Extracts the blob name from a blob URL.
    /// </summary>
    /// <param name="blobUrl">The full URL of the blob.</param>
    /// <returns>The blob name, or null if extraction fails.</returns>
    private static string? ExtractBlobNameFromUrl(string? blobUrl)
    {
        if (string.IsNullOrEmpty(blobUrl))
            return null;

        try
        {
            var uri = new Uri(blobUrl);
            var segments = uri.Segments;

            // The blob name is typically the last segment of the URL
            return segments.Length > 2 ? segments[^1] : null;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Extracts the container name from a blob URL.
    /// </summary>
    /// <param name="blobUrl">The full URL of the blob.</param>
    /// <returns>The container name, or null if extraction fails.</returns>
    private static string? GetContainerNameFromUrl(string? blobUrl)
    {
        if (string.IsNullOrEmpty(blobUrl))
            return null;

        try
        {
            var uri = new Uri(blobUrl);
            var segments = uri.Segments;
            // Get the second to last segment (container name)
            return segments.Length > 1 ? segments[^2].TrimEnd('/') : null;
        }
        catch
        {
            return null;
        }
    }
}

/// <summary>
/// Model for Event Grid events as delivered via Event Hub.
/// </summary>
public class EventGridEvent
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("eventType")]
    public string EventType { get; set; } = string.Empty;

    [JsonPropertyName("subject")]
    public string Subject { get; set; } = string.Empty;

    [JsonPropertyName("eventTime")]
    public DateTime EventTime { get; set; }

    [JsonPropertyName("data")]
    public JsonElement Data { get; set; }

    [JsonPropertyName("dataVersion")]
    public string DataVersion { get; set; } = string.Empty;

    [JsonPropertyName("metadataVersion")]
    public string MetadataVersion { get; set; } = string.Empty;

    [JsonPropertyName("topic")]
    public string Topic { get; set; } = string.Empty;
}

/// <summary>
/// Model for the Data property of a BlobCreated Event Grid event.
/// </summary>
public class BlobCreatedEventData
{
    [JsonPropertyName("api")]
    public string? Api { get; set; }

    [JsonPropertyName("clientRequestId")]
    public string? ClientRequestId { get; set; }

    [JsonPropertyName("requestId")]
    public string? RequestId { get; set; }

    [JsonPropertyName("eTag")]
    public string? ETag { get; set; }

    [JsonPropertyName("contentType")]
    public string? ContentType { get; set; }

    [JsonPropertyName("contentLength")]
    public long? ContentLength { get; set; }

    [JsonPropertyName("blobType")]
    public string? BlobType { get; set; }

    [JsonPropertyName("url")]
    public string? Url { get; set; }

    [JsonPropertyName("sequencer")]
    public string? Sequencer { get; set; }

    [JsonPropertyName("storageDiagnostics")]
    public Dictionary<string, object>? StorageDiagnostics { get; set; }
}
