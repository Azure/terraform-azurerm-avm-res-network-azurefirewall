terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}


provider "azurerm" {
  features {}
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  min = 0
  max = length(local.azure_regions) - 1
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name_unique
  location = local.azure_regions[random_integer.region_index.result]
}

resource "azurerm_virtual_network" "vnet" {
  name                = module.naming.virtual_network.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.1.0.0/16"]
}
resource "azurerm_subnet" "subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/26"]
}

# This is the module call
module "firewall" {
  source = "../.."
  # source             = "Azure/avm-res-network-firewall/azurerm"
  name                          = module.naming.firewall.name
  enable_telemetry              = var.enable_telemetry
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  firewall_sku_tier             = "Standard"
  firewall_sku_name             = "AZFW_VNet"
  firewall_dns_proxy_enabled    = false
  public_ip_allocation_method   = "Static"
  public_ip_location            = azurerm_resource_group.rg.location
  public_ip_name                = module.naming.public_ip.name
  public_ip_resource_group_name = azurerm_resource_group.rg.name
}
