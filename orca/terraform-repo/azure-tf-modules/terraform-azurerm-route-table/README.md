# terraform-azurerm-route-table

This module creates an Azure Route Table with user-defined routes.

## Inputs

- `name` (string): Name of the route table.
- `location` (string): Azure location.
- `resource_group_name` (string): Resource group name.
- `routes` (list(object)): List of route definitions.

## Outputs

- `route_table_id`: The ID of the route table.
- `route_table_name`: The name of the route table.
