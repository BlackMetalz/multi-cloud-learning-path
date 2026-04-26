# --- Step 5: Public DNS zone + records ---
# Zone tên không cần bro own. Để delegate thật, update NS records ở registrar.
# Trong lab này chỉ để học cú pháp record, không cần resolve toàn cầu.

resource "azurerm_dns_zone" "main" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# CNAME → Traffic Manager (đây là pattern điển hình "tm.example.com")
resource "azurerm_dns_cname_record" "tm" {
  name                = "tm"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  record              = azurerm_traffic_manager_profile.main.fqdn
  tags                = local.common_tags
}

# CNAME → App Service primary (tránh A record vì IP App Service có thể đổi)
resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  record              = azurerm_linux_web_app.primary.default_hostname
  tags                = local.common_tags
}

# TXT verification (App Service custom domain cần TXT để verify ownership)
resource "azurerm_dns_txt_record" "asuid_www" {
  name                = "asuid.www"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  tags                = local.common_tags

  record {
    value = azurerm_linux_web_app.primary.custom_domain_verification_id
  }
}
