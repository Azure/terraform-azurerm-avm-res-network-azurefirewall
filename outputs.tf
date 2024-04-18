output "resource" {
  value       = azurerm_firewall.this
  description = <<-EOT
  "This is the full output for the resource. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  Examples:
  - module.firewall.resource.id
  - module.firewall.resource.name
  - module.firewall.resource.ip_configuration
  - module.firewall.resource.virtual_hub
  EOT
}
