# --- Step 1: 2 App Services in 2 regions (F1 free) ---

resource "azurerm_service_plan" "primary" {
  name                = "plan-${local.name_prefix}-sea"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.primary_location
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = local.common_tags
}

resource "azurerm_linux_web_app" "primary" {
  name                = "app-${local.name_prefix}-sea-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.primary_location
  service_plan_id     = azurerm_service_plan.primary.id
  tags                = local.common_tags

  site_config {
    application_stack {
      docker_image_name   = "nginx:alpine"
      docker_registry_url = "https://index.docker.io"
    }
    always_on = false
  }
}

resource "azurerm_service_plan" "secondary" {
  name                = "plan-${local.name_prefix}-eas"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.secondary_location
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = local.common_tags
}

resource "azurerm_linux_web_app" "secondary" {
  name                = "app-${local.name_prefix}-eas-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.secondary_location
  service_plan_id     = azurerm_service_plan.secondary.id
  tags                = local.common_tags

  site_config {
    application_stack {
      docker_image_name   = "nginx:alpine"
      docker_registry_url = "https://index.docker.io"
    }
    always_on = false
  }
}
