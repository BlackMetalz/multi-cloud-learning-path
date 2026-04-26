# --- Step 1: AKS cluster ---

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${local.name_prefix}"
  kubernetes_version  = var.aks_kubernetes_version
  sku_tier            = "Free" # Free tier = no SLA, $0 control plane
  tags                = local.common_tags

  # Enable OIDC issuer + Workload Identity for secret-less pod-to-Azure auth.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                 = "system"
    node_count           = var.aks_node_count
    vm_size              = var.aks_node_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = false
    os_disk_size_gb      = 30
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
}

# Let AKS kubelet pull from ACR without imagePullSecrets.
resource "azurerm_role_assignment" "aks_acrpull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
