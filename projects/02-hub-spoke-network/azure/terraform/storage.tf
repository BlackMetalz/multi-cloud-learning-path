# --- Step 5: Storage Account (target for Private Endpoint) ---
# Public network access disabled — VM must reach it via PE + Private DNS.

resource "azurerm_storage_account" "main" {
  name                            = "st${local.alphanumeric_name}${local.suffix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  tags                            = local.common_tags
}
