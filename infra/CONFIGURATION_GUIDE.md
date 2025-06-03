# Terraform Configuration Files

This directory contains different Terraform variable files for different deployment scenarios:

## Configuration Files

### `terraform.tfvars.example`
- **Purpose**: Template file showing all available variables
- **Usage**: Copy to `terraform.tfvars` and customize as needed
- **Contains**: All possible configuration options with documentation

### `terraform.tfvars.private`
- **Purpose**: Private access mode configuration
- **Features**:
  - Private endpoints for Storage Account and Function App
  - VNet integration for Function App
  - Network restrictions (deny public access)
  - Azure Bastion and jumpbox VM for secure management
  - Enhanced security posture
- **Use Case**: Production environments, high-security requirements
- **Cost**: Higher (includes Bastion, jumpbox VM, private endpoints)

### `terraform.tfvars.public`
- **Purpose**: Public access mode configuration
- **Features**:
  - Public endpoints for all resources
  - No private endpoints or VNet integration
  - No Bastion or jumpbox resources
  - Simplified networking
- **Use Case**: Development, testing, proof-of-concept
- **Cost**: Lower (minimal networking resources)

## Usage Instructions

### Deploy with Private Access Mode
```bash
# Copy the private configuration
cp terraform.tfvars.private terraform.tfvars

# Customize variables if needed (optional)
nano terraform.tfvars

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### Deploy with Public Access Mode
```bash
# Copy the public configuration
cp terraform.tfvars.public terraform.tfvars

# Customize variables if needed (optional)
nano terraform.tfvars

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### Switch Between Modes
```bash
# To switch from public to private mode
cp terraform.tfvars.private terraform.tfvars
terraform plan  # Review changes
terraform apply

# To switch from private to public mode
cp terraform.tfvars.public terraform.tfvars
terraform plan  # Review changes
terraform apply
```

## Variable Explanations

### Access Mode Control Variables

| Variable | Private Mode | Public Mode | Description |
|----------|-------------|-------------|-------------|
| `enable_private_access` | `true` | `false` | Controls private endpoints and network restrictions |
| `allow_public_blob_access` | `false` | `true` | Allows public blob access when private mode disabled |
| `function_app_public_network_access` | `false` | `true` | Controls Function App public network access |
| `create_bastion_jumpbox` | `true` | `false` | Controls creation of Bastion and jumpbox resources |

## Resource Impact by Mode

### Private Mode Resources
- ✅ Private endpoints for Storage and Function App
- ✅ Private DNS zones and virtual network links
- ✅ Azure Bastion and jumpbox VM
- ✅ Network security groups with restrictive rules
- ✅ VNet integration for Function App

### Public Mode Resources
- ❌ No private endpoints
- ❌ No private DNS zones
- ❌ No Bastion or jumpbox
- ✅ Simplified network security groups
- ❌ No VNet integration

## Security Considerations

### Private Mode
- **Pros**: Enhanced security, network isolation, compliance-ready
- **Cons**: Higher complexity, requires VPN/ExpressRoute for remote access
- **Best for**: Production, sensitive data, compliance requirements

### Public Mode
- **Pros**: Simple setup, easy development access, lower cost
- **Cons**: Resources accessible from internet, reduced security
- **Best for**: Development, testing, proof-of-concept

## Cost Implications

### Private Mode Additional Costs
- Azure Bastion: ~$140/month
- Jumpbox VM (Standard_B2s): ~$60/month
- Private endpoints: ~$15/month each
- Private DNS zones: ~$1/month each

### Public Mode Savings
- No Bastion, jumpbox, or private endpoint costs
- Estimated savings: ~$200+/month

Choose the appropriate mode based on your security requirements, compliance needs, and budget constraints.
