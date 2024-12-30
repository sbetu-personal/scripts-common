#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Script: setup_terraform_repo.sh
# Description: Creates a Terraform repository structure with standard best-practice files.
# Author: Your Name
# Usage:
#   1) chmod +x setup_terraform_repo.sh
#   2) ./setup_terraform_repo.sh
# ------------------------------------------------------------------------------

# Define the top-level directory
REPO_ROOT="terraform-repo"

echo "Creating main repository directory: ${REPO_ROOT}"
mkdir -p "${REPO_ROOT}"

# ------------------------------------------------------------------------------
# 1. Create .gitignore
# ------------------------------------------------------------------------------
cat <<EOF > "${REPO_ROOT}/.gitignore"
# Terraform state
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Sensitive variable files
*.tfvars
*.tfvars.json

# Logs
*.log
crash.log

# Terraform config
.terraformrc
terraform.rc
EOF
echo "Created .gitignore."

# ------------------------------------------------------------------------------
# 2. Create .pre-commit-config.yaml
# ------------------------------------------------------------------------------
cat <<EOF > "${REPO_ROOT}/.pre-commit-config.yaml"
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.71.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
EOF
echo "Created .pre-commit-config.yaml."

# ------------------------------------------------------------------------------
# 3. Create .tflint.hcl
# ------------------------------------------------------------------------------
cat <<EOF > "${REPO_ROOT}/.tflint.hcl"
plugin "azure" {
  enabled = true
}

rule "no-empty-values" {
  enabled = true
}

rule "variable-naming" {
  enabled      = true
  name_pattern = "^[a-z_][a-z0-9_]*\$"
}
EOF
echo "Created .tflint.hcl."

# ------------------------------------------------------------------------------
# 4. Create optional .terraform-version (for tfenv users)
# ------------------------------------------------------------------------------
cat <<EOF > "${REPO_ROOT}/.terraform-version"
1.5.7
EOF
echo "Created .terraform-version (optional, for tfenv)."

# ------------------------------------------------------------------------------
# 5. Create main README.md
# ------------------------------------------------------------------------------
cat <<EOF > "${REPO_ROOT}/README.md"
# Terraform Repository

This repository houses Terraform configurations, modules, and environment files for Azure resources.

## Structure

