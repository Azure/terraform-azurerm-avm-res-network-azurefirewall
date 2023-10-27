terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
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

module "vnet" {
  source = "Azure/terraform-azurerm-avm-res-network-virtualnetwork/azurerm" # This is the relative path to the module
  # source             = "Azure/avm-res-network-virtualnetwork/azurerm"
  name                = module.naming.virtual_network.name
  enable_telemetry    = true
  resource_group_name = azurerm_resource_group.rg.name
  vnet_location       = azurerm_resource_group.rg.location
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.0.0/26"]
  subnet_names        = ["AzureFirewallSubnet"]
  tags = {
    environment = "dev"
  }
}

# This is the module call
module "firewall" {
  source = "../../"
  # source             = "Azure/avm-res-network-firewall/azurerm"
  firewall_name           = module.naming.firewall.name
  enable_telemetry        = var.enable_telemetry
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  firewall_ip_config_name = module.naming.firewall_ip_configuration.name
  firewall_sku_name       = "AZFW_VNet"
  firewall_sku_tier       = "Standard"
  subnet_id               = module.vnet.subnet_ids[0]
  public_ip_address_config = {
    allocation_method = "Static"
    sku               = "Standard"
    sku_tier          = "Regional"
  }

  tags = {
    environment = "dev"
  }
}
# ...
