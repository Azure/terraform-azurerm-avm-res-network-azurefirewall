terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
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

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
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

resource "azurerm_firewall_policy" "policy" {
  name                = module.naming.firewall_policy.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# This is the module call
module "firewall" {
  source = "../.."
  # source             = "Azure/avm-res-network-firewall/azurerm"
  firewall_name           = module.naming.firewall.name
  enable_telemetry        = var.enable_telemetry
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  firewall_sku_name       = "AZFW_VNet"
  firewall_sku_tier       = "Standard"
  firewall_policy_id      = azurerm_firewall_policy.policy.id
  subnet_id               = azurerm_subnet.subnet.id
  firewall_ip_config_name = "AzureFirewallIpConfiguration"
  public_ip_address_config = {
    allocation_method   = "Static"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard"
    sku_tier            = "Regional"
    zones               = ["1", "2", "3"]
    idle_timeout_in_minutes = 4
    ip_version = "IPv4"
    ddos_protection_mode = "VirtualNetworkInherited"
  }
}