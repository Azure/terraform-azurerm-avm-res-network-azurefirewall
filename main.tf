data "azapi_client_config" "current" {}

resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = local.parent_id
  type      = var.resource_types.network_azure_firewalls
  body      = local.firewall_body
  # The placeholders in the body are always ignored, so on update the provider re-reads the firewall and
  # sends the live values instead, as the AzureRM provider did. A PUT resets every property it omits, and
  # classic rule collections are often managed outside this module.
  ignore_body_changes = distinct(concat(local.firewall_ignored_body_paths, var.ignore_body_changes.network_azure_firewalls))
  # Azure does not always return resource IDs, such as the firewall policy ID, in the casing they were sent
  # in. The AzureRM provider normalised them.
  ignore_casing = true
  # The AzureRM provider replaced the firewall whenever one of these inputs changed. The inputs are compared
  # rather than body paths, so reordering IP configurations, or adding or removing a public IP, updates the
  # firewall in place. While the prior value is null, as it is straight after upgrading from AzureRM,
  # nothing is replaced.
  replace_triggers_external_values = {
    management_ip_configuration = var.firewall_management_ip_configuration == null ? null : {
      name                 = var.firewall_management_ip_configuration.name
      public_ip_address_id = lower(var.firewall_management_ip_configuration.public_ip_address_id)
      subnet_id            = lower(var.firewall_management_ip_configuration.subnet_id)
    }
    sku_name   = var.firewall_sku_name
    subnet_ids = sort(distinct([for configuration in local.firewall_ip_configurations : lower(configuration.subnet_id) if configuration.subnet_id != null]))
    zones      = local.firewall_zones
  }
  response_export_values = [
    "properties.additionalProperties",
    "properties.hubIPAddresses",
    "properties.ipConfigurations",
    "properties.managementIpConfiguration",
    "properties.threatIntelMode",
  ]
  retry = var.retry
  tags  = var.tags

  timeouts {
    create = local.firewall_timeouts.create
    delete = local.firewall_timeouts.delete
    read   = local.firewall_timeouts.read
    update = local.firewall_timeouts.update
  }

  lifecycle {
    # Keeps the planned body consistent with the values in state, which AzAPI cannot fit into the
    # placeholders. The values actually sent come from the live read described above.
    ignore_changes = [
      body.properties.applicationRuleCollections,
      body.properties.natRuleCollections,
      body.properties.networkRuleCollections,
      body.properties.threatIntelMode,
      body.zones,
    ]
  }
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = var.lock.kind
      notes = coalesce(var.lock.notes, local.lock_notes[var.lock.kind])
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Create the lock last and remove it first. A ReadOnly lock blocks changes to the role assignments and
  # diagnostic settings.
  depends_on = [time_sleep.lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzAPI provider does not wait for it to be
# gone as the AzureRM provider did. This pause is destroyed after the lock and before the firewall and the
# resources under it, so they are not deleted while the lock still applies.
resource "time_sleep" "lock_removal" {
  count = var.lock != null ? 1 : 0

  destroy_duration = "30s"
  # Replacing the firewall replaces its lock, so the pause is replaced with them.
  triggers = {
    firewall_id = azapi_resource.this.id
  }

  depends_on = [
    azapi_resource.diagnostic_settings,
    azapi_resource.role_assignments,
  ]
}

# Role definitions are resolved here, case-insensitively as the AzureRM provider did, rather than by the
# interfaces module, whose lookup is case-sensitive. They are listed in the resource group rather than on
# the firewall, so the lookup does not wait for pending changes to the firewall and a role name that does
# not exist fails during plan.
data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = local.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location                                  = var.location
  enable_telemetry                          = var.enable_telemetry
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = azapi_resource.this.id
  type                 = var.resource_types.authorization_role_assignments
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_body_changes  = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider replaced a role assignment whenever one of its inputs changed. The inputs are
  # compared, rather than body paths or the resolved role definition ID, because Azure normalises role
  # definition IDs. While the prior value is null, as it is straight after upgrading from AzureRM,
  # nothing is replaced.
  replace_triggers_external_values = {
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    description                            = each.value.description
    name                                   = each.value.name
    principal_id                           = lower(each.value.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_definition_id_or_name)
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Upgraded assignments keep the GUID the AzureRM provider generated, while the interfaces module
    # generates a new one. Replacing them would fail under a CanNotDelete lock. A change to an explicit
    # name still replaces the assignment through replace_triggers_external_values.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "The role definition `${each.value.role_definition_id_or_name}` was not found in the resource group. Use the name of a role definition that can be assigned there, or the role definition's resource ID."
    }
  }
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = merge(
      {
        eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
        eventHubName                = each.value.event_hub_name
        logAnalyticsDestinationType = each.value.log_analytics_destination_type
        logs = tolist(concat(
          [for category in each.value.log_categories : { category = category, categoryGroup = null, enabled = true }],
          [for group in each.value.log_groups : { category = null, categoryGroup = group, enabled = true }],
        ))
        marketplacePartnerId = each.value.marketplace_partner_resource_id
        storageAccountId     = each.value.storage_account_resource_id
        workspaceId          = each.value.workspace_resource_id
      },
      # Azure lists every metric category, disabled, when none is sent, so an empty list is not sent.
      length(each.value.metric_categories) > 0 ? {
        metrics = [for category in each.value.metric_categories : { category = category, enabled = true }]
      } : {},
    )
  }
  ignore_body_changes = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  ignore_casing       = true
  # Azure returns every log category group of the firewall, disabling those that were not sent. List items
  # are matched by category and items that are not configured are ignored, so they are not reported as
  # changes.
  ignore_other_items_in_list = ["properties.logs", "properties.metrics"]
  list_unique_id_property = {
    "properties.logs"    = "category, categoryGroup"
    "properties.metrics" = "category"
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
