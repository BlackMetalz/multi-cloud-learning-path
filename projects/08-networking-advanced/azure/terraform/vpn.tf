# --- Step 4: VPN Gateway Point-to-Site (toggle) ---
# Basic SKU + AAD authentication. Tạo lâu ~30 phút.

resource "azurerm_virtual_network" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "vnet-vpn-${local.name_prefix}"
  address_space       = [var.vpn_vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# GatewaySubnet — tên BẮT BUỘC, /27 trở lên.
resource "azurerm_subnet" "gateway" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vpn[0].name
  address_prefixes     = [var.vpn_gateway_subnet_cidr]
}

resource "azurerm_subnet" "vpn_workload" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vpn[0].name
  address_prefixes     = [var.vpn_workload_subnet_cidr]
}

resource "azurerm_public_ip" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "pip-vgw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic" # Basic SKU yêu cầu Dynamic
  sku                 = "Basic"
  tags                = local.common_tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "vgw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "Basic"
  tags                = local.common_tags

  ip_configuration {
    name                          = "vgw-ipcfg"
    public_ip_address_id          = azurerm_public_ip.vpn[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  vpn_client_configuration {
    address_space        = [var.vpn_client_address_pool]
    vpn_client_protocols = ["OpenVPN"]

    # AAD authentication: dùng tenant Azure để auth thay vì certs.
    aad_tenant   = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4" # Azure VPN Client App ID (Microsoft-managed, hardcoded)
    aad_issuer   = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
  }
}
