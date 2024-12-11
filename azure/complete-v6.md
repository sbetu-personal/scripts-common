Apologies for the confusion in the previous responses. Based on your clarified directory structure, I'll provide a comprehensive Terraform configuration that aligns with your requirements. This setup ensures modularity, flexibility, and scalability, allowing you to manage multiple environments (`dev` and `prod`) within a single repository while leveraging shared modules.

## **Directory Structure**

Your desired directory structure is as follows:

```
/terraform
├── .gitignore
├── .pre-commit-config.yaml
├── .tflint.hcl
├── azure-tf-modules
│   ├── terraform-azurerm-vnet
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── provider.tf
│   └── terraform-azurerm-subnet
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── provider.tf
└── terraform-azurerm-orca
    ├── orca
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    └── env 
        ├── README.md 
        ├── prod.tf 
        ├── dev.tfvars 
```

Let's break down each component and provide the necessary configuration files.

---

## **1. Root Configuration Files**

These files are located directly under the `/terraform` directory and are essential for version control, code quality, and linting.

### **a. `.gitignore`**

Specifies intentionally untracked files to ignore.

```gitignore
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
```

### **b. `.pre-commit-config.yaml`**

Configures pre-commit hooks to enforce code quality before commits.

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.71.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
```

**Explanation:**
- **`terraform_fmt`**: Formats Terraform files.
- **`terraform_validate`**: Validates the Terraform configuration.
- **`terraform_tflint`**: Lints Terraform code.
- **`terraform_docs`**: Generates documentation from Terraform modules.

### **c. `.tflint.hcl`**

Configures TFLint for linting Terraform code.

```hcl
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
  enabled = true
  name_pattern = "^[a-z_][a-z0-9_]*$"
}
```

**Explanation:**
- **`azure` plugin**: Enables Azure-specific linting rules.
- **`no-empty-values`**: Ensures no empty values are present.
- **`variable-naming`**: Enforces snake_case naming for variables.

---

## **2. Azure Terraform Modules**

Located under `/terraform/azure-tf-modules`, these modules encapsulate reusable Terraform code for managing Azure resources like Virtual Networks and Subnets.

### **a. `terraform-azurerm-vnet` Module**

This module manages Azure Virtual Networks (VNets), including Subnets, Network Security Groups (NSGs), Route Tables, and Peerings.

#### **i. `azure-tf-modules/terraform-azurerm-vnet/main.tf`**

```hcl
# azure-tf-modules/terraform-azurerm-vnet/main.tf

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

# Create Subnets
resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  # NSG Association
  network_security_group_id = each.value.nsg_name != null ? lookup({ for nsg in var.nsgs : nsg.name => azurerm_network_security_group.this[nsg.name].id }, each.value.nsg_name, null) : null

  # Route Table Association
  route_table_id = each.value.route_table_name != null ? lookup({ for rt in var.route_tables : rt.name => azurerm_route_table.this[rt.name].id }, each.value.route_table_name, null) : null

  # Delegations
  dynamic "delegation" {
    for_each = each.value.delegations != null ? each.value.delegations : []
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
    for_each = each.value.service_endpoints != null ? each.value.service_endpoints : []
    content {
      service = service_endpoints.value
    }
  }
}

# Create Network Security Groups (NSGs)
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

# Create Route Tables
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
```

#### **ii. `azure-tf-modules/terraform-azurerm-vnet/variables.tf`**

Defines input variables for the VNet module.

```hcl
# azure-tf-modules/terraform-azurerm-vnet/variables.tf

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
```

#### **iii. `azure-tf-modules/terraform-azurerm-vnet/outputs.tf`**

Exports relevant outputs from the VNet module.

```hcl
# azure-tf-modules/terraform-azurerm-vnet/outputs.tf

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "peerings" {
  description = "Map of VNet Peering IDs"
  value       = { for p in azurerm_virtual_network_peering.peerings : p.name => p.id }
}
```

#### **iv. `azure-tf-modules/terraform-azurerm-vnet/provider.tf`**

Defines the provider configuration for the VNet module. This file can be empty or contain provider-specific settings if needed. Since providers are managed at the root level with aliases, it's best to leave this empty to prevent conflicts.

```hcl
# azure-tf-modules/terraform-azurerm-vnet/provider.tf

