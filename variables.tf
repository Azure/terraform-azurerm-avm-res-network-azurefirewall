variable "firewall_sku_name" {
  type        = string
  description = "(Required) SKU name of the Firewall. Possible values are `AZFW_Hub` and `AZFW_VNet`. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = contains(["AZFW_Hub", "AZFW_VNet"], var.firewall_sku_name)
    error_message = "`firewall_sku_name` must be `AZFW_Hub` or `AZFW_VNet`."
  }
}

variable "firewall_sku_tier" {
  type        = string
  description = "(Required) SKU tier of the Firewall. Possible values are `Premium`, `Standard` and `Basic`."
  nullable    = false

  validation {
    condition     = contains(["Basic", "Premium", "Standard"], var.firewall_sku_tier)
    error_message = "`firewall_sku_tier` must be `Basic`, `Premium` or `Standard`."
  }
}

variable "location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) Specifies the name of the Firewall. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(regex("^[[:alnum:]]([[:alnum:]_.-]{0,78}?[[:alnum:]_])?$", var.name))
    error_message = "The name must be between 1 and 80 characters long, start with a letter or number, end with a letter, number or underscore, and contain only letters, numbers, underscores, periods and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the resource. Ignored when `parent_id` is set. Changing this forces a new resource to be created."
  nullable    = false
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of diagnostic settings to create on the Firewall. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "firewall_ip_configuration" {
  type = list(object({
    name                 = string
    public_ip_address_id = optional(string)
    subnet_id            = optional(string)
  }))
  default     = null
  description = <<-EOT
[DEPRECATED] Use `ip_configurations` instead. This variable is deprecated and will be removed in a future version.

 - `name` - (Required) Specifies the name of the IP Configuration.
 - `public_ip_address_id` - (Optional) The ID of the Public IP Address associated with the firewall.
 - `subnet_id` - (Optional) Reference to the subnet associated with the IP Configuration. Changing this forces a new resource to be created.
EOT

  validation {
    condition = alltrue([
      for configuration in coalesce(var.firewall_ip_configuration, []) :
      configuration.subnet_id == null || endswith(configuration.subnet_id, "/subnets/AzureFirewallSubnet")
    ])
    error_message = "The subnet of the firewall must be named `AzureFirewallSubnet`."
  }
}

variable "firewall_management_ip_configuration" {
  type = object({
    name                 = string
    public_ip_address_id = string
    subnet_id            = string
  })
  default     = null
  description = <<-EOT
The management IP configuration of the firewall. Adding, removing or changing it forces a new resource to be created.

 - `name` - (Required) Specifies the name of the IP Configuration.
 - `public_ip_address_id` - (Required) The ID of the Public IP Address associated with the firewall.
 - `subnet_id` - (Required) Reference to the subnet associated with the IP Configuration. Changing this forces a new resource to be created.
EOT

  validation {
    condition     = var.firewall_management_ip_configuration == null || endswith(try(var.firewall_management_ip_configuration.subnet_id, ""), "/subnets/AzureFirewallManagementSubnet")
    error_message = "The management subnet of the firewall must be named `AzureFirewallManagementSubnet`."
  }
}

variable "firewall_policy_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the Firewall Policy applied to this Firewall."
}

variable "firewall_private_ip_ranges" {
  type        = set(string)
  default     = null
  description = "(Optional) A list of SNAT private CIDR IP ranges, or the special string `IANAPrivateRanges`, which indicates Azure Firewall does not SNAT when the destination IP address is a private range per IANA RFC 1918."
}

variable "firewall_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
Timeouts for the Firewall. Each value takes precedence over the same value in `timeouts`.

 - `create` - (Defaults to 90 minutes) Used when creating the Firewall.
 - `delete` - (Defaults to 90 minutes) Used when deleting the Firewall.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Firewall.
 - `update` - (Defaults to 90 minutes) Used when updating the Firewall.
EOT
}

variable "firewall_virtual_hub" {
  type = object({
    public_ip_count = optional(number)
    virtual_hub_id  = string
  })
  default     = null
  description = <<-EOT
 - `public_ip_count` - (Optional) Specifies the number of public IPs to assign to the Firewall. Defaults to `1`. Azure keeps the existing public IPs when the count is increased. It cannot be reduced in place, because Azure then requires the public IPs to retain: remove public IPs in the Azure portal, Azure CLI or Azure PowerShell first, then set the new count.
 - `virtual_hub_id` - (Required) Specifies the ID of the Virtual Hub where the Firewall resides in.
EOT

  validation {
    condition     = try(var.firewall_virtual_hub.public_ip_count, null) == null || try(var.firewall_virtual_hub.public_ip_count >= 1, false)
    error_message = "`firewall_virtual_hub.public_ip_count` must be at least 1."
  }
}

variable "firewall_zones" {
  type        = set(string)
  default     = ["1", "2", "3"]
  description = "(Required) Specifies a list of Availability Zones in which this Azure Firewall should be located. Changing this forces a new Azure Firewall to be created."
}

