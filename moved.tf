# The firewall, lock, role assignments and diagnostic settings moved from the AzureRM provider to AzAPI.
# They are adopted in place and updated with the same settings.
moved {
  from = azurerm_firewall.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}
