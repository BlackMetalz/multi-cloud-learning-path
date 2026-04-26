# --- Outputs ---

output "app_url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "static_url" {
  value = azurerm_storage_account.static.primary_web_endpoint
}

output "storage_account_name" {
  value = azurerm_storage_account.static.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "webapp_name" {
  value = azurerm_linux_web_app.main.name
}

output "log_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}

output "log_workspace_id" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_admin_login" {
  value = azurerm_postgresql_flexible_server.main.administrator_login
}
