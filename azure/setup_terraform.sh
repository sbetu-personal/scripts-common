#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define base directory
BASE_DIR="terraform"

# Create the base directory
mkdir -p "$BASE_DIR"

# Navigate to the base directory
cd "$BASE_DIR"

# Create top-level files
echo "Creating top-level files..."

# .gitignore
cat <<EOF > .gitignore
# Terraform files
*.tfstate
*.tfstate.*
.crash.log
*.tfvars
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore .terraform directory
.terraform/

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore editor backups and swap files
*~
*.swp
EOF

# .pre-commit-config.yaml
cat <<EOF > .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.71.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
EOF

# .tflint.hcl
cat <<EOF > .tflint.hcl
plugin "azure" {
  enabled = true
}

rule "azure-lint" {
  enabled = true
}

rule "no-empty-values" {
  enabled = true
}

rule "variable-naming" {
  enabled      = true
  name_pattern = "^[a-z_][a-z0-9_]*$"
}
EOF

# Create the modules directory
echo "Creating modules directory..."
mkdir -p azure-tf-modules/terraform-azurerm-vnet
mkdir -p azure-tf-modules/terraform-azurerm-subnet

# Create terraform-azurerm-vnet module files
echo "Creating terraform-azurerm-vnet module files..."

# azure-tf-modules/terraform-azurerm-vnet/main.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-vnet/main.tf
resource "azurerm_virtual_network" "this" {
  name                = var.name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "dns_servers" {
    for_each = var.dns_servers != null && length(var.dns_servers) > 0 ? [var.dns_servers] : []
    content {
      dns_servers = dns_servers.value
    }
  }

  dynamic "enable_ddos_protection" {
    for_each = var.enable_ddos_protection != null ? [var.enable_ddos_protection] : []
    content {
      enable_ddos_protection = enable_ddos_protection.value
    }
  }

  dynamic "enable_vm_protection" {
    for_each = var.enable_vm_protection != null ? [var.enable_vm_protection] : []
    content {
      enable_vm_protection = enable_vm_protection.value
    }
  }
}

# Create VNet Peerings
resource "azurerm_virtual_network_peering" "peerings" {
  for_each = { for p in var.peerings : p.name => p }

  name                      = each.value.name
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = each.value.remote_virtual_network_id

  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}
EOF

# azure-tf-modules/terraform-azurerm-vnet/variables.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-vnet/variables.tf
variable "name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "dns_servers" {
  description = "List of custom DNS servers for the Virtual Network"
  type        = list(string)
  default     = []
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection for the Virtual Network"
  type        = bool
  default     = false
}

variable "enable_vm_protection" {
  description = "Enable VM Protection for the Virtual Network"
  type        = bool
  default     = false
}

variable "peerings" {
  description = "List of VNet peering configurations"
  type = list(object({
    name                        = string
    remote_virtual_network_id   = string
    allow_forwarded_traffic     = bool
    allow_virtual_network_access = bool
    allow_gateway_transit       = bool
    use_remote_gateways         = bool
  }))
  default = []
}
EOF

# azure-tf-modules/terraform-azurerm-vnet/outputs.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-vnet/outputs.tf
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "peerings" {
  description = "Map of VNet Peering IDs"
  value       = { for p in azurerm_virtual_network_peering.peerings : p.name => p.id }
}
EOF

# azure-tf-modules/terraform-azurerm-vnet/provider.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-vnet/provider.tf
# This file is intentionally left blank.
# Providers are configured at the root level with aliases.
EOF

# Create terraform-azurerm-subnet module files
echo "Creating terraform-azurerm-subnet module files..."

# azure-tf-modules/terraform-azurerm-subnet/main.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-subnet/main.tf
resource "azurerm_subnet" "this" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.address_prefixes

  # NSG Association
  network_security_group_id = var.nsg_id

  # Route Table Association
  route_table_id = var.route_table_id

  # Delegations
  dynamic "delegation" {
    for_each = var.delegations != null ? var.delegations : []
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

  # Service Endpoints
  dynamic "service_endpoints" {
    for_each = var.service_endpoints != null ? var.service_endpoints : []
    content {
      service = service_endpoints.value
    }
  }
}
EOF

# azure-tf-modules/terraform-azurerm-subnet/variables.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-subnet/variables.tf
variable "name" {
  description = "Name of the Subnet"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_prefixes" {
  description = "Address prefixes for the Subnet"
  type        = list(string)
}

variable "nsg_id" {
  description = "ID of the Network Security Group to associate with the Subnet"
  type        = string
  default     = null
}

variable "route_table_id" {
  description = "ID of the Route Table to associate with the Subnet"
  type        = string
  default     = null
}

