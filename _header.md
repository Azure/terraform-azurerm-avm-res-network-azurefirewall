# terraform-azurerm-avm-res-network-firewall

Module to deploy Azure Firewall

## Upgrading from 0.4.x or earlier

The Firewall, its lock, role assignments and diagnostic settings are now AzAPI resources, and the module no longer uses the AzureRM provider. `moved` blocks carry them to their new addresses in the state, so nothing is recreated. No input changes are needed, but Terraform 1.11 or later is required.

1. A `ReadOnly` lock blocks the upgrade, because the Firewall, its role assignments and diagnostic settings are updated. Change it to `CanNotDelete`, or remove it, until the upgrade is applied.
1. Cross-tenant role assignments, which set `delegated_managed_identity_resource_id`, need extra steps. The AzureRM provider stored their ID with a `|<tenant-id>` suffix that the `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module:

   ```pwsh
   terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
   ```

   ```hcl
   import {
     to = module.<module-name>.azapi_resource.role_assignments["<key>"]
     id = "<role assignment resource ID, without the |<tenant-id> suffix>"
   }
   ```

1. Run `terraform init -upgrade`, then `terraform plan`. The plan must not destroy or replace anything. It updates the Firewall, lock, role assignments and diagnostic settings in place with the same settings, and adds:
   - a `random_uuid` for each role assignment, which only exists in the state. The assignments keep their names;
   - `time_sleep.lock_removal`, when a lock is set;
   - the AVM telemetry resources, when telemetry is enabled. The previous telemetry resources are removed from the state without being destroyed.

   The private and public IP addresses of the Firewall are read again during the apply, so values derived from them, for example routes that use the Firewall as their next hop, show as known after apply. They keep the same values.

   Role assignment descriptions were not sent by earlier versions. A description you set is added to the existing assignment in place. When `firewall_private_ip_ranges` lists more than one range, the update of the Firewall may also send them in a different order; they are the same ranges.
1. Apply the plan. The Firewall is updated with the same settings, which takes a few minutes. Classic rule collections and the threat intelligence mode are read from Azure and sent back unchanged. Later plans report no changes, except that, when telemetry is enabled, each plan updates the AVM telemetry deployment to record the apply.

Other changes:

- Adding, removing or reordering IP configurations, for example to add a public IP, now updates the Firewall in place instead of replacing it. Changing the subnet, the zones, the SKU name or the management IP configuration still replaces it.
- `parent_id` can be set instead of `resource_group_name`.
- `resource_types`, `retry`, `timeouts` and `ignore_body_changes` cover the Firewall, its lock, role assignments and diagnostic settings. For the Firewall, `firewall_timeouts` takes precedence and keeps its defaults.
- `lock` accepts `notes`, and `role_assignments` accepts `name`.
- New outputs `name` and `private_ip_address`. The `resource` output keeps the attribute names of the `azurerm_firewall` resource.
- Role names are matched, ignoring case, against the role definitions that can be assigned in the resource group, and an unknown name fails during plan.
- The public IP count of a Firewall in a Virtual Hub can still be increased in place. It cannot be reduced in place, because Azure then requires the public IPs to retain; remove public IPs outside Terraform first, then set the new count. The AzureRM provider silently kept the most recently added addresses.

> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>