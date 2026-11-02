locals {
  firewall_body = merge(
    {
      properties = merge(
        {
          additionalProperties = length(local.firewall_private_ip_ranges) > 0 ? { "Network.SNAT.PrivateRanges" = join(",", local.firewall_private_ip_ranges) } : {}
          # Placeholders, see main.tf. Azure keeps classic rule collections only when they are sent back.
          applicationRuleCollections = []
          natRuleCollections         = []
          networkRuleCollections     = []
          # A null value keeps the type of the body known when the policy ID is not known until apply.
          firewallPolicy = var.firewall_policy_id == null ? null : { id = var.firewall_policy_id }
          ipConfigurations = [
            for configuration in local.firewall_ip_configurations : {
              name = configuration.name
              properties = {
                publicIPAddress = configuration.public_ip_address_id == null ? null : { id = configuration.public_ip_address_id }
                subnet          = configuration.subnet_id == null ? null : { id = configuration.subnet_id }
              }
            }
          ]
          sku = {
            name = var.firewall_sku_name
            tier = var.firewall_sku_tier
          }
          # Placeholder, see main.tf. The AzureRM provider sent an empty value on create and the live value
          # on update.
          threatIntelMode = ""
        },
        var.firewall_management_ip_configuration == null ? {} : {
          managementIpConfiguration = {
            name = var.firewall_management_ip_configuration.name
            properties = {
              publicIPAddress = { id = var.firewall_management_ip_configuration.public_ip_address_id }
              subnet          = { id = var.firewall_management_ip_configuration.subnet_id }
            }
          }
        },
        var.firewall_virtual_hub == null ? {} : {
          # Only the count is sent. Azure keeps the existing public IPs when it is unchanged or increased.
          hubIPAddresses = {
            publicIPs = {
              count = coalesce(var.firewall_virtual_hub.public_ip_count, 1)
            }
          }
        },
        var.firewall_virtual_hub == null ? {} : {
          virtualHub = {
            id = var.firewall_virtual_hub.virtual_hub_id
          }
        },
      )
    },
    length(local.firewall_zones) > 0 ? { zones = local.firewall_zones } : {},
  )
  firewall_ignored_body_paths = [
    "properties.applicationRuleCollections",
    "properties.natRuleCollections",
    "properties.networkRuleCollections",
    "properties.threatIntelMode",
    # Zones cannot change in place: a change replaces the Firewall, which sends the configured zones. On update
    # the live zones are sent back, in the order the AzureRM provider sent them.
    "zones",
  ]
  # The deprecated list first, then the map in key order: the order the AzureRM provider sent them in.
  firewall_ip_configurations = concat(
    var.firewall_ip_configuration == null ? [] : var.firewall_ip_configuration,
    values(var.ip_configurations),
  )
  firewall_private_ip_ranges = var.firewall_private_ip_ranges == null ? [] : tolist(var.firewall_private_ip_ranges)
  # The AzureRM provider's defaults for the firewall, which can take longer than the AzAPI defaults allow.
  firewall_timeouts = {
    create = coalesce(try(var.firewall_timeouts.create, null), try(var.timeouts.create, null), "90m")
    delete = coalesce(try(var.firewall_timeouts.delete, null), try(var.timeouts.delete, null), "90m")
    read   = coalesce(try(var.firewall_timeouts.read, null), try(var.timeouts.read, null), "5m")
    update = coalesce(try(var.firewall_timeouts.update, null), try(var.timeouts.update, null), "90m")
  }
  firewall_zones = var.firewall_zones == null ? [] : sort(tolist(var.firewall_zones))
  # The notes this module has always written, so that upgrading leaves existing locks unchanged.
  lock_notes = {
    CanNotDelete = "Cannot delete the resource or its child resources."
    ReadOnly     = "Cannot delete or modify the resource or its child resources."
  }
  parent_id = var.parent_id != null ? var.parent_id : "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  # Role names are matched case-insensitively, as the AzureRM provider matched them.
  role_definition_ids_by_name = length(var.role_assignments) > 0 ? {
    for definition in data.azapi_resource_list.role_definitions[0].output.results : lower(definition.role_name) => definition.id...
  } : {}
  role_definition_resource_substring = "/providers/microsoft.authorization/roledefinitions/"
  role_assignments = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      # The AzureRM provider sent this principal type when the flag was set, which skips the Entra ID
      # existence check that fails for newly created service principals.
      principal_type = assignment.principal_type == null && assignment.skip_service_principal_aad_check ? "ServicePrincipal" : assignment.principal_type
      # Names resolve to IDs. Tenant-level IDs are qualified with the subscription, which is the form Azure
      # returns, so that the configuration and the deployed assignment compare equal.
      role_definition_id_or_name = (
        !strcontains(lower(assignment.role_definition_id_or_name), local.role_definition_resource_substring) ? try(local.role_definition_ids_by_name[lower(assignment.role_definition_id_or_name)][0], assignment.role_definition_id_or_name) :
        startswith(lower(assignment.role_definition_id_or_name), "/providers/") ? "/subscriptions/${local.subscription_id}${assignment.role_definition_id_or_name}" :
        assignment.role_definition_id_or_name
      )
    })
  }
  subscription_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", local.parent_id).subscription_id
}
