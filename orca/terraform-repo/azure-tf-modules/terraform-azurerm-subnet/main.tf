resource "azurerm_subnet" "this" {
  name                 = var.name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.address_prefixes
  resource_group_name  = var.resource_group_name

  dynamic "service_endpoints" {
    for_each = var.service_endpoints != null ? var.service_endpoints : []
    content {
      service = service_endpoints.value
    }
  }

  network_security_group_id = var.network_security_group_id
  route_table_id            = var.route_table_id
}
