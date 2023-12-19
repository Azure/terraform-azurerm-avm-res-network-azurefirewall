<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-network-firewall

Module to deploy Azure Firewall

"Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to https://semver.org/"

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.71.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_firewall.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_firewall_sku_name"></a> [firewall\_sku\_name](#input\_firewall\_sku\_name)

Description: (Required) SKU name of the Firewall. Possible values are `AZFW_Hub` and `AZFW_VNet`. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_firewall_sku_tier"></a> [firewall\_sku\_tier](#input\_firewall\_sku\_tier)

Description: (Required) SKU tier of the Firewall. Possible values are `Premium`, `Standard` and `Basic`.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: (Required) Specifies the name of the Firewall. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_public_ip_allocation_method"></a> [public\_ip\_allocation\_method](#input\_public\_ip\_allocation\_method)

Description: (Required) Defines the allocation method for this IP address. Possible values are `Static` or `Dynamic`.

Type: `string`

### <a name="input_public_ip_location"></a> [public\_ip\_location](#input\_public\_ip\_location)

Description: (Required) Specifies the supported Azure location where the Public IP should exist. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_public_ip_name"></a> [public\_ip\_name](#input\_public\_ip\_name)

Description: (Required) Specifies the name of the Public IP. Changing this forces a new Public IP to be created.

Type: `string`

### <a name="input_public_ip_resource_group_name"></a> [public\_ip\_resource\_group\_name](#input\_public\_ip\_resource\_group\_name)

Description: (Required) The name of the Resource Group where this Public IP should exist. Changing this forces a new Public IP to be created.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: (Required) The name of the resource group in which to create the resource. Changing this forces a new resource to be created.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description:   A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

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

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_firewall_dns_proxy_enabled"></a> [firewall\_dns\_proxy\_enabled](#input\_firewall\_dns\_proxy\_enabled)

Description: (Optional) Whether DNS proxy is enabled. It will forward DNS requests to the DNS servers when set to `true`. It will be set to `true` if `dns_servers` provided with a not empty list.

Type: `bool`

Default: `null`

### <a name="input_firewall_dns_servers"></a> [firewall\_dns\_servers](#input\_firewall\_dns\_servers)

Description: (Optional) A list of DNS servers that the Azure Firewall will direct DNS traffic to the for name resolution.

Type: `list(string)`

Default: `null`

### <a name="input_firewall_ip_configuration"></a> [firewall\_ip\_configuration](#input\_firewall\_ip\_configuration)

Description: - `name` - (Required) Specifies the name of the IP Configuration.
- `public_ip_address_id` - (Optional) The ID of the Public IP Address associated with the firewall.
- `subnet_id` - (Optional) Reference to the subnet associated with the IP Configuration. Changing this forces a new resource to be created.

Type:

```hcl
list(object({
    name                 = string
    public_ip_address_id = optional(string)
    subnet_id            = optional(string)
  }))
```

Default: `null`

### <a name="input_firewall_management_ip_configuration"></a> [firewall\_management\_ip\_configuration](#input\_firewall\_management\_ip\_configuration)

Description: - `name` - (Required) Specifies the name of the IP Configuration.
- `public_ip_address_id` - (Required) The ID of the Public IP Address associated with the firewall.
- `subnet_id` - (Required) Reference to the subnet associated with the IP Configuration. Changing this forces a new resource to be created.

Type:

```hcl
object({
    name                 = string
    public_ip_address_id = string
    subnet_id            = string
  })
```

Default: `null`

### <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id)

Description: (Optional) The ID of the Firewall Policy applied to this Firewall.

Type: `string`

Default: `null`

### <a name="input_firewall_private_ip_ranges"></a> [firewall\_private\_ip\_ranges](#input\_firewall\_private\_ip\_ranges)

Description: (Optional) A list of SNAT private CIDR IP ranges, or the special string `IANAPrivateRanges`, which indicates Azure Firewall does not SNAT when the destination IP address is a private range per IANA RFC 1918.

Type: `set(string)`

Default: `null`

### <a name="input_firewall_threat_intel_mode"></a> [firewall\_threat\_intel\_mode](#input\_firewall\_threat\_intel\_mode)

Description: (Optional) The operation mode for threat intelligence-based filtering. Possible values are: `Off`, `Alert` and `Deny`. Defaults to `Alert`.

Type: `string`

Default: `null`

### <a name="input_firewall_timeouts"></a> [firewall\_timeouts](#input\_firewall\_timeouts)

Description: - `create` - (Defaults to 90 minutes) Used when creating the Firewall.
- `delete` - (Defaults to 90 minutes) Used when deleting the Firewall.
- `read` - (Defaults to 5 minutes) Used when retrieving the Firewall.
- `update` - (Defaults to 90 minutes) Used when updating the Firewall.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `null`

### <a name="input_firewall_virtual_hub"></a> [firewall\_virtual\_hub](#input\_firewall\_virtual\_hub)

