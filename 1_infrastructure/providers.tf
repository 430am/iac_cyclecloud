terraform {
    required_version = "~> 1"

    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4"
      }
      random = {
        source = "hashicorp/random"
        version = "~> 3"
      }
      tls = {
        source = "hashicorp/tls"
        version = "~> 4"
      }
      azuread = {
        source = "hashicorp/azuread"
        version = "~> 3"
      }
    }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}