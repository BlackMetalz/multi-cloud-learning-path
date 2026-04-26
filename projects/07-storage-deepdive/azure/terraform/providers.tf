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
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate139f04"
    container_name       = "tfstate"
    key                  = "storage-deepdive.tfstate"
  }
}

provider "azurerm" {
  features {
    storage {
      data_plane_available = true
    }
  }
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "core"
}
