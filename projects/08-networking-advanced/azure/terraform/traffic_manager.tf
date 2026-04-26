# --- Step 2: Traffic Manager (DNS-based global LB) ---
# F1 App Services không support TM "Azure endpoint" type — dùng external endpoint trỏ vào defaultHostName.

resource "azurerm_traffic_manager_profile" "main" {
  name                   = "tm-${local.name_prefix}-${local.suffix}"
  resource_group_name    = azurerm_resource_group.main.name
  traffic_routing_method = "Priority" # đổi thử Weighted/Performance/Geographic để học
  tags                   = local.common_tags

  dns_config {
    relative_name = "tm-${local.name_prefix}-${local.suffix}"
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_external_endpoint" "primary" {
  name              = "ep-sea"
  profile_id        = azurerm_traffic_manager_profile.main.id
  target            = azurerm_linux_web_app.primary.default_hostname
  endpoint_location = var.primary_location
  weight            = 100
  priority          = 1 # primary
}

resource "azurerm_traffic_manager_external_endpoint" "secondary" {
  name              = "ep-eas"
  profile_id        = azurerm_traffic_manager_profile.main.id
  target            = azurerm_linux_web_app.secondary.default_hostname
  endpoint_location = var.secondary_location
  weight            = 100
  priority          = 2 # failover
}
