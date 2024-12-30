# terraform-azurerm-nsg

This module creates an Azure Network Security Group (NSG) with customizable rules.

## Inputs

- `name` (string): Name of the NSG.
- `location` (string): Azure location.
- `resource_group_name` (string): Resource group name.
- `security_rules` (list(object)): List of security rules.

## Outputs

- `nsg_id`: The ID of the NSG.
- `nsg_name`: The name of the NSG.
