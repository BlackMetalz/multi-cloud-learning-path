output "vm_name" {
  value = azurerm_linux_virtual_machine.main.name
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "vault_name" {
  value = azurerm_recovery_services_vault.main.name
}

output "backup_policy_name" {
  value = azurerm_backup_policy_vm.daily.name
}

output "operator_group_id" {
  value = azuread_group.vm_operators.object_id
}

output "operator_group_name" {
  value = azuread_group.vm_operators.display_name
}

output "custom_role_name" {
  value = azurerm_role_definition.vm_operator.name
}

output "vm_ssh_private_key_pem" {
  value     = tls_private_key.vm.private_key_pem
  sensitive = true
}
