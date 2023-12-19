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

variable "firewall_dns_proxy_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether DNS proxy is enabled. It will forward DNS requests to the DNS servers when set to `true`. It will be set to `true` if `dns_servers` provided with a not empty list."
}

variable "firewall_dns_servers" {
  type        = list(string)
  default     = null
  description = "(Optional) A list of DNS servers that the Azure Firewall will direct DNS traffic to the for name resolution."
}

variable "firewall_policy_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the Firewall Policy applied to this Firewall."
}

variable "firewall_ip_configuration" {
  type = list(object({
    name                 = string
    public_ip_address_id = optional(string)
    subnet_id            = optional(string)
  }))
  default     = null
  description = <<-EOT
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

variable "firewall_private_ip_ranges" {
  type        = set(string)
  default     = null
  description = "(Optional) A list of SNAT private CIDR IP ranges, or the special string `IANAPrivateRanges`, which indicates Azure Firewall does not SNAT when the destination IP address is a private range per IANA RFC 1918."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

variable "firewall_threat_intel_mode" {
  type        = string
  default     = null
  description = "(Optional) The operation mode for threat intelligence-based filtering. Possible values are: `Off`, `Alert` and `Deny`. Defaults to `Alert`."
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
  default     = null
  description = "(Optional) Specifies a list of Availability Zones in which this Azure Firewall should be located. Changing this forces a new Azure Firewall to be created."
}

variable "public_ip_allocation_method" {
  type        = string
  description = "(Required) Defines the allocation method for this IP address. Possible values are `Static` or `Dynamic`."
  nullable    = false
}

variable "public_ip_ddos_protection_mode" {
  type        = string
  description = "(Optional) The DDoS protection mode of the public IP. Possible values are `Disabled`, `Enabled`, and `VirtualNetworkInherited`. Defaults to `VirtualNetworkInherited`."
  default     = null
}

variable "public_ip_ddos_protection_plan_id" {
  type        = string
  description = "(Optional) The ID of DDoS protection plan associated with the public IP."
  default     = null
}

variable "public_ip_domain_name_label" {
  type        = string
  description = "(Optional) Label for the Domain Name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system."
  default     = null
}

variable "public_ip_edge_zone" {
  type        = string
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Public IP should exist. Changing this forces a new Public IP to be created."
  default     = null
}

variable "public_ip_idle_timeout_in_minutes" {
  type        = number
  description = "(Optional) Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes."
  default     = null
}

variable "public_ip_ip_tags" {
  type        = map(string)
  description = "(Optional) A mapping of IP tags to assign to the public IP. Changing this forces a new resource to be created."
  default     = null
}

variable "public_ip_ip_version" {
  type        = string
  description = "(Optional) The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Defaults to `IPv4`."
  default     = null
}

variable "public_ip_location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the Public IP should exist. Changing this forces a new resource to be created."
  nullable    = false
}

variable "public_ip_name" {
  type        = string
  description = "(Required) Specifies the name of the Public IP. Changing this forces a new Public IP to be created."
  nullable    = false
}

variable "public_ip_public_ip_prefix_id" {
  type        = string
  description = "(Optional) If specified then public IP address allocated will be provided from the public IP prefix resource. Changing this forces a new resource to be created."
  default     = null
}

variable "public_ip_resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group where this Public IP should exist. Changing this forces a new Public IP to be created."
  nullable    = false
}

variable "public_ip_reverse_fqdn" {
  type        = string
  description = "(Optional) A fully qualified domain name that resolves to this public IP address. If the reverseFqdn is specified, then a PTR DNS record is created pointing from the IP address in the in-addr.arpa domain to the reverse FQDN."
  default     = null
}

variable "public_ip_sku" {
  type        = string
  description = "(Optional) The SKU of the Public IP. Accepted values are `Basic` and `Standard`. Defaults to `Basic`. Changing this forces a new resource to be created."
  default     = null
}

variable "public_ip_sku_tier" {
  type        = string
  description = "(Optional) The SKU Tier that should be used for the Public IP. Possible values are `Regional` and `Global`. Defaults to `Regional`. Changing this forces a new resource to be created."
  default     = null
}

variable "public_ip_tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = null
}

variable "public_ip_zones" {
  type        = set(string)
  description = "(Optional) A collection containing the availability zone to allocate the Public IP in. Changing this forces a new resource to be created."
  default     = null
}

variable "public_ip_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 30 minutes) Used when creating the Public IP.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Public IP.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Public IP.
 - `update` - (Defaults to 30 minutes) Used when updating the Public IP.
EOT

}


variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")


  })
  default     = {}
  description = "The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
  nullable    = false

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
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
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - The description of the role assignment.
  - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - The condition which will be used to scope the role assignment.
  - `condition_version` - The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
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
  default  = {}
  nullable = false

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
  description = <<DESCRIPTION
  A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
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
