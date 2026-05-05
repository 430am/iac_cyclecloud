terraform {
  required_version = "~> 1"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  features {}
}