terraform-repo
├── .gitignore
├── .pre-commit-config.yaml
├── .tflint.hcl
├── README.md
├── azure-tf-modules
│   ├── terraform-azurerm-vnet
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── provider.tf
│   ├── terraform-azurerm-subnet
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── provider.tf
│   ├── terraform-azurerm-nsg
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── provider.tf
│   └── terraform-azurerm-route-table
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── provider.tf
└── terraform-azurerm-orca
    ├── orca
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── backend.tf
    └── env
        ├── README.md
        ├── prod.tfvars
        ├── dev.tfvars

# .gitignore
*.tfstate
*.tfstate.*
.terraform/
*.tfvars
*.tfvars.json
*.log
crash.log
.terraformrc
terraform.rc

# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.71.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs

# .tflint.hcl
plugin "azure" {
  enabled = true
}

rule "no-empty-values" {
  enabled = true
}

rule "variable-naming" {
  enabled      = true
  name_pattern = "^[a-z_][a-z0-9_]*$"
}

# azure-tf-modules/terraform-azurerm-vnet/main.tf
resource "azurerm_virtual_network" "this" {
  name                = var.name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "dns_servers" {
    for_each = var.dns_servers != null ? var.dns_servers : []
    content {
      dns_servers = dns_servers.value
    }
  }
}

# azure-tf-modules/terraform-azurerm-vnet/variables.tf
variable "name" {
  type        = string
  description = "Name of the virtual network"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "location" {
  type        = string
  description = "Azure location for the virtual network"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for the virtual network"
}

variable "dns_servers" {
  type        = list(string)
  description = "List of DNS servers for the virtual network"
  default     = []
}

# azure-tf-modules/terraform-azurerm-vnet/outputs.tf
output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "The ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.this.name
  description = "The name of the virtual network"
}

# azure-tf-modules/terraform-azurerm-vnet/provider.tf
# Empty provider configuration

# azure-tf-modules/terraform-azurerm-subnet/main.tf
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

# azure-tf-modules/terraform-azurerm-subnet/variables.tf
variable "name" {
  type        = string
  description = "Name of the subnet"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network the subnet belongs to"
}

variable "address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints to associate with the subnet"
  default     = []
}

variable "network_security_group_id" {
  type        = string
  description = "ID of the network security group to associate with the subnet"
  default     = null
}

variable "route_table_id" {
  type        = string
  description = "ID of the route table to associate with the subnet"
  default     = null
}

# azure-tf-modules/terraform-azurerm-subnet/outputs.tf
output "subnet_id" {
  value       = azurerm_subnet.this.id
  description = "The ID of the subnet"
}

output "subnet_name" {
  value       = azurerm_subnet.this.name
  description = "The name of the subnet"
}

# azure-tf-modules/terraform-azurerm-subnet/provider.tf
# Empty provider configuration

# azure-tf-modules/terraform-azurerm-nsg/main.tf
resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# azure-tf-modules/terraform-azurerm-nsg/variables.tf
variable "name" {
  type        = string
  description = "Name of the network security group"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "security_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "List of security rules"
}

# azure-tf-modules/terraform-azurerm-nsg/outputs.tf
output "nsg_id" {
  value       = azurerm_network_security_group.this.id
  description = "The ID of the network security group"
}

output "nsg_name" {
  value       = azurerm_network_security_group.this.name
  description = "The name of the network security group"
}

# azure-tf-modules/terraform-azurerm-nsg/provider.tf
# Empty provider configuration

# azure-tf-modules/terraform-azurerm-route-table/main.tf
resource "azurerm_route_table" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
}

# azure-tf-modules/terraform-azurerm-route-table/variables.tf
variable "name" {
  type        = string
  description = "Name of the route table"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "List of routes"
}

# azure-tf-modules/terraform-azurerm-route-table/outputs.tf
output "route_table_id" {
  value       = azurerm_route_table.this.id
  description = "The ID of the route table"
}

output "route_table_name" {
  value       = azurerm_route_table.this.name
  description = "The name of the route table"
}

# azure-tf-modules/terraform-azurerm-route-table/provider.tf
# Empty provider configuration

# terraform-azurerm-orca/orca/main.tf
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

# terraform-azurerm-orca/orca/variables.tf
variable "vnet_name" {
  type        = string
  description = "Name of the VNet"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space of the VNet"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for the VNet"
  default     = []
}

variable "nsg_name" {
  type        = string
  description = "Name of the network security group"
}

variable "security_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "Security rules for the network security group"
}

variable "route_table_name" {
  type        = string
  description = "Name of the route table"
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "Routes for the route table"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet"
}

variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints for the subnet"
  default     = []
}

# terraform-azurerm-orca/orca/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "orca.terraform.tfstate"
  }
}

# terraform-azurerm-orca/env/README.md
# Environment Configuration
This directory contains environment-specific configurations.

# terraform-azurerm-orca/env/prod.tfvars
vnet_name = "prod-vnet"
vnet_address_space = ["10.0.0.0/16"]
location = "eastus"
resource_group_name = "prod-resource-group"
dns_servers = []
nsg_name = "prod-nsg"
security_rules = [
  {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]
route_table_name = "prod-route-table"
routes = [
  {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
]
subnet_name = "prod-subnet"
subnet_address_prefixes = ["10.0.1.0/24"]
service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]

# terraform-azurerm-orca/env/dev.tfvars
vnet_name = "dev-vnet"
vnet_address_space = ["10.1.0.0/16"]
location = "westus"
resource_group_name = "dev-resource-group"
dns_servers = ["8.8.8.8", "8.8.4.4"]
nsg_name = "dev-nsg"
security_rules = [
  {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]
route_table_name = "dev-route-table"
routes = [
  {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
]
subnet_name = "dev-subnet"
subnet_address_prefixes = ["10.1.1.0/24"]
service_endpoints = []
