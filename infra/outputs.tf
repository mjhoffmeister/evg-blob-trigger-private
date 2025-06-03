output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account_name" {
  description = "Name of the main storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the main storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_container_name" {
  description = "Name of the blob container"
  value       = azurerm_storage_container.main.name
}

output "eventhub_namespace_name" {
  description = "Name of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.name
}

output "eventhub_namespace_id" {
  description = "ID of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.id
}

output "eventhub_name" {
  description = "Name of the Event Hub"
  value       = azurerm_eventhub.main.name
}

output "eventhub_id" {
  description = "ID of the Event Hub"
  value       = azurerm_eventhub.main.id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_windows_function_app.main.name
}

output "function_app_id" {
  description = "ID of the Function App"
  value       = azurerm_windows_function_app.main.id
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_windows_function_app.main.default_hostname
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${azurerm_windows_function_app.main.default_hostname}"
}

output "eventgrid_system_topic_name" {
  description = "Name of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.storage.name
}

output "eventgrid_system_topic_id" {
  description = "ID of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.storage.id
}

output "eventgrid_subscription_name" {
  description = "Name of the Event Grid subscription"
  value       = azurerm_eventgrid_event_subscription.storage_to_eventhub.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "private_endpoints_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "function_app_subnet_id" {
  description = "ID of the function app subnet"
  value       = azurerm_subnet.function_app.id
}

output "storage_private_endpoint_ip" {
  description = "Private IP address of the storage private endpoint"
  value       = var.enable_private_access ? azurerm_private_endpoint.storage[0].private_service_connection[0].private_ip_address : null
}

output "function_app_private_endpoint_ip" {
  description = "Private IP address of the function app private endpoint"
  value       = var.enable_private_access ? azurerm_private_endpoint.function_app[0].private_service_connection[0].private_ip_address : null
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "bastion_name" {
  description = "Name of the Azure Bastion host"
  value       = var.create_bastion_jumpbox ? azurerm_bastion_host.main[0].name : null
}

output "bastion_id" {
  description = "ID of the Azure Bastion host"
  value       = var.create_bastion_jumpbox ? azurerm_bastion_host.main[0].id : null
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = var.create_bastion_jumpbox ? azurerm_public_ip.bastion[0].ip_address : null
}

output "jumpbox_vm_name" {
  description = "Name of the jumpbox virtual machine"
  value       = var.create_bastion_jumpbox ? azurerm_windows_virtual_machine.jumpbox[0].name : null
}

output "jumpbox_vm_id" {
  description = "ID of the jumpbox virtual machine"
  value       = var.create_bastion_jumpbox ? azurerm_windows_virtual_machine.jumpbox[0].id : null
}

output "jumpbox_private_ip" {
  description = "Private IP address of the jumpbox VM"
  value       = var.create_bastion_jumpbox ? azurerm_network_interface.jumpbox[0].private_ip_address : null
}

output "jumpbox_admin_username" {
  description = "Admin username for the jumpbox VM"
  value       = var.create_bastion_jumpbox ? azurerm_windows_virtual_machine.jumpbox[0].admin_username : null
}

output "bastion_subnet_id" {
  description = "ID of the Bastion subnet"
  value       = var.create_bastion_jumpbox ? azurerm_subnet.bastion[0].id : null
}

output "jumpbox_subnet_id" {
  description = "ID of the jumpbox subnet"
  value       = var.create_bastion_jumpbox ? azurerm_subnet.jumpbox[0].id : null
}
