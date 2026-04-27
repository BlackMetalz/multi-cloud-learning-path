# --- Step 1: Recovery Services Vault + Backup Policy + Protected VM ---

resource "azurerm_recovery_services_vault" "main" {
  name                = "rsv-${local.name_prefix}-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  storage_mode_type = "GeoRedundant" # default; can switch to LocallyRedundant for cheaper

  # Soft delete is always-on now (Azure "secure by default" policy, 2024+).
  # `provider.features.recovery_service.purge_protected_items_from_vault_on_destroy = true`
  # ở providers.tf đã handle clean destroy bypass soft-delete.

  tags = local.common_tags
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = "bp-daily-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  timezone = "Singapore Standard Time"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = var.backup_retention_daily
  }
}

resource "azurerm_backup_protected_vm" "main" {
  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  source_vm_id        = azurerm_linux_virtual_machine.main.id
  backup_policy_id    = azurerm_backup_policy_vm.daily.id
}
