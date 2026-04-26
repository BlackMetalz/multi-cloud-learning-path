variable "subscription_id" {
  type = string
}

variable "project_name" {
  default = "backup-lab"
}

variable "location" {
  default = "Southeast Asia"
}

variable "environment" {
  default = "dev"
}

variable "owner" {
  default = "kien"
}

# --- Network ---

variable "vnet_cidr" {
  default = "10.30.0.0/16"
}

variable "subnet_cidr" {
  default = "10.30.1.0/24"
}

# --- VM ---

variable "vm_size" {
  description = "B1s ~$8/mo cho lab. Pre-flight check trước khi đổi region."
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  default = "azureuser"
}

# --- Backup ---

variable "backup_retention_daily" {
  description = "Daily retention in days"
  default     = 7
}

# --- Identity ---

variable "operator_group_members" {
  description = "List of UPNs (email) cho group g-vm-operators. Để [] nếu chỉ muốn group rỗng."
  type        = list(string)
  default     = []
}
