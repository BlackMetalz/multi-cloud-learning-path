# Shared foundation — resources & data sources used across multiple files.

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

# Get current public IP — used to allow SSH from your machine when Bastion is off.
data "http" "myip" {
  url = "https://api.ipify.org"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}
