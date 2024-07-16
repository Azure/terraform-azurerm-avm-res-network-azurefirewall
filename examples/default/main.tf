terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  max = length(local.azure_regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "rg" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  name                = module.naming.virtual_network.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.1.0.0/26"]
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

module "fw_public_ip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.1.2"
  # insert the 3 required variables here
  name                = "pip-fw-terraform"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    deployment = "terraform"
  }
  zones = ["1", "2", "3"]
}

module "fwpolicy" {
  source              = "Azure/avm-res-network-firewallpolicy/azurerm"
  version             = "0.2.0"
  name                = module.naming.firewall_policy.name_unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# This is the module call
module "firewall" {
  source = "../.."
  # source             = "Azure/avm-res-network-firewall/azurerm"
  name                = module.naming.firewall.name
  enable_telemetry    = var.enable_telemetry
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  firewall_sku_tier   = "Standard"
  firewall_sku_name   = "AZFW_VNet"
  firewall_zones      = ["1", "2", "3"]
  firewall_ip_configuration = [
    {
      name                 = "ipconfig1"
      subnet_id            = azurerm_subnet.subnet.id
      public_ip_address_id = module.fw_public_ip.public_ip_id
    }
  ]
}

