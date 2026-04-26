resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}
