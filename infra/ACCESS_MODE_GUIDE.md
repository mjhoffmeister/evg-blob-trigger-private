# Access Mode Toggle Configuration

This Terraform infrastructure supports both **public** and **private** access modes through configuration variables. You can easily switch between these modes based on your requirements.

## Configuration Variables

### Primary Toggle Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_private_access` | bool | `true` | Enables private access mode with private endpoints and restricted network access |
| `allow_public_blob_access` | bool | `false` | Allows public access to blob storage (only effective when `enable_private_access = false`) |
| `function_app_public_network_access` | bool | `false` | Allows public network access to Function App |
| `create_bastion_jumpbox` | bool | `true` | Creates Azure Bastion and jumpbox VM for accessing private resources |

## Access Modes

### Private Access Mode (Default)
When `enable_private_access = true`:

✅ **What's created:**
- Private endpoints for Storage Account and Function App
- Private DNS zones for blob storage and sites
- VNet integration for Function App
- Network rules blocking public access to storage
- Optional Bastion and jumpbox for secure access

✅ **Benefits:**
- Enhanced security through private connectivity
- No public endpoints exposed
- Traffic stays within Azure backbone
- Compliance with enterprise security policies

⚠️ **Considerations:**
- Requires VPN or Bastion for management access
- Higher cost due to private endpoints
- More complex networking setup

### Public Access Mode
When `enable_private_access = false`:

✅ **What's created:**
- Public endpoints for Storage Account and Function App
- No private endpoints or private DNS zones
- Simplified networking configuration
- Optional public blob access

✅ **Benefits:**
- Lower cost (no private endpoint charges)
- Simpler setup and troubleshooting
- Direct public access for development/testing
- Easier integration with external services

⚠️ **Considerations:**
- Public endpoints exposed to internet
- Requires additional security measures
- May not meet enterprise compliance requirements

## Configuration Examples

### 1. Full Private Mode (Production Recommended)
```hcl
# Private access with Bastion for management
enable_private_access = true
allow_public_blob_access = false
function_app_public_network_access = false
create_bastion_jumpbox = true
```

### 2. Private Mode without Bastion (VPN Access)
```hcl
# Private access for environments with existing VPN
enable_private_access = true
allow_public_blob_access = false
function_app_public_network_access = false
create_bastion_jumpbox = false
```

### 3. Public Mode for Development
```hcl
# Public access for development and testing
enable_private_access = false
allow_public_blob_access = true
function_app_public_network_access = true
create_bastion_jumpbox = false
```

### 4. Hybrid Mode
```hcl
# Private storage with public Function App access
enable_private_access = true
allow_public_blob_access = false
function_app_public_network_access = true
create_bastion_jumpbox = true
```

## Resource Impact by Mode

### Resources Created in Private Mode Only
- `azurerm_private_endpoint.storage`
- `azurerm_private_endpoint.function_app`
- `azurerm_private_dns_zone.storage`
- `azurerm_private_dns_zone.sites`
- `azurerm_private_dns_zone_virtual_network_link.storage`
- `azurerm_private_dns_zone_virtual_network_link.sites`

### Resources Created with Bastion/Jumpbox Only
- `azurerm_public_ip.bastion`
- `azurerm_bastion_host.main`
- `azurerm_subnet.bastion`
- `azurerm_subnet.jumpbox`
- `azurerm_network_security_group.jumpbox`
- `azurerm_network_interface.jumpbox`
- `azurerm_windows_virtual_machine.jumpbox`

### Resources Always Created
- Resource Group
- Virtual Network and core subnets
- Storage Accounts
- Event Grid and Event Hub resources
- Function App and App Service Plan
- Application Insights
- Network Security Groups (core)
- Role assignments

## Cost Implications

### Private Mode Costs
- **Private Endpoints**: ~$7.30/month per endpoint (2 endpoints = ~$14.60/month)
- **Bastion Host**: ~$87.60/month (if enabled)
- **Jumpbox VM**: ~$14.60/month for Standard_B2s (if enabled)
- **Additional data processing**: Minimal impact

### Public Mode Costs
- **No private endpoint fees**
- **No Bastion costs** (if disabled)
- **Lower overall monthly cost**

## Security Considerations

### Private Mode Security Features
- All traffic flows through private networks
- No public IP addresses on storage or function resources
- DNS resolution points to private IPs
- Network Security Groups provide additional protection
- Azure Bastion provides secure RDP access without exposing VMs

### Public Mode Security Measures
- Storage account still supports network restrictions
- Function App can be configured with access restrictions
- HTTPS enforcement on all public endpoints
- Azure Active Directory integration for authentication
- Monitor with Application Insights and Azure Monitor

## Deployment Instructions

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars with your desired mode:**
   ```bash
   # Set your preferred access mode
   enable_private_access = true  # or false
   create_bastion_jumpbox = true  # or false
   
   # Configure other variables as needed
   ```

3. **Deploy the infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Switching Between Modes

You can switch between access modes by updating the variables and redeploying:

1. **Update terraform.tfvars** with new mode settings
2. **Run terraform plan** to review changes
3. **Run terraform apply** to implement changes

⚠️ **Important:** Switching from private to public mode or vice versa will recreate resources. Plan for downtime during the switch.

## Troubleshooting

### Private Mode Issues
- **Cannot access resources**: Ensure you're connected via VPN or using Bastion
- **DNS resolution problems**: Check private DNS zone configuration
- **Function app connectivity**: Verify VNet integration and route tables

### Public Mode Issues
- **Access denied**: Check network rules and firewall settings
- **Function app not accessible**: Verify public network access is enabled
- **Storage access problems**: Ensure public blob access is configured correctly

## Best Practices

1. **Use private mode for production environments**
2. **Enable Bastion for secure management access in private mode**
3. **Use public mode only for development/testing**
4. **Implement proper monitoring and alerting regardless of mode**
5. **Regularly review and audit access patterns**
6. **Use Azure Key Vault for sensitive configuration (passwords, connection strings)**
7. **Enable diagnostic logging for all resources**
