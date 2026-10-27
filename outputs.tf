output "name" {
  description = "The name of the Firewall."
  value       = azapi_resource.this.name
}

output "private_ip_address" {
  description = "The private IP address of the Firewall: the address of the IP configuration in `AzureFirewallSubnet`, or the private hub IP address of a Firewall in a Virtual Hub."
  value = var.firewall_virtual_hub != null ? try(azapi_resource.this.output.properties.hubIPAddresses.privateIPAddress, null) : try(
    [for configuration in azapi_resource.this.output.properties.ipConfigurations : configuration.properties.privateIPAddress if try(configuration.properties.privateIPAddress, null) != null][0],
    null
  )
}

output "resource" {
  description = <<-EOT
  The Firewall, with the attribute names and empty values of the `azurerm_firewall` resource that earlier versions of this module returned, so that existing references keep working. Prefer `resource_id`, `name` and `private_ip_address`.
  Examples:
  - module.firewall.resource.id
  - module.firewall.resource.name
  - module.firewall.resource.ip_configuration[0].private_ip_address
  - module.firewall.resource.virtual_hub[0].private_ip_address
  EOT
  value = {
    dns_proxy_enabled  = try(azapi_resource.this.output.properties.additionalProperties["Network.DNS.EnableProxy"] == "true", false)
    dns_servers        = try(split(",", azapi_resource.this.output.properties.additionalProperties["Network.DNS.Servers"]), [])
    firewall_policy_id = var.firewall_policy_id == null ? "" : var.firewall_policy_id
    id                 = azapi_resource.this.id
    ip_configuration = [
      for configuration in local.firewall_ip_configurations : {
        name                 = configuration.name
        private_ip_address   = try([for deployed in azapi_resource.this.output.properties.ipConfigurations : deployed.properties.privateIPAddress if deployed.name == configuration.name][0], "")
        public_ip_address_id = configuration.public_ip_address_id == null ? "" : configuration.public_ip_address_id
        subnet_id            = configuration.subnet_id == null ? "" : configuration.subnet_id
      }
    ]
    location = azapi_resource.this.location
    management_ip_configuration = var.firewall_management_ip_configuration == null ? [] : [{
      name                 = var.firewall_management_ip_configuration.name
      private_ip_address   = try(azapi_resource.this.output.properties.managementIpConfiguration.properties.privateIPAddress, "")
      public_ip_address_id = var.firewall_management_ip_configuration.public_ip_address_id
      subnet_id            = var.firewall_management_ip_configuration.subnet_id
    }]
    name                = azapi_resource.this.name
    private_ip_ranges   = toset(local.firewall_private_ip_ranges)
    resource_group_name = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", local.parent_id).resource_group_name
    sku_name            = var.firewall_sku_name
    sku_tier            = var.firewall_sku_tier
    tags                = azapi_resource.this.tags == null ? tomap({}) : azapi_resource.this.tags
    threat_intel_mode   = try(azapi_resource.this.output.properties.threatIntelMode, "")
    virtual_hub = var.firewall_virtual_hub == null ? [] : [{
      private_ip_address  = try(azapi_resource.this.output.properties.hubIPAddresses.privateIPAddress, "")
      public_ip_addresses = try([for address in azapi_resource.this.output.properties.hubIPAddresses.publicIPs.addresses : address.address], [])
      public_ip_count     = coalesce(var.firewall_virtual_hub.public_ip_count, 1)
      virtual_hub_id      = var.firewall_virtual_hub.virtual_hub_id
    }]
    zones = local.firewall_zones
  }
}

output "resource_id" {
  description = "This is the resource id for the firewall resource."
  value       = azapi_resource.this.id
}
