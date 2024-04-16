# We pick a random region from this list.
locals {
  azure_regions = [
    "westeurope",
    "northeurope",
    "eastus",
    "eastus2",
    "westus3",
    "westus2",
    "southcentralus",
    "centralus",
    "eastasia",
    "southeastasia",
  ]
}
