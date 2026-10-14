mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry    = false
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Standard"
  location            = "westeurope"
  name                = "test-firewall"
  resource_group_name = "test-rg"
}

override_resource {
  target = azurerm_firewall.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/azureFirewalls/test-firewall"
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
    condition     = length(azurerm_firewall.this.ip_configuration) == 2 && azurerm_firewall.this.tags.environment == "test"
    error_message = "Both public IP configurations and tags must be preserved."
  }
  assert {
    condition     = output.resource_id == output.resource.id && output.resource.name == var.name
    error_message = "Both existing Firewall output contracts must remain usable."
  }
  assert {
    condition     = length(modtm_telemetry.telemetry) == 0 && length(data.azapi_client_config.telemetry) == 0
    error_message = "Disabling telemetry must omit the telemetry resource and client configuration."
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
  }

  assert {
    condition     = one(azurerm_firewall.this.ip_configuration).name == "legacy" && one(azurerm_firewall.this.management_ip_configuration).name == "management"
    error_message = "The deprecated IP interface and management configuration must still work."
  }
  assert {
    condition     = azurerm_firewall.this.timeouts.create == "100m" && azurerm_firewall.this.timeouts.update == "100m"
    error_message = "Custom Firewall timeouts must remain wired."
  }
}

run "virtual_hub" {
  command = apply

  variables {
    firewall_sku_name = "AZFW_Hub"
    firewall_virtual_hub = {
      virtual_hub_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualHubs/test-hub"
      public_ip_count = 2
    }
  }

  assert {
    condition     = one(azurerm_firewall.this.virtual_hub).public_ip_count == 2 && azurerm_firewall.this.sku_name == "AZFW_Hub"
    error_message = "Virtual Hub Firewall settings must be preserved."
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
    }
    lock = { kind = "CanNotDelete" }
    role_assignments = {
      reader = {
        principal_id               = "00000000-0000-0000-0000-000000000001"
        role_definition_id_or_name = "Reader"
        description                = "Read the test firewall"
      }
    }
  }

  assert {
    condition     = one(azurerm_monitor_diagnostic_setting.this["logs"].enabled_log).category_group == "allLogs" && one(azurerm_monitor_diagnostic_setting.this["logs"].metric).category == "AllMetrics"
    error_message = "Diagnostic log groups and metrics must be preserved."
  }
  assert {
    condition     = azurerm_management_lock.this[0].scope == output.resource_id && azurerm_management_lock.this[0].lock_level == "CanNotDelete"
    error_message = "The lock must retain its Firewall scope and level."
  }
  assert {
    condition     = azurerm_role_assignment.this["reader"].description == "Read the test firewall" && azurerm_role_assignment.this["reader"].scope == output.resource_id
    error_message = "Role assignments must retain their scope and honor the documented description."
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
}

run "rejects_missing_subnet" {
  command = plan

  variables {
    ip_configurations = {
      primary = { name = "primary" }
    }
  }

  expect_failures = [var.ip_configurations]
}
