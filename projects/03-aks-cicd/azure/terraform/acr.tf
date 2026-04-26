# --- Step 1: Azure Container Registry (Basic) ---

resource "azurerm_container_registry" "main" {
  name                = "acr${local.alphanumeric_name}${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false # rely on AAD/RBAC, no admin creds
  tags                = local.common_tags
}
