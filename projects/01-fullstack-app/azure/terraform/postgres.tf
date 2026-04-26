# --- Bonus: PostgreSQL Flexible Server ---

resource "random_password" "postgres" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+"
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [time_sleep.wait_for_rbac]
}

# Get current public IP so we can psql from this machine.
data "http" "myip" {
  url = "https://api.ipify.org"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${local.name_prefix}-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags

  version                = var.postgres_version
  administrator_login    = var.postgres_admin_login
  administrator_password = random_password.postgres.result

  # This is how sku name works in Terraform: https://github.com/hashicorp/terraform-provider-azurerm/issues/21522#issuecomment-2076534083
  sku_name     = var.postgres_sku        # cheapest burstable, ~$13/mo if left running
  storage_mb   = var.postgres_storage_mb # Minimum, define by Azure, we can not set lower =.=
  storage_tier = var.postgres_storage_tier
  zone         = var.postgres_zone

  public_network_access_enabled = true

  authentication {
    password_auth_enabled = true
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "myip" {
  name             = "allow-my-ip"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = chomp(data.http.myip.response_body)
  end_ip_address   = chomp(data.http.myip.response_body)
}

# Special "0.0.0.0" rule = "allow Azure services" (App Service can reach DB).
# DEV ONLY: "0.0.0.0" is a magic value = "allow ALL Azure services
# from ANY tenant" — relies on auth alone. Production should use Private Endpoint + VNet integration instead.
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "demo" {
  name      = "demo"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}
