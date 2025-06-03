# Event Grid Blob Trigger with Private Endpoints

This repository demonstrates how to build a secure, private Azure Event Grid system that processes blob storage events using Azure Functions with complete network isolation.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌───────────────────┐
│   Blob Storage  │───▶│   Event Grid     │───▶│   Event Hub     │───▶│  Azure Function │
│  (Private EP)   │    │  System Topic    │    │   Namespace     │    │  (VNet Integrated)│
└─────────────────┘    └──────────────────┘    └─────────────────┘    └───────────────────┘
         │                                                                       │
         └───────────────────────────────────────────────────────────────────────┘
                              Private Virtual Network
```

### Key Features

✅ **Complete Network Isolation**: All components communicate through private endpoints  
✅ **RBAC Authentication**: No connection strings, uses managed identity throughout  
✅ **Dual Access Modes**: Public mode for development, private mode for production  
✅ **Structured Logging**: OpenTelemetry integration with Application Insights  
✅ **Infrastructure as Code**: Complete Terraform configuration  
✅ **End-to-End Testing**: Automated test scripts for both access modes  

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.0
- .NET 8.0 SDK
- Azure Functions Core Tools v4

### 1. Deploy Public Mode (Development)

```bash
# Clone and navigate to repository
git clone <repo-url>
cd evg-blob-trigger-private

# Deploy infrastructure in public mode
cd infra
terraform init
terraform apply -var-file="terraform.tfvars.public" -auto-approve

# Deploy function code
cd ../src
func azure functionapp publish func-evgblobtrigger-westus2 --csharp
```

### 2. Run Tests

```bash
# Run end-to-end tests
cd ../tests
.\Run-E2ETest.ps1
```

### 3. Deploy Private Mode (Production)

```bash
# Switch to private mode
cd ../infra
terraform apply -var-file="terraform.tfvars.private" -auto-approve

# Test private mode via jumpbox (see Private Mode Testing section)
```

## 📁 Repository Structure

```
evg-blob-trigger-private/
├── 📁 infra/                          # Terraform infrastructure
│   ├── main.tf                        # Main infrastructure configuration
│   ├── variables.tf                   # Variable definitions
│   ├── locals.tf                      # Local values and naming
│   ├── outputs.tf                     # Output values
│   ├── terraform.tfvars.public        # Public mode configuration
│   └── terraform.tfvars.private       # Private mode configuration
├── 📁 src/                            # .NET 8.0 Azure Function App
│   ├── BlobEventFunction.cs           # Event Hub trigger function
│   ├── HealthCheckFunction.cs         # Health check endpoints
│   ├── Program.cs                     # OpenTelemetry configuration
│   ├── BlobEventProcessor.csproj      # Project dependencies
│   └── host.json                      # Function host configuration
├── 📁 tests/                          # Test scripts and data
│   ├── Run-E2ETest.ps1               # End-to-end test automation
│   ├── Simple-Upload-Test.ps1        # Basic upload test
│   └── sample-data/                   # Test files
└── README.md                          # This file
```

## 🔧 Configuration

### Access Modes

| Mode | Use Case | Network Access | Authentication |
|------|----------|---------------|---------------|
| **Public** | Development, Testing | Internet accessible | RBAC + Public endpoints |
| **Private** | Production, Secure | VNet only | RBAC + Private endpoints |

### Key Configuration Files

- **`terraform.tfvars.public`**: Development configuration with public access
- **`terraform.tfvars.private`**: Production configuration with private endpoints
- **`main.tf`**: Infrastructure definition with conditional private/public resources

## 🔒 Private Mode Features

### Network Security
- **Private Endpoints**: Storage and Function App accessible only within VNet
- **VNet Integration**: Function App can securely access private resources
- **Network Isolation**: All communication through private IP addresses
- **Service Endpoints**: Enhanced security for storage account access

### Access Methods
- **Azure Bastion**: Secure RDP access to jumpbox VM
- **Jumpbox VM**: Windows Server 2022 for administration
- **Private DNS**: Internal name resolution for private endpoints

### Testing Private Mode

1. **Connect via Bastion**: Use Azure Portal to connect to jumpbox VM
2. **Run Tests**: Execute test scripts from within the private network
3. **Monitor**: Check Application Insights for event processing

See `tests/Private-Mode-Testing-Instructions.md` for detailed steps.

## 📊 Monitoring & Observability

### Application Insights Integration
- **Structured Logging**: OpenTelemetry for comprehensive telemetry
- **Custom Metrics**: Event processing counters and performance data
- **Error Tracking**: Detailed exception logging and correlation
- **Dependency Tracking**: Monitor calls to storage and Event Hub

### Key Metrics to Monitor
- Event processing latency
- Function execution success rate
- Storage access patterns
- Network connectivity health

## 🧪 Testing

### Automated Tests
- **End-to-End**: Complete pipeline from blob upload to function execution
- **Health Checks**: Function app health and readiness endpoints
- **Private Mode**: Network isolation verification

### Test Files Included
- `sample-text.txt`: Simple text file for basic testing
- `sample-data.json`: JSON payload for structured data testing
- `Run-E2ETest.ps1`: Comprehensive test automation

## 🛠️ Customization

### Scaling Configuration
```hcl
# In terraform.tfvars files
eventhub_capacity = 2           # Scale Event Hub throughput
jumpbox_vm_size = "Standard_B4s" # Larger jumpbox if needed
```

### Network Configuration
```hcl
# Customize IP ranges in terraform.tfvars
vnet_address_space = ["10.0.0.0/16"]
private_endpoints_subnet_cidr = "10.0.1.0/24"
function_app_subnet_cidr = "10.0.2.0/24"
```

### Function App Settings
Modify `src/Program.cs` for custom OpenTelemetry configuration or add new functions following the established patterns.

## 🚨 Troubleshooting

### Common Issues

#### 1. Function App Not Receiving Events
- **Check**: Event Grid subscription is active
- **Verify**: Event Hub authorization rules and RBAC assignments
- **Monitor**: Application Insights for function execution logs

#### 2. Private Mode Connectivity Issues
- **Verify**: VNet integration is properly configured
- **Check**: Private DNS zone configuration
- **Test**: Network connectivity from jumpbox VM

#### 3. Storage Access Denied
- **Confirm**: Managed identity has correct storage roles
- **Check**: Network rules allow function app subnet
- **Verify**: Service endpoints are configured on subnets

### Debug Commands

```bash
# Check function app status
az functionapp show --name <function-app-name> --resource-group <rg-name>

# Verify private endpoint connections
az network private-endpoint show --name <pe-name> --resource-group <rg-name>

# Test DNS resolution from jumpbox
nslookup <function-app-name>.azurewebsites.net
```

## 📚 Additional Resources

- [Azure Event Grid Documentation](https://docs.microsoft.com/en-us/azure/event-grid/)
- [Azure Functions Networking Options](https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options)
- [Private Endpoints Overview](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [OpenTelemetry in .NET](https://docs.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel)

---
