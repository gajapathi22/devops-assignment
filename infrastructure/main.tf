# infrastructure/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  resource_group_name = "rg-devops-${random_id.suffix.hex}"
  location           = "East US"
  vm_name           = "vm-devops-${random_id.suffix.hex}"
  tags = {
    Environment = "demo"
    Project     = "devops-assignment"
    Owner       = "student"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

# Network Module
module "network" {
  source = "./modules/network"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  suffix             = random_id.suffix.hex
  tags               = local.tags
}

# VM Module  
module "vm" {
  source = "./modules/vm"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  subnet_id          = module.network.subnet_id
  public_ip_id       = module.network.public_ip_id
  vm_name            = local.vm_name
  suffix             = random_id.suffix.hex
  tags               = local.tags
}