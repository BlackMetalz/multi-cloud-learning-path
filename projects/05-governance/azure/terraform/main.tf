data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# Resource Group for action groups, alert rules.
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = "southeastasia"
  tags     = local.common_tags
}
