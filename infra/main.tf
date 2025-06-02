# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Network Security Groups
resource "azurerm_network_security_group" "private_endpoints" {
  name                = local.nsg_pe_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowInboundPrivateEndpoints"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "function_app" {
  name                = local.nsg_func_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowOutboundHTTPS"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutboundEventHub"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5671-5672"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Jumpbox
resource "azurerm_network_security_group" "jumpbox" {
  name                = local.jumpbox_nsg_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# Subnets
resource "azurerm_subnet" "private_endpoints" {
  name                 = local.private_endpoints_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoints_subnet_cidr]
}

resource "azurerm_subnet" "function_app" {
  name                 = local.function_app_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.function_app_subnet_cidr]

  delegation {
    name = "Microsoft.Web.serverFarms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "reserved" {
  name                 = local.reserved_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.reserved_subnet_cidr]
}

resource "azurerm_subnet" "bastion" {
  name                 = local.bastion_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_subnet" "jumpbox" {
  name                 = local.jumpbox_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.jumpbox_subnet_cidr]
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

resource "azurerm_subnet_network_security_group_association" "function_app" {
  subnet_id                 = azurerm_subnet.function_app.id
  network_security_group_id = azurerm_network_security_group.function_app.id
}

resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = azurerm_subnet.jumpbox.id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "storage" {
  name                = local.storage_private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "sites" {
  name                = local.sites_private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Link Private DNS Zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "storage-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sites" {
  name                  = "sites-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sites.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Storage Account for blob events
resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Blob properties
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
    versioning_enabled = true
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.common_tags
}

# Storage Container
resource "azurerm_storage_container" "main" {
  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Function App Storage Account
resource "azurerm_storage_account" "function_app" {
  name                     = local.func_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Allow public access for Function App runtime
  public_network_access_enabled = true

  tags = local.common_tags
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = local.storage_private_endpoint_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "storage-private-connection"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }

  tags = local.common_tags
}

# Event Grid System Topic
resource "azurerm_eventgrid_system_topic" "storage" {
  name                   = local.eventgrid_topic_name
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  source_arm_resource_id = azurerm_storage_account.main.id
  topic_type             = "Microsoft.Storage.StorageAccounts"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Event Hub Namespace
resource "azurerm_eventhub_namespace" "main" {
  name                = local.eventhub_namespace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.eventhub_sku
  capacity            = var.eventhub_capacity

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Event Hub
resource "azurerm_eventhub" "main" {
  name                = local.eventhub_name
  namespace_id        = azurerm_eventhub_namespace.main.id
  partition_count     = 2
  message_retention   = 1
}

# Event Hub Authorization Rule for Event Grid
resource "azurerm_eventhub_authorization_rule" "eventgrid" {
  name                = "EventGridSender"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = azurerm_resource_group.main.name
  listen              = false
  send                = true
  manage              = false
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  retention_in_days   = 30

  tags = local.common_tags
}

# App Service Plan (Consumption)
resource "azurerm_service_plan" "main" {
  name                = local.app_service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Windows"
  sku_name            = "Y1"

  tags = local.common_tags
}

# Function App
resource "azurerm_windows_function_app" "main" {
  name                = local.function_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.function_app.name
  storage_account_access_key = azurerm_storage_account.function_app.primary_access_key
  service_plan_id            = azurerm_service_plan.main.id

  # VNet integration
  virtual_network_subnet_id = azurerm_subnet.function_app.id

  site_config {
    application_stack {
      dotnet_version = var.function_app_version
    }

    # Enable VNet route all for outbound traffic
    vnet_route_all_enabled = true

    application_insights_key               = azurerm_application_insights.main.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.main.connection_string
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"   = var.function_app_runtime
    "WEBSITE_RUN_FROM_PACKAGE"   = "1"
    "EVENTHUB_CONNECTION_STRING" = azurerm_eventhub_authorization_rule.eventgrid.primary_connection_string
    "STORAGE_ACCOUNT_NAME"       = azurerm_storage_account.main.name
    "STORAGE_CONTAINER_NAME"     = azurerm_storage_container.main.name
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Private Endpoint for Function App
resource "azurerm_private_endpoint" "function_app" {
  name                = local.func_private_endpoint_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "function-private-connection"
    private_connection_resource_id = azurerm_windows_function_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "function-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sites.id]
  }

  tags = local.common_tags
}

# Role Assignment: Event Grid System Topic -> Event Hub Data Sender
resource "azurerm_role_assignment" "eventgrid_to_eventhub" {
  scope                = azurerm_eventhub_namespace.main.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_eventgrid_system_topic.storage.identity[0].principal_id
}

# Role Assignment: Function App -> Storage Blob Data Reader
resource "azurerm_role_assignment" "function_to_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_function_app.main.identity[0].principal_id
}

# Role Assignment: Function App -> Event Hub Data Receiver
resource "azurerm_role_assignment" "function_to_eventhub" {
  scope                = azurerm_eventhub_namespace.main.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_windows_function_app.main.identity[0].principal_id
}

# Event Grid Subscription
resource "azurerm_eventgrid_event_subscription" "storage_to_eventhub" {
  name  = local.eventgrid_subscription_name
  scope = azurerm_storage_account.main.id

  event_delivery_schema = "EventGridSchema"

  included_event_types = [
    "Microsoft.Storage.BlobCreated"
  ]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.blob_container_name}/"
  }

  eventhub_endpoint_id = azurerm_eventhub.main.id

  delivery_identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_role_assignment.eventgrid_to_eventhub
  ]
}

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  name                = local.bastion_pip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  name                = local.bastion_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.common_tags
}

# Network Interface for Jumpbox VM
resource "azurerm_network_interface" "jumpbox" {
  name                = local.jumpbox_nic_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "jumpbox-ip-config"
    subnet_id                     = azurerm_subnet.jumpbox.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

# Jumpbox Virtual Machine
resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                = local.jumpbox_vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.jumpbox_vm_size
  admin_username      = var.jumpbox_admin_username
  admin_password      = var.jumpbox_admin_password

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk"
    version   = "latest"
  }

  tags = local.common_tags
}
