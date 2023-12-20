resource "azurerm_firewall" "this" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.firewall_sku_name
  sku_tier            = var.firewall_sku_tier
  dns_proxy_enabled   = var.firewall_dns_proxy_enabled
  dns_servers         = var.firewall_dns_servers
  firewall_policy_id  = var.firewall_policy_id
  private_ip_ranges   = var.firewall_private_ip_ranges
  tags                = var.tags
  threat_intel_mode   = var.firewall_threat_intel_mode
  zones               = var.firewall_zones

  dynamic "ip_configuration" {
    for_each = var.firewall_ip_configuration == null ? [] : var.firewall_ip_configuration
    content {
      name                 = ip_configuration.value.name
      public_ip_address_id = ip_configuration.value.public_ip_address_id
      subnet_id            = ip_configuration.value.subnet_id
    }
  }
  dynamic "management_ip_configuration" {
    for_each = var.firewall_management_ip_configuration == null ? [] : [var.firewall_management_ip_configuration]
    content {
      name                 = management_ip_configuration.value.name
      public_ip_address_id = management_ip_configuration.value.public_ip_address_id
      subnet_id            = management_ip_configuration.value.subnet_id
    }
  }
  dynamic "timeouts" {
    for_each = var.firewall_timeouts == null ? [] : [var.firewall_timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
  dynamic "virtual_hub" {
    for_each = var.firewall_virtual_hub == null ? [] : [var.firewall_virtual_hub]
    content {
      virtual_hub_id  = virtual_hub.value.virtual_hub_id
      public_ip_count = virtual_hub.value.public_ip_count
    }
  }
}

# Creating Public IP for the Azure Firewall
resource "azurerm_public_ip" "this" {
  allocation_method       = var.public_ip_allocation_method
  ddos_protection_mode    = var.public_ip_ddos_protection_mode
  ddos_protection_plan_id = var.public_ip_ddos_protection_plan_id
  domain_name_label       = var.public_ip_domain_name_label
  edge_zone               = var.public_ip_edge_zone
  idle_timeout_in_minutes = var.public_ip_idle_timeout_in_minutes
  ip_tags                 = var.public_ip_ip_tags
  ip_version              = var.public_ip_ip_version
  location                = var.public_ip_location
  name                    = var.public_ip_name
  public_ip_prefix_id     = var.public_ip_public_ip_prefix_id
  resource_group_name     = var.public_ip_resource_group_name
  reverse_fqdn            = var.public_ip_reverse_fqdn
  sku                     = var.public_ip_sku
  sku_tier                = var.public_ip_sku_tier
  tags                    = var.public_ip_tags
  zones                   = var.public_ip_zones
  dynamic "timeouts" {
    for_each = var.public_ip_timeouts == null ? [] : [var.public_ip_timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

}

# Applying Management Lock to the Virtual Network if specified.
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_firewall.this.id
}

# Assigning Roles to the Virtual Network based on the provided configurations.
resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_firewall.this.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                       = var.diagnostic_settings
  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_firewall.this.id
  storage_account_id             = each.value.storage_account_resource_id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  partner_solution_id            = each.value.marketplace_partner_resource_id
  log_analytics_workspace_id     = each.value.workspace_resource_id
  log_analytics_destination_type = each.value.log_analytics_destination_type

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
  }
}



