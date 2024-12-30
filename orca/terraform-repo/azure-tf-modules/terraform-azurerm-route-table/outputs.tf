output "route_table_id" {
  value       = azurerm_route_table.this.id
  description = "The ID of the route table."
}

output "route_table_name" {
  value       = azurerm_route_table.this.name
  description = "The name of the route table."
}
