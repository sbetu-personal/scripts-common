###############################################################################
# Provider configuration (if needed)
###############################################################################
provider "azurerm" {
  features {}
}

###############################################################################
# Module Calls
###############################################################################
module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_servers         = var.dns_servers
}

module "nsg" {
  source              = "../../azure-tf-modules/terraform-azurerm-nsg"
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rules      = var.security_rules
}

module "route_table" {
  source              = "../../azure-tf-modules/terraform-azurerm-route-table"
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
  routes              = var.routes
}

module "subnet" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  name                 = var.subnet_name
  virtual_network_name = module.vnet.vnet_name
  address_prefixes     = var.subnet_address_prefixes
  resource_group_name  = var.resource_group_name
  service_endpoints    = var.service_endpoints
  network_security_group_id = module.nsg.nsg_id
  route_table_id            = module.route_table.route_table_id
}