# This file is intentionally left blank.
# Providers are configured at the root level with aliases.
```

### **b. `terraform-azurerm-subnet` Module**

This module manages Azure Subnets. Given that the VNet module already handles subnet creation, this separate subnet module can be used for advanced subnet configurations or standalone subnet management if needed.

#### **i. `azure-tf-modules/terraform-azurerm-subnet/main.tf`**

```hcl
# azure-tf-modules/terraform-azurerm-subnet/main.tf

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
```

#### **ii. `azure-tf-modules/terraform-azurerm-subnet/variables.tf`**

Defines input variables for the Subnet module.

```hcl
# azure-tf-modules/terraform-azurerm-subnet/variables.tf

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
```

#### **iii. `azure-tf-modules/terraform-azurerm-subnet/outputs.tf`**

Exports relevant outputs from the Subnet module.

```hcl
# azure-tf-modules/terraform-azurerm-subnet/outputs.tf

output "subnet_id" {
  description = "ID of the Subnet"
  value       = azurerm_subnet.this.id
}
```

#### **iv. `azure-tf-modules/terraform-azurerm-subnet/provider.tf`**

Defines the provider configuration for the Subnet module. Similar to the VNet module, this can be left empty.

```hcl
# azure-tf-modules/terraform-azurerm-subnet/provider.tf

# This file is intentionally left blank.
# Providers are configured at the root level with aliases.
```

---

## **3. Orca Terraform Configuration**

Located under `/terraform/terraform-azurerm-orca`, this directory contains the primary Terraform configurations for deploying the Orca infrastructure. It includes shared configurations (`orca/`) and environment-specific configurations (`env/`).

### **a. `terraform-azurerm-orca/orca/main.tf`**

This file orchestrates the use of shared modules (`vnet` and `subnet`) to deploy the Orca infrastructure.

```hcl
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

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables

  peerings = var.peerings
}

# If you have separate subnet module usage, you can include it here
# module "subnet" {
#   source               = "../../azure-tf-modules/terraform-azurerm-subnet"
#   name                 = "example-subnet"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = module.vnet.name
#   address_prefixes     = ["10.0.1.0/24"]
#   nsg_id               = azurerm_network_security_group.this.id
#   route_table_id       = azurerm_route_table.this.id
#   delegations          = []
#   service_endpoints    = []
# }
```

### **b. `terraform-azurerm-orca/orca/variables.tf`**

Defines variables used by the Orca configuration.

```hcl
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
```

### **c. `terraform-azurerm-orca/orca/terraform.tfvars`**

Provides default values for variables. Typically, this file can be overridden by environment-specific `tfvars` files.

```hcl
# terraform-azurerm-orca/orca/terraform.tfvars

# VNet Configuration
vnet_name          = "orca-vnet"
address_space      = ["10.0.0.0/16"]
location           = "eastus"
resource_group_name = "rg-orca"

dns_servers        = ["10.1.0.4", "10.1.0.5"]
enable_ddos_protection = false
enable_vm_protection   = false

# Subnets Configuration
subnets = [
  {
    name             = "orca-subnet"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "orca-nsg"
    route_table_name = "orca-route-table"
    delegations      = []
    service_endpoints = []
  },
  {
    name             = "collector-subnet"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "collector-nsg"
    route_table_name = "collector-route-table"
    delegations      = []
    service_endpoints = []
  }
]

