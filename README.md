# Event Grid Blob Trigger with Private Endpoints

This repository demonstrates a secure Azure Event Grid system that processes blob storage events using Azure Functions with complete network isolation. The architecture is designed for private, enterprise-grade deployments with a public testing mode available for initial validation.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌───────────────────┐
│   Blob Storage  │───▶│   Event Grid     │───▶│   Event Hub     │───▶│  Azure Function │
│  (Private EP)   │    │  System Topic    │    │   Namespace     │    │  (VNet Integrated)│
└─────────────────┘    └──────────────────┘    └─────────────────┘    └───────────────────┘
         │                                                                       │
         └───────────────────────────────────────────────────────────────────────┘
                              Private Virtual Network (10.0.0.0/16)
```

### Key Features

✅ **Complete Network Isolation**: All components communicate through private endpoints in a dedicated VNet  
✅ **RBAC Authentication**: No connection strings, uses managed identity throughout  
✅ **Private-First Design**: Optimized for production deployment with private endpoints  
✅ **Public Testing Mode**: Available for initial validation and development  
✅ **Structured Logging**: OpenTelemetry integration with Application Insights  
✅ **Infrastructure as Code**: Complete Terraform configuration with dual access modes

## 🚀 Getting Started

This solution's architecture is designed for demonstration purposes. The
Terraform scripts are helpful for understanding it, but they would need to be
modified to be valid for existing Azure environments. 

### Prerequisites

- Azure CLI or Azure PowerShell
- Terraform >= 1.0
- .NET 8.0 SDK (for local development)
- Azure Functions Core Tools v4 (for local development)

### Infrastructure Deployment

The infrastructure supports two deployment modes:

#### Private Mode (Production)
- **Purpose**: Production deployment with complete network isolation
- **Configuration**: Use `terraform.tfvars.private`
- **App Service Plan**: Premium (EP1) to support VNet integration
- **Access**: All components communicate through private endpoints

#### Public Mode (Testing Only)  
- **Purpose**: Initial validation and testing
- **Configuration**: Use `terraform.tfvars.public`
- **App Service Plan**: Consumption (Y1) for cost-effective testing
- **Access**: Internet-accessible endpoints for easier testing

## 📁 Repository Structure

```
evg-blob-trigger-private/
├── 📁 infra/                          # Terraform infrastructure
│   ├── main.tf                        # Main infrastructure configuration
│   ├── variables.tf                   # Variable definitions
│   ├── locals.tf                      # Local values and naming
│   ├── outputs.tf                     # Output values
│   ├── providers.tf                   # Provider configuration
│   ├── terraform.tfvars.public        # Public mode configuration (testing)
│   └── terraform.tfvars.private       # Private mode configuration (production)
├── 📁 src/                            # .NET 8.0 Azure Function App
│   ├── BlobEventFunction.cs           # Event Hub trigger function
│   ├── HealthCheckFunction.cs         # Health check endpoints
│   ├── Program.cs                     # OpenTelemetry configuration
│   ├── BlobEventProcessor.csproj      # Project dependencies
│   ├── local.settings.json            # Local development settings
│   └── host.json                      # Function host configuration
├── .gitignore                         # Git ignore rules
├── evg-blob-trigger-private.sln       # Visual Studio solution
└── README.md                          # This documentation
```

## 🔧 Configuration

### Deployment Modes

| Mode | Use Case | App Service Plan | Network Access | Authentication |
|------|----------|------------------|---------------|---------------|
| **Private** | Production | Premium (EP1) | VNet only | RBAC + Private endpoints |
| **Public** | Testing Only | Consumption (Y1) | Internet accessible | RBAC + Public endpoints |

### Key Configuration Files

- **`terraform.tfvars.private`**: Production configuration with private endpoints and Premium plan
- **`terraform.tfvars.public`**: Testing configuration with public access and Consumption plan  
- **`main.tf`**: Infrastructure definition with conditional private/public resources

## 🔒 Private Mode Architecture (Production)

### Network Security Components
- **Private Endpoints**: Storage (10.0.1.4) and Function App (10.0.1.5) accessible only within VNet
- **VNet Integration**: Function App integrated with dedicated subnet for secure resource access
- **Network Isolation**: All communication through private IP addresses within 10.0.0.0/16 address space
- **Service Endpoints**: Enhanced security for storage account access from function subnet

### Network Topology
```
Virtual Network (10.0.0.0/16)
├── Private Endpoints Subnet (10.0.1.0/24)
│   ├── Storage Account Private Endpoint (10.0.1.4)
│   └── Function App Private Endpoint (10.0.1.5)
├── Function App Subnet (10.0.2.0/24)
│   └── VNet-Integrated Function App
└── Jumpbox Subnet (10.0.3.0/24)
    └── Windows VM for Administration
