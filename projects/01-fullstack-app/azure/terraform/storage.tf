# --- Step 4: Storage Account + Static Website ---

resource "azurerm_storage_account" "static" {
  name                     = "st${local.alphanumeric_name}${local.suffix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

resource "azurerm_storage_account_static_website" "static" {
  storage_account_id = azurerm_storage_account.static.id
  index_document     = "index.html"
}
