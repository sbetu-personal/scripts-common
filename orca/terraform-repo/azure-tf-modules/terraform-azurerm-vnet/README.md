# terraform-azurerm-vnet

This module creates an Azure Virtual Network with optional DNS servers.

## Inputs

- `name` (string): Name of the virtual network.
- `address_space` (list(string)): Address space for the virtual network.
- `location` (string): Azure location.
- `resource_group_name` (string): Resource group name for the VNet.
- `dns_servers` (list(string)): DNS servers for the virtual network (default: []).

## Outputs

- `vnet_id`: The ID of the virtual network.
- `vnet_name`: The name of the virtual network.
