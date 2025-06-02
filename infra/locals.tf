locals {
  # Common naming convention
  naming_prefix = "${var.project_name}-${var.environment}-${var.location}"

  # Resource names using Azure naming conventions
  resource_group_name = "rg-${local.naming_prefix}"

  # Networking
  vnet_name                     = "vnet-${local.naming_prefix}"
  private_endpoints_subnet_name = "snet-pe-${local.naming_prefix}"
  function_app_subnet_name      = "snet-func-${local.naming_prefix}"
  reserved_subnet_name          = "snet-reserved-${local.naming_prefix}"
  nsg_pe_name                   = "nsg-pe-${local.naming_prefix}"
  nsg_func_name                 = "nsg-func-${local.naming_prefix}"

  # Storage
  storage_account_name      = "st${replace(local.naming_prefix, "-", "")}"
  func_storage_account_name = "stfunc${replace(local.naming_prefix, "-", "")}"

  # Event Grid
  eventgrid_topic_name        = "evgt-${local.naming_prefix}"
  eventgrid_subscription_name = "evgs-${local.naming_prefix}"

  # Event Hub
  eventhub_namespace_name = "evhns-${local.naming_prefix}"
  eventhub_name           = "evh-${local.naming_prefix}"

  # Function App
  app_service_plan_name = "asp-${local.naming_prefix}"
  function_app_name     = "func-${local.naming_prefix}"

  # Application Insights
  app_insights_name = "appi-${local.naming_prefix}"

  # Private DNS Zones
  storage_private_dns_zone_name = "privatelink.blob.core.windows.net"
  sites_private_dns_zone_name   = "privatelink.azurewebsites.net"

  # Private Endpoints
  storage_private_endpoint_name = "pe-st-${local.naming_prefix}"
  func_private_endpoint_name    = "pe-func-${local.naming_prefix}"

  # Bastion and Jumpbox
  bastion_subnet_name = "AzureBastionSubnet" # This name is required by Azure
  jumpbox_subnet_name = "snet-jumpbox-${local.naming_prefix}"
  bastion_name        = "bas-${local.naming_prefix}"
  bastion_pip_name    = "pip-bas-${local.naming_prefix}"
  jumpbox_vm_name     = "vm-jumpbox-${local.naming_prefix}"
  jumpbox_nic_name    = "nic-jumpbox-${local.naming_prefix}"
  jumpbox_nsg_name    = "nsg-jumpbox-${local.naming_prefix}"

  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment
    Location    = var.location
    Project     = var.project_name
  })
}
