<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-network-firewall

Module to deploy Azure Firewall

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

- [azurerm_firewall.azfw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_public_ip.pip_azfw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_firewall_ip_config_name"></a> [firewall\_ip\_config\_name](#input\_firewall\_ip\_config\_name)

Description: The name of the Azure Firewall IP Config.

Type: `string`

### <a name="input_firewall_name"></a> [firewall\_name](#input\_firewall\_name)

Description: The name of the Azure Firewall to be created.

Type: `string`

### <a name="input_firewall_sku_name"></a> [firewall\_sku\_name](#input\_firewall\_sku\_name)

Description: The name of the Azure Firewall SKU.

Type: `string`

### <a name="input_firewall_sku_tier"></a> [firewall\_sku\_tier](#input\_firewall\_sku\_tier)

Description: Firewall SKU.

Type: `string`

### <a name="input_public_ip_address_config"></a> [public\_ip\_address\_config](#input\_public\_ip\_address\_config)

Description:   
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
      resource_group_name              = azurerm_resource_group.rg.name
      location                        = azurerm_resource_group.rg.location
    }

```

Type:

```hcl
object({
    resource_group_name              = string
    location                         = string
    allocation_method                = string
    zones                            = optional(list(number), null)
    sku                              = optional(string)
    sku_tier                         = optional(string)
    ddos_protection_mode             = optional(string)
    ddos_protection_plan_resource_id = optional(string, null)
    domain_name_label                = optional(string, null)
    reverse_fqdn                     = optional(string, null)
    idle_timeout_in_minutes          = optional(number, null)
    ip_version                       = optional(string, "IPv4")
    ip_tags                          = optional(map(string), null)
    public_ip_prefix_resource_id     = optional(string, null)
    tags                             = optional(map(any), null)
  })
```

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id)

Description: The ID of the subnet where the Azure Firewall will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: n/a

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id)

Description: The ID of the Azure Firewall Policy to be associated with the Azure Firewall.

Type: `string`

Default: `null`

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure Region where the resources will be deployed.

Type: `string`

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

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: n/a

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, true)
    condition                              = optional(string, null)
    condition_version                      = optional(string, "2.0")
    delegated_managed_identity_resource_id = optional(string)
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to associate with your network and subnets.

Type: `map(any)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id)

Description: TODO: insert outputs here.

### <a name="output_firewall_name"></a> [firewall\_name](#output\_firewall\_name)

Description: n/a

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->