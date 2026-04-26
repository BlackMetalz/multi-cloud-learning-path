# --- Step 3: Azure Front Door Standard (toggle) ---
# Edge POPs Microsoft toàn cầu, L7 với caching + WAF tùy chọn.

resource "azurerm_cdn_frontdoor_profile" "main" {
  count = var.enable_front_door ? 1 : 0

  name                = "fd-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  count = var.enable_front_door ? 1 : 0

  name                     = "fde-${local.name_prefix}-${local.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  enabled                  = true
  tags                     = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  count = var.enable_front_door ? 1 : 0

  name                     = "og-app"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

resource "azurerm_cdn_frontdoor_origin" "primary" {
  count = var.enable_front_door ? 1 : 0

  name                          = "origin-sea"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[0].id

  enabled                        = true
  host_name                      = azurerm_linux_web_app.primary.default_hostname
  origin_host_header             = azurerm_linux_web_app.primary.default_hostname
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "main" {
  count = var.enable_front_door ? 1 : 0

  name                          = "route-default"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.primary[0].id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = true
}
