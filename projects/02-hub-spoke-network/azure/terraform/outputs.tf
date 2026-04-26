# --- Outputs ---

output "vm_name" {
  value = azurerm_linux_virtual_machine.main.name
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}

output "vm_ssh_private_key_pem" {
  description = "Save to ~/.ssh/<name>.pem and chmod 600 to use with Bastion / direct SSH"
  value       = tls_private_key.vm.private_key_pem
  sensitive   = true
}

output "bastion_name" {
  value = var.enable_bastion ? azurerm_bastion_host.main[0].name : null
}

output "appgw_public_ip" {
  value = var.enable_app_gateway ? azurerm_public_ip.appgw[0].ip_address : null
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_blob_pe_ip" {
  value = azurerm_private_endpoint.storage_blob.private_service_connection[0].private_ip_address
}

output "log_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}
