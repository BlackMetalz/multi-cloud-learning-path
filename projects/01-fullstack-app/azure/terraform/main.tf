terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
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

resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name   = "nginx:alpine"
      docker_registry_url = "https://index.docker.io"
    }
  }
}

# --- Outputs ---

output "app_url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

# TODO: Step 3 — Add PostgreSQL Flexible Server + Key Vault
# TODO: Step 4 — Add Storage Account
# TODO: Step 5 — Add Monitor + Log Analytics Workspace