variable "delegations" {
  description = "List of delegations for the Subnet"
  type = list(object({
    name               = string
    service_delegation = object({
      name    = string
      actions = list(string)
    })
  }))
  default = []
}

variable "service_endpoints" {
  description = "List of service endpoints for the Subnet"
  type        = list(string)
  default     = []
}
EOF

# azure-tf-modules/terraform-azurerm-subnet/outputs.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-subnet/outputs.tf
output "subnet_id" {
  description = "ID of the Subnet"
  value       = azurerm_subnet.this.id
}
EOF

# azure-tf-modules/terraform-azurerm-subnet/provider.tf
cat <<EOF > azure-tf-modules/terraform-azurerm-subnet/provider.tf
# This file is intentionally left blank.
# Providers are configured at the root level with aliases.
EOF

# Create terraform-azurerm-orca directory structure
echo "Creating terraform-azurerm-orca directory structure..."
mkdir -p terraform-azurerm-orca/orca
mkdir -p terraform-azurerm-orca/env

# Create terraform-azurerm-orca/orca/main.tf
echo "Creating terraform-azurerm-orca/orca/main.tf..."
cat <<EOF > terraform-azurerm-orca/orca/main.tf
# terraform-azurerm-orca/orca/main.tf

module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_servers              = var.dns_servers
  enable_ddos_protection   = var.enable_ddos_protection
  enable_vm_protection     = var.enable_vm_protection

  peerings = var.peerings
}

module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  for_each             = { for subnet in var.subnets : subnet.name => subnet }
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = module.vnet.name
  address_prefixes     = each.value.address_prefixes
  nsg_id               = each.value.nsg_name != null ? azurerm_network_security_group.this[each.value.nsg_name].id : null
  route_table_id       = each.value.route_table_name != null ? azurerm_route_table.this[each.value.route_table_name].id : null
  delegations          = each.value.delegations
  service_endpoints    = each.value.service_endpoints
}

# Create Network Security Groups (NSGs) if any
resource "azurerm_network_security_group" "this" {
  for_each = { for nsg in var.nsgs : nsg.name => nsg }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.security_rules != null ? each.value.security_rules : []
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

# Create Route Tables if any
resource "azurerm_route_table" "this" {
  for_each = { for rt in var.route_tables : rt.name => rt }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = each.value.routes != null ? each.value.routes : []
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}
EOF

# Create terraform-azurerm-orca/orca/variables.tf
echo "Creating terraform-azurerm-orca/orca/variables.tf..."
cat <<EOF > terraform-azurerm-orca/orca/variables.tf
# terraform-azurerm-orca/orca/variables.tf

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "dns_servers" {
  description = "List of custom DNS servers for the Virtual Network"
  type        = list(string)
  default     = []
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection for the Virtual Network"
  type        = bool
  default     = false
}

variable "enable_vm_protection" {
  description = "Enable VM Protection for the Virtual Network"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnet configurations"
  type = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, null)
    route_table_name = optional(string, null)
    delegations      = optional(list(object({
      name               = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
    service_endpoints = optional(list(string), [])
  }))
  default = []
}

variable "nsgs" {
  description = "List of Network Security Groups configurations"
  type = list(object({
    name           = string
    security_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  default = []
}

variable "route_tables" {
  description = "List of Route Table configurations"
  type = list(object({
    name   = string
    routes = optional(list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string, null)
    })), [])
  }))
  default = []
}

variable "peerings" {
  description = "List of VNet peering configurations"
  type = list(object({
    name                        = string
    remote_virtual_network_id   = string
    allow_forwarded_traffic     = bool
    allow_virtual_network_access = bool
    allow_gateway_transit       = bool
    use_remote_gateways         = bool
  }))
  default = []
}
EOF

# Create terraform-azurerm-orca/orca/backend.tf
echo "Creating terraform-azurerm-orca/orca/backend.tf..."
cat <<EOF > terraform-azurerm-orca/orca/backend.tf
# terraform-azurerm-orca/orca/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"            # Replace with your state Resource Group
    storage_account_name = "tfstatestoragedev"    # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "orca.terraform.tfstate"
  }
}
EOF

# Create terraform-azurerm-orca/env directory files
echo "Creating env folder files..."

# terraform-azurerm-orca/env/README.md
cat <<EOF > terraform-azurerm-orca/env/README.md
# Orca Environments

This directory contains environment-specific Terraform configurations for deploying the Orca infrastructure.

## Environments

- **Development (`dev.tfvars`)**
- **Production (`prod.tfvars`)**

## Structure

- **`dev.tfvars`**: Variable definitions for the Development environment.
- **`prod.tfvars`**: Variable definitions for the Production environment.
- **`README.md`**: This file.

## Usage

### **Development Environment**

1. **Navigate to the Orca Directory**

   ```bash
   cd ../../orca
