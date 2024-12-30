output "nsg_id" {
  value       = azurerm_network_security_group.this.id
  description = "The ID of the network security group."
}

output "nsg_name" {
  value       = azurerm_network_security_group.this.name
  description = "The name of the network security group."
}
