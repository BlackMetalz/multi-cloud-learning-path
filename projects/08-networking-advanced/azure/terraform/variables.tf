variable "subscription_id" {
  type = string
}

variable "project_name" {
  default = "net-lab"
}

variable "primary_location" {
  default = "Southeast Asia"
}

variable "secondary_location" {
  default = "East Asia"
}

variable "environment" {
  default = "dev"
}

variable "owner" {
  default = "kien"
}

# --- DNS ---

variable "dns_zone_name" {
  description = "Public DNS zone — không cần own thật, Azure DNS sẽ host record nhưng không ai resolve trừ khi bro update NS"
  default     = "lab.kien.dev"
}

# --- VPN VNet (chỉ tạo khi enable_vpn_gateway = true) ---

variable "vpn_vnet_cidr" {
  default = "10.40.0.0/16"
}

variable "vpn_gateway_subnet_cidr" {
  description = "GatewaySubnet — Azure yêu cầu tối thiểu /27"
  default     = "10.40.0.0/27"
}

variable "vpn_workload_subnet_cidr" {
  default = "10.40.1.0/24"
}

variable "vpn_client_address_pool" {
  description = "Pool IP cấp cho VPN client"
  default     = "172.16.0.0/24"
}

# --- Toggles for expensive resources ---

variable "enable_front_door" {
  description = "Front Door Standard ~$35/mo base — toggle on khi học, off khi không"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "VPN Gateway Basic ~$72/mo + tạo lâu ~30 phút — toggle on khi học"
  type        = bool
  default     = false
}
