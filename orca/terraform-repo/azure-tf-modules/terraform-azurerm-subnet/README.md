# terraform-azurerm-subnet

This module creates a subnet within an existing Azure Virtual Network.

## Inputs

- `name` (string): Name of the subnet.
- `virtual_network_name` (string): Name of the parent VNet.
- `address_prefixes` (list(string)): Address prefixes for the subnet.
- `resource_group_name` (string): Resource group name.
- `service_endpoints` (list(string)): List of service endpoints (default: []).
- `network_security_group_id` (string): NSG ID (optional).
- `route_table_id` (string): Route table ID (optional).

## Outputs

- `subnet_id`: The ID of the subnet.
- `subnet_name`: The name of the subnet.
