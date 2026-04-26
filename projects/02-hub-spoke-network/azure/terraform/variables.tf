variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  default = "hub-spoke-net"
}

variable "location" {
  default = "Southeast Asia"
}

variable "environment" {
  description = "Environment name (dev, staging, prod) — used in tags"
  default     = "dev"
}

variable "owner" {
  description = "Owner / responsible person — used in tags"
  default     = "kien"
}

# --- Network ---

variable "hub_vnet_cidr" {
  default = "10.0.0.0/16"
}

variable "spoke_vnet_cidr" {
  default = "10.1.0.0/16"
}

variable "bastion_subnet_cidr" {
  description = "Bastion requires the subnet name 'AzureBastionSubnet' and CIDR >= /26"
  default     = "10.0.1.0/26"
}

variable "appgw_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "vm_subnet_cidr" {
  default = "10.1.1.0/24"
}

variable "pe_subnet_cidr" {
  description = "Private Endpoint subnet — must disable network policies"
  default     = "10.1.2.0/24"
}

# --- VM ---

variable "vm_size" {
  description = "Linux VM size (D2alds_v7 ~$90/mo)"
  # Spec: 2c_4g
  default     = "Standard_D2alds_v7"
}

variable "vm_admin_username" {
  default = "azureuser"
}

# --- Toggles for expensive resources ---

variable "enable_bastion" {
  description = "Azure Bastion ~$4.5/day — toggle on only when actively learning"
  type        = bool
  default     = false
}

variable "enable_app_gateway" {
  description = "Application Gateway Standard_v2 ~$10/day — toggle on only when actively learning"
  type        = bool
  default     = false
}

# --- Monitor ---

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  default     = 30
}
