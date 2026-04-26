terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate139f04"
    container_name       = "tfstate"
    key                  = "backup-identity.tfstate"
  }
}

provider "azurerm" {
  features {
    recovery_service {
      vm_backup_stop_protection_and_retain_data_on_destroy = true
      purge_protected_items_from_vault_on_destroy          = true
    }
  }
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "core"
}

# Reuses az login session.
provider "azuread" {}
