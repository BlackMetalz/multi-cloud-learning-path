output "app_primary_url" {
  value = "https://${azurerm_linux_web_app.primary.default_hostname}"
}

output "app_secondary_url" {
  value = "https://${azurerm_linux_web_app.secondary.default_hostname}"
}

output "tm_fqdn" {
  description = "Traffic Manager FQDN — curl này để xem routing"
  value       = azurerm_traffic_manager_profile.main.fqdn
}

output "tm_url" {
  value = "https://${azurerm_traffic_manager_profile.main.fqdn}"
}

output "dns_zone_nameservers" {
  description = "Update registrar's NS records sang đây nếu muốn delegate zone thật"
  value       = azurerm_dns_zone.main.name_servers
}

output "frontdoor_endpoint_hostname" {
  value = var.enable_front_door ? azurerm_cdn_frontdoor_endpoint.main[0].host_name : null
}

output "vpn_gateway_public_ip" {
  value = var.enable_vpn_gateway ? azurerm_public_ip.vpn[0].ip_address : null
}
