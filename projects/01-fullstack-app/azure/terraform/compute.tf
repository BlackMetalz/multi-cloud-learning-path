# --- Step 2 (continued): App Service ---

resource "azurerm_service_plan" "main" {
  name                = "plan-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "webapp" {
  name                = "id-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_linux_web_app" "main" {
  name                            = "app-${local.name_prefix}" # In case you don't know where `app-fullstack-app` comes from xD
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  service_plan_id                 = azurerm_service_plan.main.id
  key_vault_reference_identity_id = azurerm_user_assigned_identity.webapp.id
  tags                            = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.webapp.id]
  }

  app_settings = {
    "DEMO_SECRET" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.demo.versionless_id})"
  }

  site_config {
    application_stack {
      docker_image_name   = "nginx:alpine"
      docker_registry_url = "https://index.docker.io"
    }

    # Free plan: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app#always_on-1
    # always_on must be explicitly set to false when using Free, F1, D1, or Shared Service Plans.
    always_on = false
  }
}
