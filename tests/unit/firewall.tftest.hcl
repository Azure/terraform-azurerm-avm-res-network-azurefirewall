mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/azureFirewalls/test-firewall/providers/Microsoft.Resources/mocked/mocked"
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      object_id                = "11111111-1111-1111-1111-111111111111"
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            role_name = "Reader"
          }
        ]
      }
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

variables {
  enable_telemetry    = false
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Standard"
  location            = "westeurope"
  name                = "test-firewall"
  resource_group_name = "test-rg"
}

override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/azureFirewalls/test-firewall"
    output = {
      properties = {
        additionalProperties = {}
        # Only one of these is read, depending on whether the Firewall is in a Virtual Hub.
        hubIPAddresses = {
          privateIPAddress = "10.100.0.132"
          publicIPs = {
            addresses = [{ address = "20.0.0.1" }, { address = "20.0.0.2" }]
            count     = 2
          }
        }
        ipConfigurations = [
          {
            name = "primary"
            properties = {
              privateIPAddress = "10.0.0.4"
              publicIPAddress  = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/primary" }
              subnet           = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallSubnet" }
            }
          },
          {
            name = "secondary"
            properties = {
              publicIPAddress = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/secondary" }
            }
          },
        ]
        threatIntelMode = "Alert"
      }
    }
  }
}

