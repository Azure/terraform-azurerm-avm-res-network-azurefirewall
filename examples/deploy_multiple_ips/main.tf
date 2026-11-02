terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  max = length(local.azure_regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

# This is required for resource modules
resource "azapi_resource" "resource_group" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.virtual_network.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.1.0.0/16"]
      }
      subnets = [
        {
          name = "AzureFirewallSubnet"
          properties = {
            addressPrefix = "10.1.0.0/26"
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "public_ip_prefix" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.public_ip_prefix.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/publicIPPrefixes@2024-05-01"
  body = {
    properties = {
      prefixLength           = 31
      publicIPAddressVersion = "IPv4"
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    zones = ["1", "2", "3"]
  }
}

resource "azapi_resource" "public_ip" {
  for_each = toset(["0", "1"])

  location  = azapi_resource.resource_group.location
  name      = "${module.naming.public_ip.name_unique}-${each.key}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/publicIPAddresses@2024-05-01"
  body = {
    properties = {
      publicIPAddressVersion   = "IPv4"
      publicIPAllocationMethod = "Static"
      publicIPPrefix = {
        id = azapi_resource.public_ip_prefix.id
      }
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    zones = ["1", "2", "3"]
  }
}

# This is the module call
module "firewall" {
  source = "../../"

  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Standard"
  location            = azapi_resource.resource_group.location
  name                = module.naming.firewall.name_unique
  resource_group_name = azapi_resource.resource_group.name
  enable_telemetry    = var.enable_telemetry
  firewall_zones      = ["1", "2", "3"]
  ip_configurations = {
    ipconfig1 = {
      name                 = "ipconfig1"
      subnet_id            = "${azapi_resource.virtual_network.id}/subnets/AzureFirewallSubnet"
      public_ip_address_id = azapi_resource.public_ip["0"].id
    }
    ipconfig2 = {
      name                 = "ipconfig2"
      public_ip_address_id = azapi_resource.public_ip["1"].id
    }
  }
  tags = {
    environment = "terraform"
  }
}
