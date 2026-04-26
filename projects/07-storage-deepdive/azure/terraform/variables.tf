variable "subscription_id" {
  type = string
}

variable "project_name" {
  default = "storage-lab"
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

variable "replication_type" {
  description = "LRS / ZRS / GRS / RA-GRS / GZRS — picks the redundancy"
  default     = "LRS"
}

variable "blob_soft_delete_days" {
  default = 7
}

variable "container_soft_delete_days" {
  default = 7
}
