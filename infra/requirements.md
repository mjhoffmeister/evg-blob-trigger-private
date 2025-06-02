# Infrastructure requirements for Event Grid secure delivery

## Overview

Terraform scripts for implementing the secure delivery of Event Grid blob
created events to an Azure Function utilizing managed identity, Event Hub, and
private endpoints ([Deliver events to Event Hubs using managed identity](https://learn.microsoft.com/en-us/azure/event-grid/deliver-events-using-managed-identity#deliver-events-to-event-hubs-using-managed-identity)).

## Core requirements

### Style, naming, and guidelines

1. Create clean, well-documented Terraform scripts that adhere to [HashiCorp style guide](https://developer.hashicorp.com/terraform/language/style) best practices
1. Use the [Azure Naming](https://github.com/Azure/terraform-azurerm-naming/)
module for naming wherever possible with the following convention for Azure
resources: `{resource abbreviation}-evgblobtrigpvt-{region}`. For example:
`vnet-evgblobtrigpvt-westus2`
1. Use
[Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/) when available
1. Optimize cost while still utilizing production-level service tiers and SKUs
1. Use a single region (default: `westus2`) for all services and don't enable zone redundancy
1. Follow Terraform deployment workflow: `terraform validate` → `terraform plan` → `terraform apply`
1. Use consistent variable definitions with proper descriptions, types, and default values
1. Implement proper output values for resource IDs, endpoints, and connection strings

### Terraform backend

Use the following remote backend configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateschemata"
    container_name       = "tfstate"
    key                  = "evg-blob-trigger-private.tfstate"
    use_oidc             = true
  }
}
```

### Required Terraform providers

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}
```

### Architecture

#### Core Infrastructure
1. **Resource Group**: Central container for all resources
1. **Virtual Network**: Single VNet with properly sized subnets:
   - Private endpoints subnet (`10.0.1.0/24`)
   - Function App subnet (`10.0.2.0/24`) 
   - Additional subnet for future expansion (`10.0.3.0/24`)
1. **Private DNS Zones**: For storage account and function app resolution

#### Storage and Event Grid
1. **Storage Account**: 
   - Standard_LRS tier for cost optimization
   - Private endpoint for blob sub-resource
   - Public network access disabled
   - Blob soft delete enabled (7 days retention)
1. **Event Grid System Topic**: 
   - For BlobCreated events on the storage account
   - System-assigned managed identity enabled
1. **Event Grid Subscription**:
   - Filtered for BlobCreated events
   - Delivery to Event Hub with managed identity authentication

#### Event Hub
1. **Event Hub Namespace**: 
   - Standard tier (1 throughput unit for cost optimization)
   - Managed identity authentication enabled
1. **Event Hub**: Single hub for blob events
1. **Authorization Rules**: For Event Grid system topic access

#### Azure Function
1. **App Service Plan**: 
   - Consumption plan for cost optimization
   - Windows-based for .NET compatibility
1. **Function App**:
   - .NET 8 runtime
   - System-assigned managed identity
   - Private endpoint enabled
   - VNet integration for outbound connectivity
   - Application Insights integration
1. **Storage Account**: Dedicated for Function App runtime (separate from blob storage)

#### Security and Access Control
1. **Role Assignments**:
   - Event Grid system topic → Event Hub Data Sender role
   - Function App → Storage Blob Data Reader role (for processing blobs)
   - Function App → Event Hub Data Receiver role
1. **Network Security**:
   - All resources secured with private endpoints where applicable
   - Network Security Groups on subnets with minimal required rules
   - Public access disabled on storage accounts

#### Variables and Configuration
Define the following input variables:
- `location` (default: "westus2")
- `environment` (default: "dev") 
- `project_name` (default: "evgblobtrigpvt")
- `blob_container_name` (default: "uploads")

#### Outputs
Provide the following outputs:
- Storage account name and blob endpoint
- Event Hub namespace and hub names  
- Function App name and URL
- Private endpoint IP addresses
- Resource group name

## Deployment Workflow

### Prerequisites
1. Install Terraform using `winget install Hashicorp.Terraform`
2. Authenticate to Azure using `az login` or service principal
3. Ensure the remote backend storage account exists and is accessible

### Deployment Steps
1. Initialize Terraform: `terraform init`
2. Validate configuration: `terraform validate`
3. Plan deployment: `terraform plan -out=tfplan`
4. Review plan output carefully
5. Apply changes: `terraform apply tfplan`
6. Verify resources in Azure Portal

### Post-Deployment Verification
1. Test blob upload to storage account
2. Verify Event Grid events are delivered to Event Hub
3. Confirm Function App can process events
4. Check private endpoint connectivity

## Cost Optimization Guidelines

### Service Tiers (Production-Ready but Cost-Optimized)
- **Storage Account**: Standard_LRS (locally redundant)
- **Event Hub Namespace**: Standard (1 throughput unit)
- **App Service Plan**: Consumption (serverless)
- **Function App**: Consumption tier with Application Insights Basic
- **Private Endpoints**: Standard tier

### Estimated Monthly Cost
- Storage Account: ~$5-10 (depending on usage)
- Event Hub Standard: ~$12
- Function App Consumption: ~$0-5 (first 1M executions free)
- Private Endpoints: ~$7 per endpoint
- **Total estimated**: ~$40-60/month

## Resource Sizing and Limits

### Network Configuration
- **VNet Address Space**: `10.0.0.0/16`
- **Private Endpoints Subnet**: `10.0.1.0/24` (251 available IPs)
- **Function App Subnet**: `10.0.2.0/24` (251 available IPs)
- **Reserved Subnet**: `10.0.3.0/24` (for future expansion)

### Storage Account Configuration
- **Performance**: Standard
- **Replication**: LRS (Locally Redundant Storage)
- **Access Tier**: Hot
- **Blob Soft Delete**: 7 days retention
- **Container Access**: Private

### Event Hub Configuration
- **Throughput Units**: 1 (can auto-scale if needed)
- **Message Retention**: 1 day (minimum for Standard)
- **Partition Count**: 2 (default)

## Terraform File Structure

Organize code into the following files:
- `main.tf`: Main resource definitions
- `variables.tf`: Input variable definitions
- `outputs.tf`: Output value definitions
- `providers.tf`: Provider configurations
- `locals.tf`: Local value computations
- `terraform.tfvars.example`: Example variable values