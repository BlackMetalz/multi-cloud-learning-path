variable "subscription_id" {
  description = "Azure subscription ID (the one to attach to mg-nonprod)"
  type        = string
}

variable "project_name" {
  default = "governance"
}

variable "environment" {
  default = "dev"
}

variable "owner" {
  default = "kien"
}

variable "alert_email" {
  description = "Email địa chỉ nhận budget + activity alerts"
  type        = string
}

variable "allowed_locations" {
  description = "Locations cho policy 'Allowed locations'"
  default     = ["southeastasia", "eastasia"]
}

variable "monthly_budget_usd" {
  description = "Subscription monthly budget in USD"
  default     = 50
}
