terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }

  # Remote backend
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate139f04"
    container_name       = "tfstate"
    key                  = "fullstack-app.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  default = "fullstack-app"
}

variable "location" {
  default = "Southeast Asia"
}

# --- Step 2: Resource Group + App Service ---

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = var.location
}

resource "azurerm_service_plan" "main" {
  name                = "plan-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_user_assigned_identity" "webapp" {
  name                = "id-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_linux_web_app" "main" {
  name                            = "app-${var.project_name}" # In case you don't know where `app-fullstack-app` comes from xD
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  service_plan_id                 = azurerm_service_plan.main.id
  key_vault_reference_identity_id = azurerm_user_assigned_identity.webapp.id

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

# --- Step 4: Storage Account + Static Website ---

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "static" {
  name                     = "st${replace(var.project_name, "-", "")}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "static" {
  storage_account_id = azurerm_storage_account.static.id
  index_document     = "index.html"
}

# --- Step 3 (light): Key Vault + Managed Identity ---

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${replace(var.project_name, "-", "")}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

# Grant the operator (you) Secrets Officer so Terraform can write the secret below.
resource "azurerm_role_assignment" "user_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC propagation is eventually consistent — wait before writing data-plane.
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.user_kv_secrets_officer]
  create_duration = "60s"
}

resource "azurerm_key_vault_secret" "demo" {
  name         = "demo-secret"
  value        = "top-secret-from-keyvault-not-from-tf-vars"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [time_sleep.wait_for_rbac]
}

# Grant the App Service's Managed Identity read-only access to secrets.
resource "azurerm_role_assignment" "webapp_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.webapp.principal_id
}

# --- Outputs ---

output "app_url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "static_url" {
  value = azurerm_storage_account.static.primary_web_endpoint
}

output "storage_account_name" {
  value = azurerm_storage_account.static.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "webapp_name" {
  value = azurerm_linux_web_app.main.name
}

# TODO: Step 3 — Add PostgreSQL Flexible Server (Key Vault done above)
# TODO: Step 5 — Add Monitor + Log Analytics Workspace
