# --- Step 1: Storage Account với versioning + soft delete ---

resource "azurerm_storage_account" "main" {
  name                     = "st${local.alphanumeric_name}${local.suffix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"
  tags                     = local.common_tags

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true # cần cho lifecycle rule "tier sau N ngày không truy cập"

    delete_retention_policy {
      days = var.blob_soft_delete_days
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_days
    }
  }
}

# Grant operator (you) Storage Blob Data Contributor — cần cho data plane (upload/list/delete blob).
# Account-level permissions (Owner/Contributor) chỉ control plane, không tự động cho data plane.
resource "azurerm_role_assignment" "user_blob_data" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