variable "ignore_body_changes" {
  type = object({
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
    insights_diagnostic_settings   = optional(list(string), [])
    network_azure_firewalls        = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each resource's `body` whose changes the AzAPI provider ignores. Prefer Terraform's `lifecycle.ignore_changes` when the paths are static; use this variable when the paths must be derived from variables or other non-static values.

Paths use dot notation, for example `properties.sku.name`. Individual list items cannot be targeted — ignore the whole list property instead. Configuration changes at an ignored path are **not** sent to Azure until that path is removed from the list.

Supplying a non-empty value requires Terraform 1.11 or later, because `ignore_body_changes` is a write-only argument. Changes take effect only after an apply, because the value is held in provider-private state.

- `authorization_locks` - Ignored body paths for the management lock.
- `authorization_role_assignments` - Ignored body paths for the role assignments.
- `insights_diagnostic_settings` - Ignored body paths for the diagnostic settings.
- `network_azure_firewalls` - Ignored body paths for the Firewall. `properties.applicationRuleCollections`, `properties.natRuleCollections`, `properties.networkRuleCollections`, `properties.threatIntelMode` and `zones` are always ignored in addition to these paths, so that updating the Firewall never removes classic rule collections managed outside this module and never resets the threat intelligence mode. Changing `firewall_zones` still replaces the Firewall.
DESCRIPTION
  nullable    = false
}

variable "ip_configurations" {
  type = map(object({
    name                 = string
    public_ip_address_id = optional(string)
    subnet_id            = optional(string)
  }))
  default     = {}
  description = <<-EOT
This variable defines the IP configurations for the Azure Firewall. It is a map where each key is a unique identifier for the configuration. Adding or removing an IP configuration updates the Firewall in place.

 - `name` - (Required) Specifies the name of the IP Configuration.
 - `public_ip_address_id` - (Optional) The ID of the Public IP Address associated with the firewall.
 - `subnet_id` - (Optional) Reference to the subnet associated with the IP Configuration. This should only be supplied for one ip configuration. Changing this forces a new resource to be created.
EOT
  nullable    = false

  validation {
    condition     = length(var.ip_configurations) > 0 ? length([for _, v in var.ip_configurations : v if v.subnet_id != null]) == 1 : true
    error_message = "At least one and only one IP configuration may contain a subnet_id."
  }
  validation {
    condition     = length(var.ip_configurations) > 0 && length(var.firewall_ip_configuration == null ? [] : var.firewall_ip_configuration) > 0 ? false : true
    error_message = "The `firewall_ip_configuration` variable is deprecated and should not be used alongside `ip_configurations`. Please use `ip_configurations` instead."
  }
  validation {
    condition     = alltrue([for _, v in var.ip_configurations : v.subnet_id == null || endswith(v.subnet_id, "/subnets/AzureFirewallSubnet")])
    error_message = "The subnet of the firewall must be named `AzureFirewallSubnet`."
  }
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  - `notes` - (Optional) Notes about the lock. This value maps to `Microsoft.Authorization/locks.properties.notes`. If not specified, a note describing the lock `kind` is used.

  A `ReadOnly` lock also blocks changes to the Firewall's role assignments and diagnostic settings.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "parent_id" {
  type        = string
  default     = null
  description = "The resource ID of the resource group in which to create the Firewall, for example `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg`. When provided, takes precedence over `resource_group_name`. Changing this forces a new resource to be created."

  validation {
    condition     = var.parent_id == null || can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID, or null."
  }
}

variable "resource_types" {
  type = object({
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_diagnostic_settings   = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    network_azure_firewalls        = optional(string, "Microsoft.Network/azureFirewalls@2025-01-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module, in `<provider>/<resource>@<api-version>` form. Each key defaults to a tested value; supply only the keys you want to override, for example to target a sovereign cloud that serves older API versions.

- `authorization_locks` - The management lock.
- `authorization_role_assignments` - The role assignments.
- `insights_diagnostic_settings` - The diagnostic settings. The default is a preview version because the stable version does not support log category groups.
- `network_azure_firewalls` - The Firewall.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string, null)
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the Firewall. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the role assignment. If not set, a random UUID will be generated. Changing this forces the creation of a new resource. Role assignments created by earlier versions of this module keep their existing name.
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal. A name is matched, ignoring case, against the role definitions that can be assigned in the resource group. For a custom role that can only be assigned on this Firewall, use its ID.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true and `principal_type` is not set, `principal_type` is set to `ServicePrincipal`, which skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for _, v in var.role_assignments :
      v.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", v.delegated_managed_identity_resource_id))
    ])
    error_message = "Each `role_assignments[*].delegated_managed_identity_resource_id` must be a valid user-assigned managed identity resource ID, or null."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource managed by the module. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`). For the Firewall, `firewall_timeouts` takes precedence and the defaults are those described there.

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