- \`azure-tf-modules/\`: Houses reusable Terraform modules for Azure.
- \`terraform-azurerm-orca/\`: Contains a working Terraform configuration that utilizes the modules.
- \`.gitignore\`, \`.pre-commit-config.yaml\`, \`.tflint.hcl\`: Various configuration files for Terraform best practices (ignore, linting, pre-commit hooks, etc.).

## Usage

1. Clone the repo.
2. (Optional) Install \`tfenv\` and switch to the matching Terraform version in \`.terraform-version\`.
3. Install [Pre-Commit](https://pre-commit.com/) and run \`pre-commit install\`.
4. Initialize, plan, and apply with your environment of choice, for example:
   \`\`\`
   cd terraform-azurerm-orca/orca
   terraform init
   terraform plan -var-file="../env/dev.tfvars"
   terraform apply -var-file="../env/dev.tfvars"
   \`\`\`

## Contributing

- Ensure all changes pass \`terraform fmt\`, \`terraform validate\`, and \`tflint\`.
- Document new modules thoroughly in a \`README.md\` within the module folder.
EOF
echo "Created README.md at repo root."

# ------------------------------------------------------------------------------
# 6. Create azure-tf-modules structure
# ------------------------------------------------------------------------------
MODULES_DIR="${REPO_ROOT}/azure-tf-modules"
mkdir -p "${MODULES_DIR}"
echo "Created modules directory: ${MODULES_DIR}"

# 6A. VNet Module
VNET_DIR="${MODULES_DIR}/terraform-azurerm-vnet"
mkdir -p "${VNET_DIR}"
cat <<EOF > "${VNET_DIR}/main.tf"
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
EOF

cat <<EOF > "${VNET_DIR}/variables.tf"
variable "name" {
  type        = string
  description = "Name of the virtual network."
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network."
}

variable "location" {
  type        = string
  description = "Azure location for the virtual network."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for the virtual network."
}

variable "dns_servers" {
  type        = list(string)
  description = "List of DNS servers for the virtual network."
  default     = []
}
EOF

cat <<EOF > "${VNET_DIR}/outputs.tf"
output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "The ID of the virtual network."
}

output "vnet_name" {
  value       = azurerm_virtual_network.this.name
  description = "The name of the virtual network."
}
EOF

cat <<EOF > "${VNET_DIR}/provider.tf"
// Typically empty if inheriting providers from the root
EOF

cat <<EOF > "${VNET_DIR}/README.md"
# terraform-azurerm-vnet

This module creates an Azure Virtual Network with optional DNS servers.

## Inputs

- \`name\` (string): Name of the virtual network.
- \`address_space\` (list(string)): Address space for the virtual network.
- \`location\` (string): Azure location.
- \`resource_group_name\` (string): Resource group name for the VNet.
- \`dns_servers\` (list(string)): DNS servers for the virtual network (default: []).

## Outputs

- \`vnet_id\`: The ID of the virtual network.
- \`vnet_name\`: The name of the virtual network.
EOF
echo "Created terraform-azurerm-vnet module."

# 6B. Subnet Module
SUBNET_DIR="${MODULES_DIR}/terraform-azurerm-subnet"
mkdir -p "${SUBNET_DIR}"
cat <<EOF > "${SUBNET_DIR}/main.tf"
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
EOF

cat <<EOF > "${SUBNET_DIR}/variables.tf"
variable "name" {
  type        = string
  description = "Name of the subnet."
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network the subnet belongs to."
}

variable "address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints to associate with the subnet."
  default     = []
}

variable "network_security_group_id" {
  type        = string
  description = "ID of the network security group to associate with the subnet."
  default     = null
}

variable "route_table_id" {
  type        = string
  description = "ID of the route table to associate with the subnet."
  default     = null
}
EOF

cat <<EOF > "${SUBNET_DIR}/outputs.tf"
output "subnet_id" {
  value       = azurerm_subnet.this.id
  description = "The ID of the subnet."
}

output "subnet_name" {
  value       = azurerm_subnet.this.name
  description = "The name of the subnet."
}
EOF

cat <<EOF > "${SUBNET_DIR}/provider.tf"
// Typically empty if inheriting providers from the root
EOF

cat <<EOF > "${SUBNET_DIR}/README.md"
# terraform-azurerm-subnet

This module creates a subnet within an existing Azure Virtual Network.

## Inputs

- \`name\` (string): Name of the subnet.
- \`virtual_network_name\` (string): Name of the parent VNet.
- \`address_prefixes\` (list(string)): Address prefixes for the subnet.
- \`resource_group_name\` (string): Resource group name.
- \`service_endpoints\` (list(string)): List of service endpoints (default: []).
- \`network_security_group_id\` (string): NSG ID (optional).
- \`route_table_id\` (string): Route table ID (optional).

## Outputs

- \`subnet_id\`: The ID of the subnet.
- \`subnet_name\`: The name of the subnet.
EOF
echo "Created terraform-azurerm-subnet module."

# 6C. NSG Module
NSG_DIR="${MODULES_DIR}/terraform-azurerm-nsg"
mkdir -p "${NSG_DIR}"
cat <<EOF > "${NSG_DIR}/main.tf"
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
EOF

cat <<EOF > "${NSG_DIR}/variables.tf"
variable "name" {
  type        = string
  description = "Name of the network security group."
}

variable "location" {
  type        = string
  description = "Azure location."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
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
  description = "List of security rules."
}
EOF

cat <<EOF > "${NSG_DIR}/outputs.tf"
output "nsg_id" {
  value       = azurerm_network_security_group.this.id
  description = "The ID of the network security group."
}

output "nsg_name" {
  value       = azurerm_network_security_group.this.name
  description = "The name of the network security group."
}
EOF

cat <<EOF > "${NSG_DIR}/provider.tf"
// Typically empty if inheriting providers from the root
EOF

cat <<EOF > "${NSG_DIR}/README.md"
# terraform-azurerm-nsg

This module creates an Azure Network Security Group (NSG) with customizable rules.

## Inputs

- \`name\` (string): Name of the NSG.
- \`location\` (string): Azure location.
- \`resource_group_name\` (string): Resource group name.
- \`security_rules\` (list(object)): List of security rules.

## Outputs

- \`nsg_id\`: The ID of the NSG.
- \`nsg_name\`: The name of the NSG.
EOF
echo "Created terraform-azurerm-nsg module."

# 6D. Route Table Module
ROUTE_TABLE_DIR="${MODULES_DIR}/terraform-azurerm-route-table"
mkdir -p "${ROUTE_TABLE_DIR}"
cat <<EOF > "${ROUTE_TABLE_DIR}/main.tf"
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
EOF

cat <<EOF > "${ROUTE_TABLE_DIR}/variables.tf"
variable "name" {
  type        = string
  description = "Name of the route table."
}

variable "location" {
  type        = string
  description = "Azure location."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "List of routes."
}
EOF

cat <<EOF > "${ROUTE_TABLE_DIR}/outputs.tf"
output "route_table_id" {
  value       = azurerm_route_table.this.id
  description = "The ID of the route table."
}

output "route_table_name" {
  value       = azurerm_route_table.this.name
  description = "The name of the route table."
}
EOF

cat <<EOF > "${ROUTE_TABLE_DIR}/provider.tf"
// Typically empty if inheriting providers from the root
EOF

cat <<EOF > "${ROUTE_TABLE_DIR}/README.md"
# terraform-azurerm-route-table

This module creates an Azure Route Table with user-defined routes.

## Inputs

- \`name\` (string): Name of the route table.
- \`location\` (string): Azure location.
- \`resource_group_name\` (string): Resource group name.
- \`routes\` (list(object)): List of route definitions.

## Outputs

- \`route_table_id\`: The ID of the route table.
- \`route_table_name\`: The name of the route table.
EOF
echo "Created terraform-azurerm-route-table module."

# ------------------------------------------------------------------------------
# 7. Create terraform-azurerm-orca structure
# ------------------------------------------------------------------------------
ORCA_DIR="${REPO_ROOT}/terraform-azurerm-orca/orca"
mkdir -p "${ORCA_DIR}"

# main.tf
cat <<EOF > "${ORCA_DIR}/main.tf"
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
EOF

# variables.tf
cat <<EOF > "${ORCA_DIR}/variables.tf"
variable "vnet_name" {
  type        = string
  description = "Name of the VNet."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space of the VNet."
}

variable "location" {
  type        = string
  description = "Azure location."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for the VNet."
  default     = []
}

variable "nsg_name" {
  type        = string
  description = "Name of the network security group."
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
  description = "Security rules for the network security group."
}

variable "route_table_name" {
  type        = string
  description = "Name of the route table."
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  description = "Routes for the route table."
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet."
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet."
}

variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints for the subnet."
  default     = []
}
EOF

# backend.tf
cat <<EOF > "${ORCA_DIR}/backend.tf"
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "orca.terraform.tfstate"
  }
}
EOF

# (Optional) provider.tf
cat <<EOF > "${ORCA_DIR}/provider.tf"
// You can pin provider versions here if desired:
// terraform {
//   required_providers {
//     azurerm = {
//       source  = "hashicorp/azurerm"
//       version = "~> 3.70"
//     }
//   }
// }
EOF

echo "Created terraform-azurerm-orca/orca configuration files."

# ------------------------------------------------------------------------------
# 8. Create environment folder under terraform-azurerm-orca
# ------------------------------------------------------------------------------
ENV_DIR="${REPO_ROOT}/terraform-azurerm-orca/env"
mkdir -p "${ENV_DIR}"
cat <<EOF > "${ENV_DIR}/README.md"
# Environment Configuration

This directory contains environment-specific configurations for dev, prod, etc.

Usage:
  \$ cd ../orca
  \$ terraform init
  \$ terraform plan -var-file="../env/dev.tfvars"
  \$ terraform apply -var-file="../env/dev.tfvars"
EOF

# prod.tfvars
cat <<EOF > "${ENV_DIR}/prod.tfvars"
vnet_name             = "prod-vnet"
vnet_address_space    = ["10.0.0.0/16"]
location             = "eastus"
resource_group_name   = "prod-resource-group"
dns_servers           = []
nsg_name              = "prod-nsg"

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

subnet_name             = "prod-subnet"
subnet_address_prefixes = ["10.0.1.0/24"]
service_endpoints       = ["Microsoft.Sql", "Microsoft.Storage"]
EOF

# dev.tfvars
cat <<EOF > "${ENV_DIR}/dev.tfvars"
vnet_name             = "dev-vnet"
vnet_address_space    = ["10.1.0.0/16"]
location             = "westus"
resource_group_name   = "dev-resource-group"
dns_servers           = ["8.8.8.8", "8.8.4.4"]
nsg_name              = "dev-nsg"

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

subnet_name             = "dev-subnet"
subnet_address_prefixes = ["10.1.1.0/24"]
service_endpoints       = []
EOF

echo "Created environment files (dev.tfvars, prod.tfvars)."

# ------------------------------------------------------------------------------
# Completion message
# ------------------------------------------------------------------------------
echo "Terraform repository structure created successfully in '${REPO_ROOT}'!"
echo "You can now navigate to '${REPO_ROOT}' to review or initialize your Terraform project."
