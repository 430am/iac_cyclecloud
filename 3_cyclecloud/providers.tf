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
    http = {
      source  = "hashicorp/http"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  storage_use_azuread = true
  features {}
}