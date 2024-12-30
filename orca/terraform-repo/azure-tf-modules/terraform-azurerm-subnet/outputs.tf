output "subnet_id" {
  value       = azurerm_subnet.this.id
  description = "The ID of the subnet."
}

output "subnet_name" {
  value       = azurerm_subnet.this.name
  description = "The name of the subnet."
}
