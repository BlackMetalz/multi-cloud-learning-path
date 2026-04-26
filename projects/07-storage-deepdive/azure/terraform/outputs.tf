output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "blob_endpoint" {
  value = azurerm_storage_account.main.primary_blob_endpoint
}

output "container_logs" {
  value = azurerm_storage_container.logs.name
}

output "container_public" {
  value = azurerm_storage_container.public.name
}

output "container_compliance" {
  value = azurerm_storage_container.compliance.name
}

# SAS URL = container endpoint + "?" + SAS token. Dùng curl được luôn.
output "logs_sas_url" {
  description = "Read+list SAS for the logs container, valid 1 year"
  value       = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.logs.name}?${data.azurerm_storage_account_blob_container_sas.logs_readonly.sas}"
  sensitive   = true
}
