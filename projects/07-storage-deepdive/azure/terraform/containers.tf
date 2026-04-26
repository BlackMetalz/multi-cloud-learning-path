# --- Step 1: 3 containers với access type khác nhau ---

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Anonymous public read for blobs (không list được container, chỉ get blob nếu biết tên).
resource "azurerm_storage_container" "public" {
  name                  = "public-static"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "blob"
}

# Container cho immutability lab (Step 6 — portal manual).
resource "azurerm_storage_container" "compliance" {
  name                  = "compliance"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
