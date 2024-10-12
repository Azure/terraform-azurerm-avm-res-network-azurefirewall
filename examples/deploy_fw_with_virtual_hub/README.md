<!-- BEGIN_TF_DOCS -->
# Deploy Azure Firewall in a Virtual Hub

This deploys the Azure Firewall and Firewall Policy with a Virtual Hub and a Virtual WAN.

- Azure Firewall
- Azure Firewall Policy
- Azure Virtual WAN
- Azure Virtual Hub

```hcl
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


```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71, < 5.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_virtual_hub.vhub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub) (resource)
- [azurerm_virtual_wan.vwan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_wan) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_firewall"></a> [firewall](#module\_firewall)

Source: ../..

Version:

### <a name="module_fw_policy"></a> [fw\_policy](#module\_fw\_policy)

Source: Azure/avm-res-network-firewallpolicy/azurerm

Version: 0.2.0

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->