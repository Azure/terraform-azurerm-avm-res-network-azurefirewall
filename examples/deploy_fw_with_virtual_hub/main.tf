terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0.0"
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

resource "azurerm_virtual_wan" "vwan" {
  location            = azurerm_resource_group.rg.location
  name                = module.naming.virtual_wan.name
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Standard"
}

resource "azurerm_virtual_hub" "vhub" {
  location            = azurerm_resource_group.rg.location
  name                = "virtual-hub"
  resource_group_name = azurerm_resource_group.rg.name
  address_prefix      = "10.1.0.0/16"
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
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
  firewall_sku_name   = "AZFW_Hub"
  firewall_zones      = ["1", "2", "3"]
  firewall_virtual_hub = {
    virtual_hub_id  = azurerm_virtual_hub.vhub.id
    public_ip_count = 4
  }
  firewall_policy_id = module.fw_policy.resource.id
}

module "fw_policy" {
  source = "Azure/avm-res-network-firewallpolicy/azurerm"
  # insert the 3 required variables here
  version             = "0.2.0"
  name                = module.naming.firewall_policy.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


