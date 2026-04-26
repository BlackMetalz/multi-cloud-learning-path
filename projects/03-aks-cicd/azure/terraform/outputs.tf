# --- Outputs ---

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "log_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}

# --- GitHub Actions secrets (paste into repo Settings → Secrets) ---

output "gha_AZURE_CLIENT_ID" {
  description = "Set as GitHub secret AZURE_CLIENT_ID"
  value       = azurerm_user_assigned_identity.gha_deploy.client_id
}

output "gha_AZURE_TENANT_ID" {
  description = "Set as GitHub secret AZURE_TENANT_ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "gha_AZURE_SUBSCRIPTION_ID" {
  description = "Set as GitHub secret AZURE_SUBSCRIPTION_ID"
  value       = data.azurerm_client_config.current.subscription_id
}

# --- Workload Identity demo ---

output "workload_identity_client_id" {
  description = "Annotate K8s SA 'default/demo-sa' with this client_id"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}
