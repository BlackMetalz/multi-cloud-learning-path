variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  default = "fullstack-app"
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

# --- App Service ---

variable "app_service_sku" {
  description = "App Service Plan SKU (F1 = free tier)"
  default     = "F1"
}

# --- Monitor ---

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  default     = 30
}

# --- Key Vault ---

variable "kv_soft_delete_days" {
  description = "Key Vault soft delete retention in days (min 7)"
  default     = 7
}

# --- PostgreSQL ---

variable "postgres_version" {
  description = "PostgreSQL major version"
  default     = "16"
}

variable "postgres_sku" {
  description = "PostgreSQL Flexible Server SKU"
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage size in MB (min 32768 = 32 GiB, defined by Azure)"
  default     = 32768
}

variable "postgres_storage_tier" {
  description = "PostgreSQL storage performance tier"
  default     = "P4"
}

variable "postgres_admin_login" {
  description = "PostgreSQL admin username"
  default     = "psqladmin"
}

variable "postgres_zone" {
  description = "Availability zone for PostgreSQL"
  default     = "1"
}
