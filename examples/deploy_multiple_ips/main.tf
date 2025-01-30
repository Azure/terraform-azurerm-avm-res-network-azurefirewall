terraform {
  required_version = ">= 1.9, < 2.0"
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

resource "azurerm_public_ip_prefix" "public_ip_prefix" {
  location            = azurerm_resource_group.rg.location
  name                = module.naming.public_ip_prefix.name
  resource_group_name = azurerm_resource_group.rg.name
  prefix_length       = 31
  sku                 = "Standard"
}

resource "azurerm_public_ip" "pip" {
  for_each = toset(["0", "1"])

  allocation_method   = "Static"
  location            = azurerm_resource_group.rg.location
  name                = "module.naming.public_ip.name_unique-${each.key}"
  resource_group_name = azurerm_resource_group.rg.name
  public_ip_prefix_id = azurerm_public_ip_prefix.public_ip_prefix.id
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  lifecycle {
    ignore_changes = [zones]
  }
}

# This is the module call
module "firewall" {
  source = "../.."
  # source             = "Azure/avm-res-network-firewall/azurerm"
  name                = module.naming.firewall.name_unique
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
      public_ip_address_id = azurerm_public_ip.pip[0].id
    },
    {
      name                 = "ipconfig2"
      public_ip_address_id = azurerm_public_ip.pip[1].id
    }
  ]
  tags = {
    environment = "terraform"
  }
}
