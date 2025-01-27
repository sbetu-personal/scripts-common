I'll help you create a modular and dynamic Azure network infrastructure Terraform configuration. We'll structure it with reusable modules and follow best practices for enterprise-grade deployments.

Here's the directory structure we'll use:

```
modules/
├── vnet/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── subnet/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── nsg/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── route-table/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── vnet-peering/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
main.tf
variables.tf
outputs.tf
terraform.tfvars.example
```

Let's create each module:

1. **Virtual Network Module (modules/vnet)**:

```hcl
# modules/vnet/main.tf
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = merge(var.tags, { module = "vnet" })
}

# modules/vnet/variables.tf
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "address_space" {
  description = "List of virtual network address spaces"
  type        = list(string)
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

# modules/vnet/outputs.tf
output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}
```

2. **Subnet Module (modules/subnet)**:

```hcl
# modules/subnet/main.tf
resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", {}) != {} ? [1] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# modules/subnet/variables.tf
variable "subnets" {
  description = "Map of subnets with their properties"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name          = string
      service_name  = string
      actions       = list(string)
    }))
  }))
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

# modules/subnet/outputs.tf
output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnet : k => v.id }
}
```

3. **Network Security Group Module (modules/nsg)**:

```hcl
# modules/nsg/main.tf
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { module = "nsg" })

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", null)
      destination_port_range     = lookup(security_rule.value, "destination_port_range", null)
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", null)
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", null)
    }
  }
}

# modules/nsg/variables.tf
variable "nsg_name" {
  description = "Name of the network security group"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "security_rules" {
  description = "List of security rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string)
    destination_port_range     = optional(string)
    source_address_prefix      = optional(string)
    destination_address_prefix = optional(string)
  }))
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

# modules/nsg/outputs.tf
output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}
```

4. **Main Configuration (main.tf)**:

```hcl
provider "azurerm" {
  features {}
}

module "vnet" {
  source              = "./modules/vnet"
  vnet_name           = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags
}

module "subnet" {
  source              = "./modules/subnet"
  subnets             = var.subnets
  resource_group_name = var.resource_group_name
  vnet_name           = module.vnet.vnet_name
}

module "nsg" {
  source              = "./modules/nsg"
  nsg_name            = "${var.vnet_name}-default-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  security_rules      = var.nsg_rules
  tags                = var.tags
}
```

5. **Root Variables (variables.tf)**:

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "List of virtual network address spaces"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets with their properties"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name          = string
      service_name  = string
      actions       = list(string)
    }))
  }))
}

variable "nsg_rules" {
  description = "List of NSG security rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string)
    destination_port_range     = optional(string)
    source_address_prefix      = optional(string)
    destination_address_prefix = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
```

6. **Example Usage (terraform.tfvars.example)**:

```hcl
resource_group_name = "prod-network-rg"
location            = "eastus"
vnet_name           = "prod-vnet"
address_space       = ["10.0.0.0/16"]

subnets = {
  "web" = {
    address_prefixes = ["10.0.1.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  },
  "db" = {
    address_prefixes = ["10.0.2.0/24"]
    delegation = {
      name          = "db-delegation"
      service_name  = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions       = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

nsg_rules = [
  {
    name                       = "AllowHTTP"
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

tags = {
  Environment = "Production"
  Team        = "Network"
}
```

Key Features:

1. **Modular Design**: Each Azure resource is separated into its own module for maximum reusability
2. **Dynamic Configuration**:
   - Flexible subnet configuration with optional delegation and service endpoints
   - Customizable NSG rules with optional parameters
   - Tagging support across all resources
3. **Type Constraints**: Strict variable typing for better validation
4. **Scalability**: Easy to add new modules or extend existing ones
5. **Best Practices**:
   - Secure default configurations
   - Clear separation of concerns
   - Comprehensive output variables
   - Input validation through variable types

To use this configuration:

1. Create a `terraform.tfvars` file based on the example
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review the plan:
   ```bash
   terraform plan
   ```
4. Apply the configuration:
   ```bash
   terraform apply
   ```

You can extend this further by:

1. Adding Azure Firewall module
2. Implementing Virtual Network Peering
3. Adding Private DNS Zones
4. Implementing Network Watcher
5. Adding DDoS Protection Plan

Remember to:

1. Use remote state storage (Azure Storage Account)
2. Implement CI/CD pipeline for deployments
3. Add testing using Terratest
4. Implement policy compliance checks
5. Add monitoring and diagnostics configurations
