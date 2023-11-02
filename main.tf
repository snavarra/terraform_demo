# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Provides the Resource group to Logically contain resources
resource"azurerm_resource_group" "rg"{
    name      = "seneca_dev"
    location  = "Canada East"
    tags      = {
      environment  = "dev"
      source       = "Terraform"
    }
}