Description: - `public_ip_count` - (Optional) Specifies the number of public IPs to assign to the Firewall. Defaults to `1`.
- `virtual_hub_id` - (Required) Specifies the ID of the Virtual Hub where the Firewall resides in.

Type:

```hcl
object({
    public_ip_count = optional(number)
    virtual_hub_id  = string
  })
```

Default: `null`

### <a name="input_firewall_zones"></a> [firewall\_zones](#input\_firewall\_zones)

Description: (Optional) Specifies a list of Availability Zones in which this Azure Firewall should be located. Changing this forces a new Azure Firewall to be created.

Type: `set(string)`

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")

  })
```

Default: `{}`

### <a name="input_public_ip_ddos_protection_mode"></a> [public\_ip\_ddos\_protection\_mode](#input\_public\_ip\_ddos\_protection\_mode)

Description: (Optional) The DDoS protection mode of the public IP. Possible values are `Disabled`, `Enabled`, and `VirtualNetworkInherited`. Defaults to `VirtualNetworkInherited`.

Type: `string`

Default: `null`

### <a name="input_public_ip_ddos_protection_plan_id"></a> [public\_ip\_ddos\_protection\_plan\_id](#input\_public\_ip\_ddos\_protection\_plan\_id)

Description: (Optional) The ID of DDoS protection plan associated with the public IP.

Type: `string`

Default: `null`

### <a name="input_public_ip_domain_name_label"></a> [public\_ip\_domain\_name\_label](#input\_public\_ip\_domain\_name\_label)

Description: (Optional) Label for the Domain Name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system.

Type: `string`

Default: `null`

### <a name="input_public_ip_edge_zone"></a> [public\_ip\_edge\_zone](#input\_public\_ip\_edge\_zone)

Description: (Optional) Specifies the Edge Zone within the Azure Region where this Public IP should exist. Changing this forces a new Public IP to be created.

Type: `string`

Default: `null`

### <a name="input_public_ip_idle_timeout_in_minutes"></a> [public\_ip\_idle\_timeout\_in\_minutes](#input\_public\_ip\_idle\_timeout\_in\_minutes)

Description: (Optional) Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes.

Type: `number`

Default: `null`

### <a name="input_public_ip_ip_tags"></a> [public\_ip\_ip\_tags](#input\_public\_ip\_ip\_tags)

Description: (Optional) A mapping of IP tags to assign to the public IP. Changing this forces a new resource to be created.

Type: `map(string)`

Default: `null`

### <a name="input_public_ip_ip_version"></a> [public\_ip\_ip\_version](#input\_public\_ip\_ip\_version)

Description: (Optional) The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Defaults to `IPv4`.

Type: `string`

Default: `null`

### <a name="input_public_ip_public_ip_prefix_id"></a> [public\_ip\_public\_ip\_prefix\_id](#input\_public\_ip\_public\_ip\_prefix\_id)

Description: (Optional) If specified then public IP address allocated will be provided from the public IP prefix resource. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_public_ip_reverse_fqdn"></a> [public\_ip\_reverse\_fqdn](#input\_public\_ip\_reverse\_fqdn)

Description: (Optional) A fully qualified domain name that resolves to this public IP address. If the reverseFqdn is specified, then a PTR DNS record is created pointing from the IP address in the in-addr.arpa domain to the reverse FQDN.

Type: `string`

Default: `null`

### <a name="input_public_ip_sku"></a> [public\_ip\_sku](#input\_public\_ip\_sku)

Description: (Optional) The SKU of the Public IP. Accepted values are `Basic` and `Standard`. Defaults to `Basic`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_public_ip_sku_tier"></a> [public\_ip\_sku\_tier](#input\_public\_ip\_sku\_tier)

Description: (Optional) The SKU Tier that should be used for the Public IP. Possible values are `Regional` and `Global`. Defaults to `Regional`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_public_ip_tags"></a> [public\_ip\_tags](#input\_public\_ip\_tags)

Description: (Optional) A mapping of tags to assign to the resource.

Type: `map(string)`

Default: `null`

### <a name="input_public_ip_timeouts"></a> [public\_ip\_timeouts](#input\_public\_ip\_timeouts)

Description: - `create` - (Defaults to 30 minutes) Used when creating the Public IP.
- `delete` - (Defaults to 30 minutes) Used when deleting the Public IP.
- `read` - (Defaults to 5 minutes) Used when retrieving the Public IP.
- `update` - (Defaults to 30 minutes) Used when updating the Public IP.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `null`

### <a name="input_public_ip_zones"></a> [public\_ip\_zones](#input\_public\_ip\_zones)

Description: (Optional) A collection containing the availability zone to allocate the Public IP in. Changing this forces a new resource to be created.

Type: `set(string)`

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - The description of the role assignment.
  - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - The condition which will be used to scope the role assignment.
  - `condition_version` - The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) A mapping of tags to assign to the resource.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: The ID of the Azure Firewall.

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the Azure Firewall.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->