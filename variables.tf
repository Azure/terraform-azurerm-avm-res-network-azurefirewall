variable "firewall_sku_name" {
  type        = string
  description = "(Required) SKU name of the Firewall. Possible values are `AZFW_Hub` and `AZFW_VNet`. Changing this forces a new resource to be created."
  nullable    = false
}

variable "firewall_sku_tier" {
  type        = string
  description = "(Required) SKU tier of the Firewall. Possible values are `Premium`, `Standard` and `Basic`."
  nullable    = false
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
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the resource. Changing this forces a new resource to be created."
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
}

variable "firewall_management_ip_configuration" {
  type = object({
    name                 = string
    public_ip_address_id = string
    subnet_id            = string
  })
  default     = null
  description = <<-EOT
 - `name` - (Required) Specifies the name of the IP Configuration.
 - `public_ip_address_id` - (Required) The ID of the Public IP Address associated with the firewall.
 - `subnet_id` - (Required) Reference to the subnet associated with the IP Configuration. Changing this forces a new resource to be created.
EOT
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
 - `public_ip_count` - (Optional) Specifies the number of public IPs to assign to the Firewall. Defaults to `1`.
 - `virtual_hub_id` - (Required) Specifies the ID of the Virtual Hub where the Firewall resides in.
EOT
}

variable "firewall_zones" {
  type        = set(string)
  default     = ["1", "2", "3"]
  description = "(Required) Specifies a list of Availability Zones in which this Azure Firewall should be located. Changing this forces a new Azure Firewall to be created."
}

variable "ip_configurations" {
  type = map(object({
    name                 = string
    public_ip_address_id = optional(string)
    subnet_id            = optional(string)
  }))
  default     = {}
  description = <<-EOT
This variable defines the IP configurations for the Azure Firewall. It is a map where each key is a unique identifier for the configuration.

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
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "role_assignments" {
  type = map(object({
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

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
