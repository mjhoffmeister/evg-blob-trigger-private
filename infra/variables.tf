variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "westus2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "evgblobpvt"
}

variable "blob_container_name" {
  description = "Name of the blob container to monitor for events"
  type        = string
  default     = "uploads"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_endpoints_subnet_cidr" {
  description = "CIDR block for private endpoints subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "function_app_subnet_cidr" {
  description = "CIDR block for function app subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "reserved_subnet_cidr" {
  description = "CIDR block for reserved subnet (future expansion)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "storage_account_tier" {
  description = "Storage account performance tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "eventhub_sku" {
  description = "Event Hub namespace SKU"
  type        = string
  default     = "Standard"
}

variable "eventhub_capacity" {
  description = "Event Hub namespace throughput units"
  type        = number
  default     = 1
}

variable "function_app_runtime" {
  description = "Function app runtime stack"
  type        = string
  default     = "dotnet"
}

variable "function_app_version" {
  description = "Function app runtime version"
  type        = string
  default     = "8"
}

variable "app_service_plan_sku" {
  description = "App Service Plan SKU - Y1 for Consumption, EP1/EP2/EP3 for Premium (required for VNet integration)"
  type        = string
  default     = "Y1"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "EventGridBlobTrigger"
    ManagedBy   = "Terraform"
  }
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Azure Bastion subnet (must be named AzureBastionSubnet)"
  type        = string
  default     = "10.0.4.0/24"
}

variable "jumpbox_subnet_cidr" {
  description = "CIDR block for jumpbox subnet"
  type        = string
  default     = "10.0.5.0/24"
}

variable "jumpbox_vm_size" {
  description = "Size of the jumpbox virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "jumpbox_admin_username" {
  description = "Admin username for the jumpbox VM"
  type        = string
  default     = "azureuser"
}

variable "jumpbox_admin_password" {
  description = "Admin password for the jumpbox VM (use Azure Key Vault in production)"
  type        = string
  default     = "P@ssw0rd123!"
  sensitive   = true
}

# Access Mode Configuration
variable "enable_private_access" {
  description = "Enable private access mode. When true, resources will use private endpoints and restrict public access."
  type        = bool
  default     = true
}

variable "allow_public_blob_access" {
  description = "Allow public access to blob storage. Only effective when enable_private_access is false."
  type        = bool
  default     = false
}

variable "function_app_public_network_access" {
  description = "Allow public network access to Function App. When false, only VNet integrated access is allowed."
  type        = bool
  default     = false
}

variable "create_bastion_jumpbox" {
  description = "Create Azure Bastion and jumpbox VM for accessing private resources. Recommended when enable_private_access is true."
  type        = bool
  default     = true
}
