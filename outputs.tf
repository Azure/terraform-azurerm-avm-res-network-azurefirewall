output "resource" {
  value       = azurerm_firewall.this
  description = <<-EOT
  "The Resource of the Azure Firewall. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  Examples:
  - module.firewall.resource.id
  - module.firewall.resource.name
  - module.firewall.resource.ip_configuration
  - module.firewall.resource.virtual_hub
  EOT
}
