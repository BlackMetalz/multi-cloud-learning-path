# --- Step 3 (light): Key Vault + Managed Identity ---

resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.alphanumeric_name}-${local.suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = var.kv_soft_delete_days
  purge_protection_enabled   = false
  tags                       = local.common_tags
}

# Grant the operator (you) Secrets Officer so Terraform can write the secret below.
resource "azurerm_role_assignment" "user_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC propagation is eventually consistent — wait before writing data-plane.
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.user_kv_secrets_officer]
  create_duration = "60s"
}

resource "azurerm_key_vault_secret" "demo" {
  name         = "demo-secret"
  value        = "top-secret-from-keyvault-not-from-tf-vars"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [time_sleep.wait_for_rbac]
}

# Grant the App Service's Managed Identity read-only access to secrets.
resource "azurerm_role_assignment" "webapp_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.webapp.principal_id
}
