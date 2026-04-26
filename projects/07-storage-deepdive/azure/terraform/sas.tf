# --- Step 4: Service SAS cho container "logs" — read-only, list-only, 1 năm ---
# Generated as data source, output dưới dạng URL có thể curl ngay.

data "azurerm_storage_account_blob_container_sas" "logs_readonly" {
  connection_string = azurerm_storage_account.main.primary_connection_string
  container_name    = azurerm_storage_container.logs.name
  https_only        = true

  start  = formatdate("YYYY-MM-DD", timestamp())
  expiry = formatdate("YYYY-MM-DD", timeadd(timestamp(), "8760h")) # +1 year

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = true
  }
}
