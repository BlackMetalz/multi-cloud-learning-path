variable "subscription_id" {
  type = string
}

variable "project_name" {
  default = "jump-host"
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
  default = "10.50.0.0/16"
}

variable "bastion_subnet_cidr" {
  default = "10.50.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.50.2.0/24"
}

# --- VM ---

variable "vm_size" {
  description = "Pre-flight: az vm list-skus -l <region> --size <sku> --query \"[?length(restrictions)==\\`0\\`].name\" -o tsv"
  default     = "Standard_D2alds_v7"
}

variable "vm_admin_username" {
  default = "azureuser"
}

variable "workload_vm_count" {
  description = "Số VM trong private subnet để SSH ProxyJump tới"
  default     = 1
}

# --- SSH allowlist ---

variable "allowed_ssh_ips" {
  description = "Danh sách IP/CIDR được SSH vào bastion. Để rỗng → tự dùng public IP hiện tại của máy bro."
  type        = list(string)
  default     = []
}