```

### Access Methods
- **Azure Bastion**: Secure RDP access to jumpbox VM without public IP
- **Jumpbox VM**: Windows Server 2022 for administration and testing within private network
- **Private DNS**: Internal name resolution for private endpoints (*.privatelink.azurewebsites.net)

### Security Features
- **Zero Public Access**: Storage account completely isolated from internet
- **RBAC-Only Authentication**: No connection strings, all access via managed identity
- **Premium Plan**: EP1 plan required for VNet integration capabilities

## 📊 Monitoring & Observability

### Application Insights Integration
- **Structured Logging**: OpenTelemetry for comprehensive telemetry collection
- **Custom Metrics**: Event processing counters and performance data
- **Error Tracking**: Detailed exception logging with correlation IDs
- **Dependency Tracking**: Monitor calls to storage, Event Hub, and other Azure services

### Key Metrics to Monitor
- Event processing latency and throughput
- Function execution success rate and duration
- Storage access patterns and errors
- Network connectivity health in private mode
- Resource utilization across Premium plan instances

### Telemetry Configuration
The function app includes pre-configured OpenTelemetry instrumentation for:
- Azure Functions runtime metrics
- HTTP request/response tracking
- Custom business metrics for blob event processing
- Distributed tracing across Event Grid → Event Hub → Function flow

## 🧪 Testing & Validation

### Function Endpoints
The function app includes built-in endpoints for testing and monitoring:
- **Health Check**: `/api/health` - Returns function app health status
- **Ping**: `/api/ping` - Simple connectivity test
- **Event Processing**: Automatic via Event Hub trigger

### Public Mode Testing
Use public mode for initial validation:
1. Deploy with `terraform.tfvars.public`
2. Upload test files directly to storage account
3. Monitor Application Insights for event processing
4. Validate end-to-end flow before switching to private mode

### Private Mode Validation
After deploying private mode:
1. Connect to jumpbox VM via Azure Bastion
2. Test internal connectivity to private endpoints
3. Upload files from within the VNet to validate private access
4. Monitor logs to ensure events are processed correctly

## 🛠️ Customization

### Scaling Configuration
```hcl
# In terraform.tfvars files
eventhub_capacity = 2                    # Scale Event Hub throughput units
jumpbox_vm_size = "Standard_B4s"        # Larger jumpbox for heavy workloads
app_service_plan_sku = "EP2"            # Scale up Function App plan if needed
```

### Network Configuration
```hcl
# Customize IP ranges in terraform.tfvars files
vnet_address_space = ["10.0.0.0/16"]           # Main VNet CIDR
private_endpoints_subnet_cidr = "10.0.1.0/24"  # Private endpoints subnet
function_app_subnet_cidr = "10.0.2.0/24"       # Function App VNet integration
jumpbox_subnet_cidr = "10.0.3.0/24"            # Jumpbox administration subnet
```

### Function App Configuration
- **OpenTelemetry**: Modify `src/Program.cs` for custom telemetry configuration
- **Event Processing**: Extend `BlobEventFunction.cs` for additional event types
- **Health Checks**: Add custom health endpoints in `HealthCheckFunction.cs`
- **Dependencies**: Update `BlobEventProcessor.csproj` for additional NuGet packages

## 🚨 Troubleshooting

### Common Issues

#### 1. Function App Not Receiving Events
- **Check**: Event Grid subscription status and Event Hub namespace health
- **Verify**: Managed identity RBAC assignments (Event Hub Data Receiver role)
- **Monitor**: Application Insights for function execution logs and errors
- **Validate**: Event Hub trigger configuration and connection settings

#### 2. Private Mode Connectivity Issues
- **Verify**: VNet integration is properly configured on Function App
- **Check**: Private DNS zone has correct A records for private endpoints
- **Test**: Network connectivity from jumpbox VM using `Test-NetConnection`
- **Confirm**: Private endpoints show "Approved" connection state

#### 3. Storage Access Denied in Private Mode
- **Confirm**: Managed identity has Storage Blob Data Reader role
- **Check**: Storage account network rules allow function app subnet
- **Verify**: Service endpoints are configured on function app subnet
- **Test**: Storage access from jumpbox VM to verify private endpoint

#### 4. Performance Issues
- **Monitor**: Application Insights performance counters and traces
- **Check**: Event Hub throughput units vs. incoming event volume
- **Review**: Function App scaling settings and consumption patterns
- **Analyze**: Network latency between private endpoints

### Debug Commands

```powershell
# Check function app status and configuration
az functionapp show --name <function-app-name> --resource-group <rg-name>

# Verify private endpoint connections
az network private-endpoint show --name <pe-name> --resource-group <rg-name>

# Test DNS resolution from jumpbox
nslookup <function-app-name>.azurewebsites.net
Test-NetConnection <function-app-name>.azurewebsites.net -Port 443

# Check VNet integration
az functionapp vnet-integration list --name <function-app-name> --resource-group <rg-name>
```

### Monitoring Queries (Application Insights)
```kusto
// Function execution summary
requests
| where timestamp > ago(1h)
| summarize count(), avg(duration) by name
| order by count_ desc

// Event processing errors
exceptions
| where timestamp > ago(1h)
| where cloud_RoleName == "your-function-app-name"
| project timestamp, type, outerMessage, innerException
```

## 📚 Additional Resources

- [Azure Event Grid Documentation](https://docs.microsoft.com/en-us/azure/event-grid/)
- [Azure Functions Networking Options](https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options)
- [Private Endpoints Overview](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [OpenTelemetry in .NET](https://docs.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel)

---
