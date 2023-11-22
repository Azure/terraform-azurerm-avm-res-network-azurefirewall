variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "location" {
  type        = string
  default     = null
  description = "The Azure Region where the resources will be deployed."
}

variable "firewall_name" {
  type        = string
  description = "The name of the Azure Firewall to be created."
}

variable "firewall_sku_name" {
  type        = string
  description = "The name of the Azure Firewall SKU."
  validation {
    condition     = contains(["AZFW_VNet", "AZFW_Hub"], var.firewall_sku_name)
    error_message = "value must be one of the following: AZFW_VNet, AZFW_Hub"
  }
}

variable "firewall_sku_tier" {
  type        = string
  description = "Firewall SKU."
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "The SKU must be one of the following: Standard, Premium"
  }
}

variable "firewall_ip_config_name" {
  type        = string
  description = "The name of the Azure Firewall IP Config."
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet where the Azure Firewall will be deployed."
}
variable "public_ip_address_config" {
  type = map(object({
    resource_group_name              = string
    location                         = string
    allocation_method                = string
    zones                            = optional(list(number), null)
    sku                              = optional(string, null)
    sku_tier                         = optional(string, null)
    ddos_protection_mode             = optional(string, null)
    ddos_protection_plan_resource_id = optional(string, null)
    domain_name_label                = optional(string, null)
    reverse_fqdn                     = optional(string, null)
    idle_timeout_in_minutes          = optional(number, null)
    ip_version                       = optional(string, "IPv4")
    ip_tags                          = optional(map(string), null)
    public_ip_prefix_resource_id     = optional(string, null)
    tags                             = optional(map(any), null)
  }))
  default     = {}
  description = <<DESCRIPTION
  
  An object variable that configures the settings that will be the same for all public IPs for this Azure Firewall
  Each object has 14 parameters:

  - `resource_group_name`: (Required) Specifies the resource group to deploy all of the public IP addresses to be created.
  - `location`: (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  - `allocation_method`: (Required) The allocation method for this IP address. Possible valuse are Static or Dynamic.
  - `ddos_protection_mode`: (Optional) The DDoS protection mode of the public IP. Possible values are Disabled, Enabled, and VirtualNetworkInherited. Defaults to VirtualNetworkInherited.
  - `ddos_protection_plan_resource_id`: (Optional) The ID of DDoS protection plan associated with the public IP
  - `domain_name_label`: (Optional) The label for the Domain Name. This will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system.
  - `idle_timeout_in_minutes`: (Optional) Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes.
  - `ip_tags`: (Optional) A mapping of IP tags to assign to the public IP. Changing this forces a new resource to be created.
  - `ip_version`: (Optional) The version of IP to use for the Public IPs. Possible valuse are IPv4 or IPv6. Changing this forces a new resource to be created.
  - `public_ip_prefix_resource_id`: (Optional) If specified then public IP address allocated will be provided from the public IP prefix resource. Changing this forces a new resource to be created.
  - `reverse_fqdn`: (Optional) A fully qualified domain name that resolves to this public IP address. If the reverseFqdn is specified, then a PTR DNS record is created pointing from the IP address in the in-addr.arpa domain to the reverse FQDN.
  - `sku`: (Optional) The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Standard. Changing this forces a new resource to be created.
  - `sku_tier`: (Optional) The SKU Tier that should be used for the Public IP. Possible values are Regional and Global. Defaults to Regional. Changing this forces a new resource to be created.
  - `tags`: (Optional) The collection of tags to be assigned to all every Public IP.

  Example Input:
  ```terraform
  # Public IP config
  public_ip_config =  {
      allocation_method                = "Static"
      ddos_protection_mode             = "VirtualNetworkInherited"
      idle_timeout_in_minutes          = 4
      ip_version                       = "IPv4"
      sku_tier                         = "Regional"
    }
 
  DESCRIPTION

  validation {
    condition     = contains(["Dynamic", "Static"], var.public_ip_address_config.allocation_method)
    error_message = "The allocation method must be one of the following: Dynamic, Static"
  }
  validation {
    condition     = contains(["Disabled", "Enabled", "VirtualNetworkInherited"], var.public_ip_address_config.ddos_protection_mode)
    error_message = "The acceptable value for `ddos_protection_mode` are Disabled, Enabled or VirtualNetworkInherited"
  }
  validation {
    condition     = (contains(["Disabled", "VirtualNetworkInherited"], var.public_ip_address_config.ddos_protection_mode) && var.public_ip_address_config.ddos_protection_plan_resource_id == null) || (contains(["Enabled"], var.public_ip_address_config.ddos_protection_mode) && var.public_ip_address_config.ddos_protection_plan_resource_id != null)
    error_message = "A `ddos_protection_plan_resource_id` can only be set when `ddos_protection_mode` is set to Enabled"
  }
  validation {
    condition     = var.public_ip_address_config.idle_timeout_in_minutes == null ? true : var.public_ip_address_config.idle_timeout_in_minutes >= 4 && var.public_ip_address_config.idle_timeout_in_minutes <= 30
    error_message = "The value for `idle_timeout_in_minutes` must be between 4 and 30"
  }
  validation {
    condition     = contains(["IPv4", "IPv6"], var.public_ip_address_config.ip_version)
    error_message = "The accepted values for `ip_version` are IPv4 or IPv6"
  }
  validation {
    condition     = (contains(["IPv4", "IPv6"], var.public_ip_address_config.ip_version) && var.public_ip_address_config.allocation_method == "Static") || (contains(["IPv4"], var.public_ip_address_config.ip_version) && var.public_ip_address_config.allocation_method == "Dynamic") # Could probably format this to be consistent in line
    error_message = "Only Static `allocation_method` supported for IPv6"
  }
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_address_config.sku)
    error_message = "The acceptable values for `sku` are Basic or Standard"
  }
  validation {
    condition     = contains(["Global", "Regional"], var.public_ip_address_config.sku_tier)
    error_message = "The acceptable values for `sku_tier` are Global or Regional"
  }
}

//required AVM interfaces

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories_and_groups                = optional(set(string), ["allLogs"])
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
}


variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, true)
    condition                              = optional(string, null)
    condition_version                      = optional(string, "2.0")
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")


  })
  description = "The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}


# Example resource implementation

variable "tags" {
  type = map(any)
  default = {

  }
  description = <<DESCRIPTION
The tags to associate with your network and subnets.
DESCRIPTION
}