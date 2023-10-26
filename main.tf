# TODO: insert resources here.
// Create Azure Firewall Resource
resource "azurerm_firewall" "azfw" {
  name                = var.firewall_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = var.firewall_sku_name
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.azfw_policy.id
  ip_configuration {
    name                 = var.firewall_ip_config_name
    subnet_id            = azurerm_subnet_subnet_azfw.id
    public_ip_address_id = azurerm_public_ip.pip_azfw.id
  }
}

// Creating Public IP for the Azure Firewall
resource "azurerm_public_ip" "pip_azfw" {
  for_each                = { for ip_configuration in azurerm_firewall.azurerm_firewall.azfw.ip_configuration : ip_configuration => ip_configuration.create_public_ip_address }
  name                    = coalesce(each.value.public_ip_address_name, "pip-${var.firewall_name}")
  resource_group_name     = var.resource_group_name
  location                = var.location
  allocation_method       = var.public_ip_address_config.allocation_method
  sku                     = var.public_ip_address_config.sku
  sku_tier                = var.public_ip_address_config.sku_tier
  zones                   = var.public_ip_address_config.zones
  ddos_protection_mode    = var.public_ip_address_config.ddos_protection_mode
  ip_tags                 = var.public_ip_address_config.ip_tags
  ddos_protection_plan_id = var.public_ip_address_config.ddos_protection_plan_resource_id
  domain_name_label       = var.public_ip_address_config.domain_name_label
  reverse_fqdn            = var.public_ip_address_config.reverse_fqdn
  idle_timeout_in_minutes = var.public_ip_address_config.idle_timeout_in_minutes
  tags                    = var.public_ip_address_config.tags
}

# Applying Management Lock to the Virtual Network if specified.
resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.firewall_name}")
  scope      = azurerm_virtual_network.vnet.id
  lock_level = var.lock.kind
}

# Assigning Roles to the Virtual Network based on the provided configurations.
resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_virtual_network.vnet.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}