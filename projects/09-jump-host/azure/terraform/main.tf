resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

# Lấy public IP của máy hiện tại — dùng làm default cho NSG allowlist nếu user không truyền.
data "http" "myip" {
  url = "https://api.ipify.org"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}