run "vnet_multiple_ip_configurations" {
  command = apply

  variables {
    ip_configurations = {
      primary = {
        name                 = "primary"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/primary"
      }
      secondary = {
        name                 = "secondary"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/secondary"
      }
    }
    tags = { environment = "test" }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/azureFirewalls@2025-01-01" && azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
    error_message = "The Firewall should use the default resource type and be deployed to the resource group named by resource_group_name."
  }
  assert {
    condition     = [for configuration in azapi_resource.this.body.properties.ipConfigurations : configuration.name] == ["primary", "secondary"] && azapi_resource.this.body.properties.ipConfigurations[1].properties.subnet == null
    error_message = "Both IP configurations should be sent, and only the first should reference the subnet."
  }
  assert {
    condition     = azapi_resource.this.body.properties.ipConfigurations[1].properties.publicIPAddress.id == var.ip_configurations.secondary.public_ip_address_id && azapi_resource.this.tags.environment == "test"
    error_message = "Public IPs and tags should be preserved."
  }
  assert {
    condition     = azapi_resource.this.body.properties.sku.name == "AZFW_VNet" && azapi_resource.this.body.properties.sku.tier == "Standard" && tolist(azapi_resource.this.body.zones) == tolist(["1", "2", "3"])
    error_message = "The SKU and the default zones should be sent."
  }
  assert {
    condition     = azapi_resource.this.body.properties.firewallPolicy == null && length(azapi_resource.this.body.properties.additionalProperties) == 0
    error_message = "No firewall policy and no SNAT ranges should be sent by default."
  }
  assert {
    condition = alltrue([
      length(azapi_resource.this.body.properties.applicationRuleCollections) == 0,
      length(azapi_resource.this.body.properties.natRuleCollections) == 0,
      length(azapi_resource.this.body.properties.networkRuleCollections) == 0,
      azapi_resource.this.body.properties.threatIntelMode == "",
    ])
    error_message = "The body should carry the placeholders that are replaced with live values on update."
  }
  assert {
    condition     = !can(azapi_resource.this.body.properties.managementIpConfiguration) && !can(azapi_resource.this.body.properties.hubIPAddresses) && !can(azapi_resource.this.body.properties.virtualHub)
    error_message = "Management and Virtual Hub settings should not be sent when they are not configured."
  }
  assert {
    condition     = azapi_resource.this.timeouts.create == "90m" && azapi_resource.this.timeouts.delete == "90m" && azapi_resource.this.timeouts.read == "5m" && azapi_resource.this.timeouts.update == "90m"
    error_message = "The Firewall should keep the AzureRM provider's default timeouts."
  }
  assert {
    condition     = tolist(azapi_resource.this.replace_triggers_external_values.subnet_ids) == tolist([lower(var.ip_configurations.primary.subnet_id)]) && azapi_resource.this.replace_triggers_external_values.sku_name == "AZFW_VNet" && azapi_resource.this.replace_triggers_external_values.management_ip_configuration == null
    error_message = "The subnet, SKU name and zones should replace the Firewall when they change, as they did with azurerm."
  }
  assert {
    condition     = output.resource_id == output.resource.id && output.resource.name == var.name && output.name == var.name && output.resource.resource_group_name == "test-rg"
    error_message = "The resource_id, name and resource outputs should describe the Firewall."
  }
  assert {
    condition     = output.private_ip_address == "10.0.0.4" && output.resource.ip_configuration[0].private_ip_address == "10.0.0.4" && output.resource.ip_configuration[1].private_ip_address == ""
    error_message = "The private IP address should be read from the IP configuration in the Firewall subnet, and be empty for the others, as azurerm returned it."
  }
  assert {
    condition     = output.resource.threat_intel_mode == "Alert" && length(output.resource.virtual_hub) == 0 && length(output.resource.management_ip_configuration) == 0 && output.resource.firewall_policy_id == "" && output.resource.ip_configuration[1].subnet_id == "" && length(output.resource.private_ip_ranges) == 0 && output.resource.dns_proxy_enabled == false
    error_message = "The resource output should keep the azurerm attribute shape."
  }
  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(data.azapi_client_config.telemetry) == 0
    error_message = "Disabling telemetry must omit the telemetry resource and client configuration."
  }
  assert {
    condition     = length(azapi_resource.lock) + length(azapi_resource.role_assignments) + length(azapi_resource.diagnostic_settings) + length(time_sleep.lock_removal) == 0
    error_message = "No interface resources should be created by default."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "ip_configurations_keep_key_order" {
  command = apply

  variables {
    ip_configurations = {
      a_extra = {
        name                 = "extra"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/extra"
      }
      z_primary = {
        name                 = "primary"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Test-RG/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/primary"
      }
    }
  }

  assert {
    condition     = [for configuration in azapi_resource.this.body.properties.ipConfigurations : configuration.name] == ["extra", "primary"]
    error_message = "IP configurations should be sent in key order, as the AzureRM provider sent them."
  }
  assert {
    condition     = tolist(azapi_resource.this.replace_triggers_external_values.subnet_ids) == tolist(["/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/test-rg/providers/microsoft.network/virtualnetworks/test-vnet/subnets/azurefirewallsubnet"])
    error_message = "Only the subnet, not its position or casing, should replace the Firewall, so adding a public IP updates it in place."
  }
  assert {
    condition     = output.private_ip_address == "10.0.0.4" && output.resource.ip_configuration[1].private_ip_address == "10.0.0.4" && output.resource.ip_configuration[0].private_ip_address == ""
    error_message = "Private IP addresses should be matched to IP configurations by name."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "legacy_ip_configuration_and_management" {
  command = apply

  variables {
    firewall_ip_configuration = [{
      name      = "legacy"
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallSubnet"
    }]
    firewall_management_ip_configuration = {
      name                 = "management"
      subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallManagementSubnet"
      public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/management"
    }
    firewall_timeouts = {
      create = "100m"
      update = "100m"
    }
    timeouts = {
      delete = "20m"
      read   = "10m"
      update = "15m"
    }
  }

  assert {
    condition     = one(azapi_resource.this.body.properties.ipConfigurations).name == "legacy" && one(azapi_resource.this.body.properties.ipConfigurations).properties.publicIPAddress == null
    error_message = "The deprecated IP interface must still work, including without a public IP."
  }
  assert {
    condition     = azapi_resource.this.body.properties.managementIpConfiguration.name == "management" && azapi_resource.this.body.properties.managementIpConfiguration.properties.subnet.id == var.firewall_management_ip_configuration.subnet_id
    error_message = "The management IP configuration should be sent."
  }
  assert {
    condition     = azapi_resource.this.replace_triggers_external_values.management_ip_configuration.public_ip_address_id == lower(var.firewall_management_ip_configuration.public_ip_address_id)
    error_message = "Changing the management IP configuration should replace the Firewall, as it did with azurerm."
  }
  assert {
    condition     = azapi_resource.this.timeouts.create == "100m" && azapi_resource.this.timeouts.update == "100m" && azapi_resource.this.timeouts.delete == "20m" && azapi_resource.this.timeouts.read == "10m"
    error_message = "firewall_timeouts should take precedence over timeouts for the Firewall."
  }
  assert {
    condition     = one(output.resource.management_ip_configuration).name == "management" && one(output.resource.ip_configuration).name == "legacy"
    error_message = "The resource output should describe the management IP configuration."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "virtual_hub" {
  command = apply

  variables {
    firewall_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/firewallPolicies/test-policy"
    firewall_sku_name  = "AZFW_Hub"
    firewall_virtual_hub = {
      virtual_hub_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualHubs/test-hub"
      public_ip_count = 2
    }
    firewall_zones = []
  }

  assert {
    condition     = azapi_resource.this.body.properties.hubIPAddresses.publicIPs.count == 2 && !can(azapi_resource.this.body.properties.hubIPAddresses.publicIPs.addresses)
    error_message = "Only the public IP count should be sent, so Azure keeps the existing public IPs."
  }
  assert {
    condition     = azapi_resource.this.body.properties.virtualHub.id == var.firewall_virtual_hub.virtual_hub_id && azapi_resource.this.body.properties.firewallPolicy.id == var.firewall_policy_id
    error_message = "The Virtual Hub and firewall policy should be sent."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.ipConfigurations) == 0 && !can(azapi_resource.this.body.zones) && length(azapi_resource.this.replace_triggers_external_values.zones) == 0
    error_message = "A Firewall without IP configurations or zones should send none."
  }
  assert {
    condition     = output.private_ip_address == "10.100.0.132" && one(output.resource.virtual_hub).private_ip_address == "10.100.0.132"
    error_message = "The private IP address of a Firewall in a Virtual Hub should be the hub IP address."
  }
  assert {
    condition     = tolist(one(output.resource.virtual_hub).public_ip_addresses) == tolist(["20.0.0.1", "20.0.0.2"]) && one(output.resource.virtual_hub).public_ip_count == 2 && output.resource.firewall_policy_id == var.firewall_policy_id
    error_message = "The resource output should keep the azurerm virtual_hub shape."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "virtual_hub_default_public_ip_count" {
  command = apply

  variables {
    firewall_sku_name = "AZFW_Hub"
    firewall_virtual_hub = {
      virtual_hub_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualHubs/test-hub"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.hubIPAddresses.publicIPs.count == 1 && one(output.resource.virtual_hub).public_ip_count == 1
    error_message = "The public IP count should default to 1, as it did with azurerm."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "snat_private_ranges_and_policy" {
  command = apply

  variables {
    firewall_policy_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/firewallPolicies/test-policy"
    firewall_private_ip_ranges = ["IANAPrivateRanges", "10.0.0.0/8"]
    ip_configurations = {
      primary = {
        name      = "primary"
        subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallSubnet"
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.additionalProperties["Network.SNAT.PrivateRanges"] == "10.0.0.0/8,IANAPrivateRanges"
    error_message = "SNAT private ranges should be sent as a comma-separated additional property."
  }
  assert {
    condition     = azapi_resource.this.body.properties.firewallPolicy.id == var.firewall_policy_id && output.resource.private_ip_ranges == toset(["10.0.0.0/8", "IANAPrivateRanges"])
    error_message = "The firewall policy should be sent and the ranges returned in the resource output."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "extensions" {
  command = apply

  variables {
    diagnostic_settings = {
      logs = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
        log_groups            = ["allLogs"]
        metric_categories     = ["AllMetrics"]
      }
      legacy = {
        name                           = "diag-legacy"
        storage_account_resource_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testsa"
        log_analytics_destination_type = "AzureDiagnostics"
        log_categories                 = ["AzureFirewallNetworkRule"]
        log_groups                     = []
        metric_categories              = []
      }
    }
    lock = { kind = "CanNotDelete" }
    role_assignments = {
      reader = {
        principal_id                     = "00000000-0000-0000-0000-000000000001"
        role_definition_id_or_name       = "reader"
        description                      = "Read the test firewall"
        skip_service_principal_aad_check = true
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["logs"].name == "diag-test-firewall" && azapi_resource.diagnostic_settings["logs"].parent_id == azapi_resource.this.id
    error_message = "Diagnostic settings should default their name and target the Firewall."
  }
  assert {
    condition     = one(azapi_resource.diagnostic_settings["logs"].body.properties.logs).categoryGroup == "allLogs" && one(azapi_resource.diagnostic_settings["logs"].body.properties.metrics).category == "AllMetrics"
    error_message = "Diagnostic log groups and metrics must be preserved."
  }
  assert {
    condition     = azapi_resource.diagnostic_settings["logs"].body.properties.logAnalyticsDestinationType == "Dedicated" && azapi_resource.diagnostic_settings["legacy"].body.properties.logAnalyticsDestinationType == "AzureDiagnostics"
    error_message = "The destination type should be sent as configured, as the AzureRM provider sent it."
  }
  assert {
    condition     = one(azapi_resource.diagnostic_settings["legacy"].body.properties.logs).category == "AzureFirewallNetworkRule" && !can(azapi_resource.diagnostic_settings["legacy"].body.properties.metrics)
    error_message = "Log categories should be mapped, and no metrics sent when none are configured."
  }
  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete" && azapi_resource.lock[0].parent_id == azapi_resource.this.id && azapi_resource.lock[0].body.properties.level == "CanNotDelete"
    error_message = "The lock must retain its Firewall scope and level."
  }
  assert {
    condition     = azapi_resource.lock[0].body.properties.notes == "Cannot delete the resource or its child resources." && time_sleep.lock_removal[0].destroy_duration == "30s"
    error_message = "The lock should keep the notes earlier versions wrote, and removing it should pause before the Firewall is deleted."
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].parent_id == azapi_resource.this.id && azapi_resource.role_assignments["reader"].body.properties.description == "Read the test firewall"
    error_message = "Role assignments must retain their scope and honor the documented description."
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" && azapi_resource.role_assignments["reader"].body.properties.principalType == "ServicePrincipal"
    error_message = "Role names should resolve ignoring case, and skip_service_principal_aad_check should send the ServicePrincipal principal type."
  }
  assert {
    condition     = data.azapi_resource_list.role_definitions[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
    error_message = "Role definitions should be listed in the resource group."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "parent_id_and_resource_types" {
  command = apply

  variables {
    parent_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/other-rg"
    resource_types = {
      network_azure_firewalls = "Microsoft.Network/azureFirewalls@2024-07-01"
    }
    ip_configurations = {
      primary = {
        name      = "primary"
        subnet_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/other-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallSubnet"
      }
    }
  }

  assert {
    condition     = azapi_resource.this.parent_id == var.parent_id && output.resource.resource_group_name == "other-rg"
    error_message = "parent_id should take precedence over resource_group_name."
  }
  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/azureFirewalls@2024-07-01"
    error_message = "resource_types should override the Firewall API version."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_both_ip_interfaces" {
  command = plan

  variables {
    firewall_ip_configuration = [{ name = "legacy" }]
    ip_configurations = {
      primary = {
        name      = "primary"
        subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/AzureFirewallSubnet"
      }
    }
  }

  expect_failures = [var.ip_configurations]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_missing_subnet" {
  command = plan

  variables {
    ip_configurations = {
      primary = { name = "primary" }
    }
  }

  expect_failures = [var.ip_configurations]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_wrong_subnet_name" {
  command = plan

  variables {
    ip_configurations = {
      primary = {
        name      = "primary"
        subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
      }
    }
  }

  expect_failures = [var.ip_configurations]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_invalid_sku_tier" {
  command = plan

  variables {
    firewall_sku_tier = "Ultra"
  }

  expect_failures = [var.firewall_sku_tier]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}