# Network Security Groups (NSGs) Configuration
nsgs = [
  {
    name = "orca-nsg"
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
      },
      {
        name                       = "Allow-HTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Deny-All"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name = "collector-nsg"
    security_rules = [
      {
        name                       = "Allow-HTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Deny-All"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
]

# Route Tables Configuration
route_tables = [
  {
    name   = "orca-route-table"
    routes = [
      {
        name          = "Internet"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "Internet"
      }
    ]
  },
  {
    name   = "collector-route-table"
    routes = [
      {
        name          = "Internet"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "Internet"
      }
    ]
  }
]

# Peerings Configuration
peerings = [
  {
    name                        = "orca-to-hub-peering"
    remote_virtual_network_id   = data.azurerm_virtual_network.hub_vnet.id
    allow_forwarded_traffic     = true
    allow_virtual_network_access = true
    allow_gateway_transit       = false
    use_remote_gateways         = false
  }
]
```

**Note:** The `remote_virtual_network_id` in the peerings refers to a data source, which will be defined in the environment-specific configurations (`env/prod.tf` and `env/dev.tfvars`).

### **d. `terraform-azurerm-orca/orca/backend.tf`**

Configures the Terraform backend for state management. Typically, this is overridden by environment-specific backend configurations, but including it here provides a default.

```hcl
# terraform-azurerm-orca/orca/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"            # Replace with your state Resource Group
    storage_account_name = "tfstatestoragedev"    # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "orca.terraform.tfstate"
  }
}
```

---

### **e. `terraform-azurerm-orca/orca/variables.tf`**

Defines variables used by the Orca configuration.

```hcl
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
```

### **f. `terraform-azurerm-orca/orca/terraform.tfvars`**

Provides default variable values. Environment-specific values will override these as needed.

```hcl
# terraform-azurerm-orca/orca/terraform.tfvars

# VNet Configuration
vnet_name          = "orca-vnet"
address_space      = ["10.0.0.0/16"]
location           = "eastus"
resource_group_name = "rg-orca"

dns_servers        = ["10.1.0.4", "10.1.0.5"]
enable_ddos_protection = false
enable_vm_protection   = false

# Subnets Configuration
subnets = [
  {
    name             = "orca-subnet"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "orca-nsg"
    route_table_name = "orca-route-table"
    delegations      = []
    service_endpoints = []
  },
  {
    name             = "collector-subnet"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "collector-nsg"
    route_table_name = "collector-route-table"
    delegations      = []
    service_endpoints = []
  }
]

# Network Security Groups (NSGs) Configuration
nsgs = [
  {
    name = "orca-nsg"
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
      },
      {
        name                       = "Allow-HTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Deny-All"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name = "collector-nsg"
    security_rules = [
      {
        name                       = "Allow-HTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Deny-All"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
]

# Route Tables Configuration
route_tables = [
  {
    name   = "orca-route-table"
    routes = [
      {
        name          = "Internet"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "Internet"
      }
    ]
  },
  {
    name   = "collector-route-table"
    routes = [
      {
        name          = "Internet"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "Internet"
      }
    ]
  }
]

# Peerings Configuration
peerings = [
  {
    name                        = "orca-to-hub-peering"
    remote_virtual_network_id   = data.azurerm_virtual_network.hub_vnet.id
    allow_forwarded_traffic     = true
    allow_virtual_network_access = true
    allow_gateway_transit       = false
    use_remote_gateways         = false
  }
]
```

### **g. `terraform-azurerm-orca/orca/backend.tf`**

Configures the Terraform backend for state management. This can be customized per environment or kept generic.

```hcl
# terraform-azurerm-orca/orca/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"            # Replace with your state Resource Group
    storage_account_name = "tfstatestoragedev"    # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "orca.terraform.tfstate"
  }
}
```

---

## **4. Environment-Specific Configurations**

Located under `/terraform/terraform-azurerm-orca/env`, these configurations handle environment-specific settings such as Development (`dev.tfvars`) and Production (`prod.tf`).

### **a. Directory Structure**

```
/terraform/terraform-azurerm-orca/env
├── README.md 
├── prod.tf 
├── dev.tfvars 
```

### **b. `env/README.md`**

Provides instructions for managing environments.

```markdown
# Orca Environments

This directory contains environment-specific Terraform configurations for deploying the Orca infrastructure.

## Environments

- **Development (`dev`)**
- **Production (`prod`)**

## Structure

- **`prod.tf`**: Terraform configuration for the Production environment.
- **`dev.tfvars`**: Variable definitions for the Development environment.

## Usage

### **Development Environment**

1. **Navigate to the Orca Directory**

   ```bash
   cd terraform/terraform-azurerm-orca/orca
   ```

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Plan the Deployment**

   ```bash
   terraform plan -var-file="../env/dev.tfvars"
   ```

4. **Apply the Configuration**

   ```bash
   terraform apply -var-file="../env/dev.tfvars"
   ```

### **Production Environment**

1. **Navigate to the Orca Directory**

   ```bash
   cd terraform/terraform-azurerm-orca/orca
   ```

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Plan the Deployment**

   ```bash
   terraform plan -var-file="../env/prod.tfvars"
   ```

4. **Apply the Configuration**

   ```bash
   terraform apply -var-file="../env/prod.tfvars"
   ```

## Notes

- **State Management:** Ensure that each environment has its own state file to prevent conflicts.
- **Peerings:** Only peerings defined within the `peerings` list in `tfvars` are managed by Terraform. Manually added peerings will remain untouched.
- **Adding New Environments:** To add a new environment, create a new `*.tfvars` file with appropriate variable values and update Terraform configurations as needed.
```

### **c. `env/prod.tf`**

Configures the Production environment by referencing the shared Orca module and providing production-specific settings.

```hcl
# terraform-azurerm-orca/env/prod.tf

module "orca" {
  source              = "../orca"
  vnet_name           = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_servers              = var.dns_servers
  enable_ddos_protection   = var.enable_ddos_protection
  enable_vm_protection     = var.enable_vm_protection

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables

  peerings = var.peerings
}
```

**Explanation:**
- **`source`**: Points to the shared Orca module located at `../orca`.
- **Variables**: Values are supplied via the Production `tfvars` file (`prod.tfvars`), which should be defined separately.

### **d. `env/dev.tfvars`**

Provides variable values specific to the Development environment.

```hcl
# terraform-azurerm-orca/env/dev.tfvars

# Orca VNet Configuration
vnet_name          = "orca-vnet-dev"
address_space      = ["10.0.0.0/16"]
location           = "eastus"
resource_group_name = "rg-orca-dev"

dns_servers        = ["10.1.0.4", "10.1.0.5"]
enable_ddos_protection = false
enable_vm_protection   = false

# Subnets Configuration
subnets = [
  {
    name             = "orca-subnet"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "orca-nsg-dev"
    route_table_name = "orca-route-table-dev"
    delegations      = []
    service_endpoints = []
  },
  {
    name             = "collector-subnet"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "collector-nsg-dev"
    route_table_name = "collector-route-table-dev"
    delegations      = []
    service_endpoints = []
  }
]

# Network Security Groups (NSGs) Configuration
nsgs = [
  {
    name = "orca-nsg-dev"
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
      },
      {
        name                       = "Allow-HTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Deny-All"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name = "collector-nsg-dev"
    security_rules = [
      {
        name                       = "Allow-HTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Deny-All"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
]

# Route Tables Configuration
route_tables = [
  {
    name   = "orca-route-table-dev"
    routes = [
      {
        name          = "Internet"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "Internet"
      }
    ]
  },
  {
    name   = "collector-route-table-dev"
    routes = [
      {
        name          = "Internet"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "Internet"
      }
    ]
  }
]

# Peerings Configuration
peerings = [
  {
    name                        = "orca-to-hub-peering"
    remote_virtual_network_id   = "/subscriptions/YOUR_HUB_SUBSCRIPTION_ID/resourceGroups/YOUR_HUB_RG/providers/Microsoft.Network/virtualNetworks/hub-vnet"
    allow_forwarded_traffic     = true
    allow_virtual_network_access = true
    allow_gateway_transit       = false
    use_remote_gateways         = false
  }
]
```

**Note:** Replace `YOUR_HUB_SUBSCRIPTION_ID` and `YOUR_HUB_RG` with your actual Hub subscription ID and resource group name.

---

## **5. Execution Instructions**

### **a. Initialize Terraform**

Navigate to the Orca configuration directory and initialize Terraform. This command sets up the backend and downloads necessary providers.

```bash
cd terraform/terraform-azurerm-orca/orca
terraform init
```

### **b. Validate the Configuration**

Ensure that your Terraform files are syntactically correct and logically consistent.

```bash
terraform validate -var-file="../env/dev.tfvars"  # For Development
terraform validate -var-file="../env/prod.tfvars" # For Production
```

### **c. Plan the Deployment**

Preview the changes Terraform will make to your Azure environment.

```bash
terraform plan -var-file="../env/dev.tfvars"  # For Development
terraform plan -var-file="../env/prod.tfvars" # For Production
```

### **d. Apply the Configuration**

Deploy the infrastructure to Azure.

```bash
terraform apply -var-file="../env/dev.tfvars"  # For Development
terraform apply -var-file="../env/prod.tfvars" # For Production
```

- **Review:** Terraform will display the proposed changes.
- **Confirm:** Type `yes` to proceed.

### **e. Verify the Deployment**

After applying, verify that the resources are created as expected via the Azure Portal or Azure CLI.

---

## **6. Ensuring Flexibility and Safety**

### **a. Managing Peerings**

- **Terraform-Managed Peerings:** Only peerings defined in the `peerings` list within `tfvars` are managed by Terraform. Terraform will create, update, or delete these peerings based on your configurations.

- **Manually Added Peerings:** Any peerings added **manually** outside of Terraform will **not** be managed or deleted by Terraform, ensuring they remain untouched. Terraform's state only tracks resources it manages, so manual peerings are ignored.

**Example Scenario:**

1. **Initial Deployment:**
   - Deploy the VNet without any peerings by keeping the `peerings` list empty or specifying desired peerings.
   
2. **Manual Peering Addition:**
   - Later, manually add a peering to the VNet via the Azure Portal or Azure CLI.

3. **Terraform Re-Apply:**
   - Running `terraform apply` will **not** affect the manually added peering since it's not part of the Terraform configuration or state.

### **b. Adding New Peerings via Terraform**

To add new peerings, especially to subscriptions **not managed** by Terraform:

1. **Retrieve Remote VNet ID:**
   - Obtain the resource ID of the remote VNet you wish to peer with. This can be done via the Azure Portal or Azure CLI.

2. **Update `tfvars` File:**
   - Add a new peering object to the `peerings` list in your environment-specific `tfvars` file (`dev.tfvars` or `prod.tfvars`).

   ```hcl
   peerings = [
     {
       name                        = "orca-to-hub-peering"
       remote_virtual_network_id   = "/subscriptions/YOUR_HUB_SUBSCRIPTION_ID/resourceGroups/YOUR_HUB_RG/providers/Microsoft.Network/virtualNetworks/hub-vnet"
       allow_forwarded_traffic     = true
       allow_virtual_network_access = true
       allow_gateway_transit       = false
       use_remote_gateways         = false
     },
     {
       name                        = "orca-to-another-vnet-peering"
       remote_virtual_network_id   = "/subscriptions/ANOTHER_SUBSCRIPTION_ID/resourceGroups/ANOTHER_RG/providers/Microsoft.Network/virtualNetworks/another-vnet"
       allow_forwarded_traffic     = true
       allow_virtual_network_access = true
       allow_gateway_transit       = false
       use_remote_gateways         = false
     }
   ]
   ```

3. **Apply the Changes:**
   - Run `terraform plan` and `terraform apply` to establish the new peering.

   ```bash
   terraform plan -var-file="../env/dev.tfvars"
   terraform apply -var-file="../env/dev.tfvars"
   ```

**Note:** Ensure that the Terraform execution context has the necessary permissions in both the source and remote subscriptions to establish peerings.

---

## **7. Complete Code Snippets**

Below are the complete code snippets for each file based on the directory structure you provided.

### **a. Root Files**

#### **i. `.gitignore`**

```gitignore
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
```

#### **ii. `.pre-commit-config.yaml`**

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.71.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
```

#### **iii. `.tflint.hcl`**

```hcl
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
```

### **b. `azure-tf-modules/terraform-azurerm-vnet` Module**

#### **i. `main.tf`**

*(As provided above.)*

#### **ii. `variables.tf`**

*(As provided above.)*

#### **iii. `outputs.tf`**

*(As provided above.)*

#### **iv. `provider.tf`**

```hcl
# azure-tf-modules/terraform-azurerm-vnet/provider.tf

# This file is intentionally left blank.
# Providers are configured at the root level with aliases.
```

### **c. `azure-tf-modules/terraform-azurerm-subnet` Module**

#### **i. `main.tf`**

*(As provided above.)*

#### **ii. `variables.tf`**

*(As provided above.)*

#### **iii. `outputs.tf`**

*(As provided above.)*

#### **iv. `provider.tf`**

```hcl
# azure-tf-modules/terraform-azurerm-subnet/provider.tf

# This file is intentionally left blank.
# Providers are configured at the root level with aliases.
```

### **d. `terraform-azurerm-orca/orca` Configuration**

#### **i. `main.tf`**

*(As provided above.)*

#### **ii. `variables.tf`**

*(As provided above.)*

#### **iii. `terraform.tfvars`**

*(As provided above.)*

#### **iv. `backend.tf`**

*(As provided above.)*

### **e. `terraform-azurerm-orca/env` Configuration**

#### **i. `README.md`**

*(As provided above.)*

#### **ii. `prod.tf`**

*(As provided above.)*

#### **iii. `dev.tfvars`**

*(As provided above.)*

---

## **8. Additional Best Practices**

### **a. State Management**

- **Remote State Storage:** Ensure that your Terraform state is stored remotely (e.g., Azure Blob Storage) to enable team collaboration and prevent state conflicts.
- **State Isolation:** Use separate state files for different environments (`dev` and `prod`) to maintain isolation.

### **b. Security**

- **Sensitive Variables:** Mark sensitive variables as `sensitive = true` in `variables.tf` to prevent them from being displayed in logs.

  ```hcl
  variable "subscription_id_dev" {
    description = "Development Subscription ID"
    type        = string
    sensitive   = true
  }

  variable "subscription_id_hub" {
    description = "Hub Subscription ID"
    type        = string
    sensitive   = true
  }
  ```

- **Access Control:** Ensure that only authorized personnel have access to the Terraform state files and sensitive variables.

### **c. Documentation**

- **Module Documentation:** Each module should have a `README.md` detailing its purpose, inputs, outputs, and usage examples.
- **Environment Documentation:** The `env/README.md` should provide clear instructions on how to manage each environment.

### **d. Automation**

- **CI/CD Pipelines:** Integrate Terraform with CI/CD pipelines to automate deployments, run tests, and enforce code quality.
- **Pre-Commit Hooks:** Utilize the configured pre-commit hooks to enforce formatting and linting before code is committed.

### **e. Version Control**

- **Module Versioning:** Tag your modules with semantic versioning to manage updates and dependencies effectively.
- **Branching Strategy:** Adopt a branching strategy (e.g., Gitflow) to manage feature development, testing, and production releases.

---

## **9. Testing the Configuration**

To ensure that Terraform does not interfere with manually added peerings, follow these steps:

### **a. Initial Deployment Without Peerings**

1. **Configure `dev.tfvars` without Peerings:**

   ```hcl
   peerings = []
   ```

2. **Deploy the Infrastructure:**

   ```bash
   cd terraform/terraform-azurerm-orca/orca
   terraform init
   terraform apply -var-file="../env/dev.tfvars"
   ```

3. **Verify Deployment:**
   - Ensure that the VNet and subnets are created without any peerings.

### **b. Manually Add a Peering**

1. **Add Peering via Azure CLI:**

   ```bash
   az network vnet peering create \
     --name "manual-peering" \
     --resource-group "rg-orca-dev" \
     --vnet-name "orca-vnet-dev" \
     --remote-vnet "/subscriptions/REMOTE_SUBSCRIPTION_ID/resourceGroups/REMOTE_RG/providers/Microsoft.Network/virtualNetworks/remote-vnet" \
     --allow-vnet-access \
     --allow-forwarded-traffic
   ```

2. **Verify Peering:**
   - Check in the Azure Portal or via Azure CLI that the manual peering exists.

### **c. Re-Run Terraform Apply**

1. **Run Terraform Apply Again:**

   ```bash
   terraform apply -var-file="../env/dev.tfvars"
   ```

2. **Expected Outcome:**
   - Terraform will **not** detect or attempt to modify the manually added peering since it's **not** part of the Terraform configuration or state.

### **d. Confirm Peerings**

- **Terraform State:** Ensure that only peerings defined in `tfvars` are managed.
- **Manual Peerings:** Confirm that manually added peerings remain intact and are **not** altered by Terraform.

---

## **10. Final Thoughts**

By adhering to the structured approach outlined above, you achieve a Terraform configuration that is:

- **Modular:** Reusable modules encapsulate common infrastructure components.
- **Flexible:** Environment-specific configurations allow for tailored deployments without duplicating code.
- **Safe:** Manual interventions (like adding peerings) remain unaffected by Terraform, preventing accidental deletions or modifications.
- **Scalable:** Easily add new environments or extend existing configurations as your infrastructure grows.

This setup aligns with Terraform best practices, promoting maintainability, scalability, and security in your infrastructure management.

**Feel free to reach out if you have further questions or need additional assistance! Happy Terraforming! 🚀**
