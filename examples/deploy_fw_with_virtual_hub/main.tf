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

resource "azapi_resource" "virtual_wan" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.virtual_wan.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualWans@2024-05-01"
  body = {
    properties = {
      type = "Standard"
    }
  }
}

resource "azapi_resource" "virtual_hub" {
  location  = azapi_resource.resource_group.location
  name      = "virtual-hub"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualHubs@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.1.0.0/16"
      sku           = "Standard"
      virtualWan = {
        id = azapi_resource.virtual_wan.id
      }
    }
  }
}

resource "azapi_resource" "firewall_policy" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.firewall_policy.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/firewallPolicies@2024-05-01"
  body = {
    properties = {
      sku = {
        tier = "Standard"
      }
    }
  }
}

# This is the module call
module "firewall" {
  source = "../../"

  firewall_sku_name   = "AZFW_Hub"
  firewall_sku_tier   = "Standard"
  location            = azapi_resource.resource_group.location
  name                = module.naming.firewall.name
  resource_group_name = azapi_resource.resource_group.name
  enable_telemetry    = var.enable_telemetry
  firewall_policy_id  = azapi_resource.firewall_policy.id
  firewall_virtual_hub = {
    virtual_hub_id  = azapi_resource.virtual_hub.id
    public_ip_count = 4
  }
  firewall_zones = ["1", "2", "3"]
}
