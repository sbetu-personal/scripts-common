Certainly! Let's enhance your **Virtual Network (VNet)** module in a similar fashion to your already enhanced **Subnet** module. This will ensure consistency, scalability, and maintainability across your Terraform configurations for the **Orca Project**.

Below, you'll find the complete updated code for the VNet module, along with the necessary updates to other parts of your Terraform configuration to integrate these enhancements seamlessly.

---

## **Enhanced VNet Module Compatible with Azurerm Provider 4.10.0**

### **Module Structure**

```
/azure-tf-modules/terraform-azurerm-vnet
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

### **Updated Code**

#### **1. `main.tf`**

This file defines the Azure Virtual Network (`azurerm_virtual_network`) with dynamic VNet peering configurations and other optional features such as DNS servers and DDoS protection.

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.10.0"
    }
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "this" {
  name                = var.name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "dns_servers" {
    for_each = var.dns_servers != null ? [var.dns_servers] : []
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
  for_each = var.peerings != null ? var.peerings : {}

  name                      = each.value.name
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = each.value.remote_vnet_id

  allow_forwarded_traffic     = each.value.allow_forwarded_traffic
  allow_gateway_transit       = each.value.allow_gateway_transit
  allow_virtual_network_access = each.value.allow_virtual_network_access
  use_remote_gateways         = each.value.use_remote_gateways
}

```

**Explanation of Enhancements:**

1. **Dynamic DNS Servers:**
   - Allows specifying custom DNS servers for the VNet.
   - If `dns_servers` variable is provided, it configures them; otherwise, it uses Azure's default DNS.

2. **DDoS Protection:**
   - Enables or disables Azure DDoS Protection for the VNet based on the `enable_ddos_protection` variable.

3. **VM Protection:**
   - Enables or disables VM protection (`enable_vm_protection`) for the VNet.

4. **Dynamic VNet Peerings:**
   - Supports multiple VNet peerings by accepting a map of peering configurations.
   - Each peering can be individually configured with properties like `allow_forwarded_traffic`, `allow_gateway_transit`, etc.

#### **2. `variables.tf`**

This file declares all the input variables required by the VNet module, including the new variables for DNS servers, DDoS protection, VM protection, and peerings.

```hcl
variable "name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "dns_servers" {
  description = "List of DNS servers for the Virtual Network"
  type        = list(string)
  default     = null
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection for the Virtual Network"
  type        = bool
  default     = null
}

variable "enable_vm_protection" {
  description = "Enable VM protection for the Virtual Network"
  type        = bool
  default     = null
}

variable "peerings" {
  description = "Map of VNet peering configurations"
  type = map(object({
    name                       = string
    remote_vnet_id             = string
    allow_forwarded_traffic    = bool
    allow_gateway_transit      = bool
    allow_virtual_network_access = bool
    use_remote_gateways        = bool
  }))
  default = {}
}

```

**Explanation of Enhancements:**

1. **`dns_servers`:**
   - Optional list of DNS servers for the VNet.
   - Defaults to `null` to use Azure's default DNS if not specified.

2. **`enable_ddos_protection`:**
   - Optional boolean to enable DDoS Protection.
   - Defaults to `null`, meaning it won't be set unless specified.

3. **`enable_vm_protection`:**
   - Optional boolean to enable VM protection.
   - Defaults to `null`, similar to DDoS protection.

4. **`peerings`:**
   - A map allowing multiple VNet peerings.
   - Each entry defines the peering's properties, enabling granular control.

#### **3. `outputs.tf`**

This file exports useful information about the created Virtual Network and its peerings.

```hcl
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "peerings" {
  description = "Map of VNet Peering IDs"
  value       = { for p in azurerm_virtual_network_peering.peerings : p.name => p.id }
}
```

**Explanation of Enhancements:**

1. **`vnet_id`:**
   - Provides the ID of the created Virtual Network.

2. **`peerings`:**
   - Exports a map of peering names to their respective IDs for easy reference in other modules or configurations.

#### **4. `README.md`**

It's good practice to update the `README.md` to reflect the new features and usage of the enhanced VNet module.

```markdown
# Terraform AzureRM VNet Module

## Overview

This Terraform module creates an Azure Virtual Network (VNet) with support for dynamic VNet peerings, custom DNS servers, DDoS Protection, and VM protection. It's designed to be reusable and configurable across different environments.

## Module Structure

```
/azure-tf-modules/terraform-azurerm-vnet
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

## Usage

### Example Configuration

```hcl
module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_servers             = var.dns_servers
  enable_ddos_protection  = var.enable_ddos_protection
  enable_vm_protection    = var.enable_vm_protection

  peerings = var.peerings
}
```

### Variables

| Variable                   | Description                                              | Type                                                                                                                                                               | Required | Default |
|----------------------------|----------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|
| `name`                     | Name of the Virtual Network                              | `string`                                                                                                                                                            | Yes      | -       |
| `address_space`            | Address space for the Virtual Network                    | `list(string)`                                                                                                                                                      | Yes      | -       |
| `location`                 | Azure location for the resources                        | `string`                                                                                                                                                            | Yes      | -       |
| `resource_group_name`      | Name of the Resource Group                               | `string`                                                                                                                                                            | Yes      | -       |
| `dns_servers`              | List of DNS servers for the Virtual Network              | `list(string)`                                                                                                                                                      | No       | `null`  |
| `enable_ddos_protection`   | Enable DDoS Protection for the Virtual Network           | `bool`                                                                                                                                                              | No       | `null`  |
| `enable_vm_protection`     | Enable VM protection for the Virtual Network             | `bool`                                                                                                                                                              | No       | `null`  |
| `peerings`                 | Map of VNet peering configurations                       | `map(object({ name = string, remote_vnet_id = string, allow_forwarded_traffic = bool, allow_gateway_transit = bool, allow_virtual_network_access = bool, use_remote_gateways = bool }))` | No       | `{}`    |

### Outputs

| Output      | Description                     |
|-------------|---------------------------------|
| `vnet_id`   | ID of the Virtual Network       |
| `peerings`  | Map of VNet Peering IDs         |

## Best Practices

- **Version Control:** Track changes to the module in version control systems like Git.
- **Remote State Management:** Use remote backends to manage Terraform state securely.
- **Input Validation:** Implement validation rules within `variables.tf` to enforce correct inputs.
- **Modular Design:** Keep modules focused on single responsibilities for better reusability.

## Additional Resources

- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Terraform AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Module Best Practices](https://www.terraform.io/language/modules/develop/best-practices)

---
```

**Explanation of Enhancements:**

- **Overview and Usage Sections:**
  - Updated to reflect the new features like dynamic peerings, DNS servers, DDoS protection, and VM protection.
  
- **Variables and Outputs Tables:**
  - Included the new variables and outputs for clarity.

---

#### **5. Summary of Changes**

- **Dynamic Features Added:**
  - **DNS Servers:** Customizable DNS settings for the VNet.
  - **DDoS Protection:** Optional DDoS protection feature.
  - **VM Protection:** Optional VM protection to prevent accidental deletion of VMs.
  - **Dynamic VNet Peerings:** Ability to define multiple VNet peerings dynamically through a map.

- **Enhanced Outputs:**
  - Provided outputs for both the VNet ID and the peering IDs for better integration with other modules.

---

## **Updated Subnet Module for Reference**

Assuming your **Subnet** module is already enhanced with dynamic blocks and service endpoints as per our previous discussions, here's a recap for consistency:

### **Module Structure**

```
/azure-tf-modules/terraform-azurerm-subnet
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

#### **`main.tf`**

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.10.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create Network Security Groups (NSGs)
resource "azurerm_network_security_group" "nsg" {
  for_each = { for nsg in var.nsgs : nsg.name => nsg }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = lookup(each.value, "security_rules", [])
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
resource "azurerm_route_table" "route_table" {
  for_each = { for rt in var.route_tables : rt.name => rt }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = lookup(each.value, "routes", [])
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}

# Create Subnets
resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  address_prefixes     = each.value.address_prefixes
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name

  # Service Delegations
  dynamic "delegation" {
    for_each = lookup(each.value, "delegations", [])
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
    for_each = lookup(each.value, "service_endpoints", [])
    content {
      service = service_endpoints.value
    }
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "nsg_name", null) != null
  }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_name].id
}

# Associate Route Tables with Subnets
resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "route_table_name", null) != null
  }

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.route_table[each.value.route_table_name].id
}

# Create Service Endpoints for Subnets
resource "azurerm_subnet_service_endpoints" "service_endpoints" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if length(lookup(subnet, "service_endpoints", [])) > 0
  }

  subnet_id            = azurerm_subnet.this[each.key].id
  service_endpoints    = each.value.service_endpoints
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}
```

#### **`variables.tf`**

```hcl
variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "subnets" {
  description = "List of subnet configurations"
  type = list(object({
    name                 = string
    address_prefixes     = list(string)
    nsg_name             = optional(string, null)
    route_table_name     = optional(string, null)
    delegations          = optional(list(object({
      name                = string
      service_delegation  = object({
        name    = string
        actions = list(string)
      })
    })), [])
    service_endpoints    = optional(list(string), [])
  }))
}

variable "nsgs" {
  description = "List of NSG configurations"
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
```

#### **`outputs.tf`**

```hcl
output "subnet_ids" {
  description = "Map of subnet IDs"
  value       = { for subnet in azurerm_subnet.this : subnet.name => subnet.id }
}

output "nsg_ids" {
  description = "Map of NSG IDs"
  value       = { for nsg in azurerm_network_security_group.nsg : nsg.name => nsg.id }
}

output "route_table_ids" {
  description = "Map of Route Table IDs"
  value       = { for rt in azurerm_route_table.route_table : rt.name => rt.id }
}

output "service_endpoints" {
  description = "Map of Subnet Service Endpoints"
  value       = { for se in azurerm_subnet_service_endpoints.service_endpoints : se.subnet_id => se.service_endpoints }
}

output "delegations" {
  description = "Map of Subnet Delegations"
  value       = { for s in azurerm_subnet.this : s.name => s.delegations }
}
```

#### **`README.md`**

```markdown
# Terraform AzureRM Subnet Module

## Overview

This Terraform module creates Azure Subnets with optional Network Security Groups (NSGs), Route Tables, Service Delegations, and Service Endpoints. It's designed to be dynamic and reusable across different environments.

## Module Structure

```
/azure-tf-modules/terraform-azurerm-subnet
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

## Usage

### Example Configuration

```hcl
module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

### Variables

| Variable              | Description                                           | Type                                                                                                                                                        | Required | Default |
|-----------------------|-------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|
| `resource_group_name` | Name of the Resource Group                            | `string`                                                                                                                                                     | Yes      | -       |
| `virtual_network_name`| Name of the Virtual Network                           | `string`                                                                                                                                                     | Yes      | -       |
| `location`            | Azure location                                        | `string`                                                                                                                                                     | Yes      | -       |
| `subnets`             | List of subnet configurations including NSGs, route tables, delegations, and service endpoints | `list(object({ name = string, address_prefixes = list(string), nsg_name = optional(string, null), route_table_name = optional(string, null), delegations = optional(list(object({ name = string, service_delegation = object({ name = string, actions = list(string) })) }), []), service_endpoints = optional(list(string), []) }))` | Yes      | -       |
| `nsgs`                | List of Network Security Groups configurations        | `list(object({ name = string, security_rules = optional(list(object({ name = string, priority = number, direction = string, access = string, protocol = string, source_port_range = string, destination_port_range = string, source_address_prefix = string, destination_address_prefix = string })), []) }))` | No       | `[]`    |
| `route_tables`        | List of Route Table configurations                    | `list(object({ name = string, routes = optional(list(object({ name = string, address_prefix = string, next_hop_type = string, next_hop_in_ip_address = optional(string, null) })), []) }))` | No       | `[]`    |

### Outputs

| Output             | Description                      |
|--------------------|----------------------------------|
| `subnet_ids`       | Map of subnet IDs                 |
| `nsg_ids`          | Map of NSG IDs                    |
| `route_table_ids`  | Map of Route Table IDs            |
| `service_endpoints`| Map of Subnet Service Endpoints   |
| `delegations`      | Map of Subnet Delegations         |

## Best Practices

- **Modular Design:** Keep subnet configurations isolated for reusability.
- **Dynamic Blocks:** Utilize dynamic blocks to handle optional configurations like delegations and service endpoints.
- **Conditional Associations:** Associate NSGs and Route Tables only when specified to avoid unnecessary resource creation.
- **Version Control:** Track module changes using version control systems like Git.

## Additional Resources

- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Terraform AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Modules Best Practices](https://www.terraform.io/language/modules/develop/best-practices)

---
```

**Explanation of Enhancements:**

- **Dynamic Features Added:**
  - Service Delegations and Service Endpoints are now dynamically handled, allowing multiple configurations per subnet.
  
- **Updated Variables and Outputs:**
  - Expanded variables to include delegations and service endpoints.
  - Outputs now include service endpoints and delegations for better integration and reference.

---

## **Updated Environment Configuration**

With the enhanced VNet and Subnet modules, ensure that your environment-specific configurations (`orca-prod` and `orca-dev`) are updated to utilize these enhancements effectively.

### **1. `orca-prod/main.tf`**

```hcl
terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.10.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features        = {}
  subscription_id = var.subscription_id
  alias           = "this"
}

module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_servers            = var.dns_servers
  enable_ddos_protection = var.enable_ddos_protection
  enable_vm_protection   = var.enable_vm_protection

  peerings = var.peerings
}

module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

**Explanation of Enhancements:**

- **Backend Configuration:**
  - Ensure that `backend "azurerm" {}` is properly configured in `backend.tf`. If it's included here, it can be left empty as shown.

- **Provider Configuration:**
  - Consistent use of provider alias `this` for both VNet and Subnet modules.

- **Module Calls:**
  - Updated `module "vnet"` call to include new variables like `dns_servers`, `enable_ddos_protection`, and `enable_vm_protection`.
  - `peerings` variable is now a map, allowing multiple VNet peerings.

### **2. `orca-prod/variables.tf`**

```hcl
variable "subscription_id" {
  description = "Production Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
}

variable "dns_servers" {
  description = "List of DNS servers for the VNet"
  type        = list(string)
  default     = []
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection for the VNet"
  type        = bool
  default     = false
}

variable "enable_vm_protection" {
  description = "Enable VM Protection for the VNet"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnets"
  type = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, null)
    route_table_name = optional(string, null)
    delegations = optional(list(object({
      name                = string
      service_delegation  = object({
        name    = string
        actions = list(string)
      })
    })), [])
    service_endpoints = optional(list(string), [])
  }))
}

variable "nsgs" {
  description = "List of NSG configurations"
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
  description = "Map of VNet peering configurations"
  type = map(object({
    name                       = string
    remote_vnet_id             = string
    allow_forwarded_traffic    = bool
    allow_gateway_transit      = bool
    allow_virtual_network_access = bool
    use_remote_gateways        = bool
  }))
  default = {}
}
```

**Explanation of Enhancements:**

- **New Variables Added:**
  - **`dns_servers`**: Allows specifying custom DNS servers.
  - **`enable_ddos_protection`**: Toggles Azure DDoS Protection.
  - **`enable_vm_protection`**: Toggles VM protection.
  - **`peerings`**: Updated to be a map, enabling multiple VNet peerings with granular configurations.

- **Updated `subnets` Variable:**
  - Included `delegations` and `service_endpoints` to align with the enhanced Subnet module.

### **3. `orca-prod/terraform.tfvars`**

Update your `terraform.tfvars` to include values for the new variables introduced in the enhanced modules.

```hcl
subscription_id     = "YOUR_PROD_SUBSCRIPTION_ID"
location            = "eastus"
resource_group_name = "rg-orca-prod"
vnet_name           = "vnet-orca-prod"
address_space       = ["10.0.0.0/16"]

dns_servers = ["10.1.0.4", "10.1.0.5"]

enable_ddos_protection = true
enable_vm_protection   = true

subnets = [
  {
    name             = "subnet-app"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "nsg-app"
    route_table_name = "rt-app"
    delegations = [
      {
        name = "delegation-app-service"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    ]
    service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
  },
  {
    name             = "subnet-db"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "nsg-db"
    route_table_name = null
    delegations      = []
    service_endpoints = []
  }
]

nsgs = [
  {
    name = "nsg-app"
    security_rules = [
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
      },
      {
        name                       = "AllowHTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name = "nsg-db"
    security_rules = [
      {
        name                       = "AllowSQL"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "*"
      }
    ]
  }
]

route_tables = [
  {
    name = "rt-app"
    routes = [
      {
        name                   = "route-to-internet"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "Internet"
        next_hop_in_ip_address = null
      }
    ]
  }
]

peerings = {
  "prod-to-dev" = {
    name                       = "prod-to-dev"
    remote_vnet_id             = "/subscriptions/YOUR_DEV_SUBSCRIPTION_ID/resourceGroups/rg-orca-dev/providers/Microsoft.Network/virtualNetworks/vnet-orca-dev"
    allow_forwarded_traffic    = true
    allow_gateway_transit      = false
    allow_virtual_network_access = true
    use_remote_gateways        = false
  }
}
```

**Explanation of Enhancements:**

- **`dns_servers`:**
  - Specifies custom DNS servers for the VNet.

- **`enable_ddos_protection` & `enable_vm_protection`:**
  - Enabled for enhanced security and protection.

- **`peerings`:**
  - Added a VNet peering configuration named `prod-to-dev` to peer the production VNet with the development VNet.

- **Subnets:**
  - Added `delegations` and `service_endpoints` to `subnet-app` for service-specific functionalities.

### **4. `orca-prod/backend.tf`**

Ensure your backend configuration is correctly set up to manage Terraform state remotely.

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorageprod"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

**Note:** Ensure that the Azure Storage Account and Container specified in `backend.tf` exist and are accessible.

---

## **Complete Project Overview with Enhanced Modules**

For clarity and completeness, here's the updated project structure with the enhanced VNet module and its integration within the production environment.

### **Project Structure**

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
│   │   └── README.md
│   └── terraform-azurerm-subnet
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── terraform-azurerm-orca
    ├── orca-prod
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    └── orca-dev
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── backend.tf
```

### **Updated `terraform-azurerm-orca/orca-prod/main.tf`**

```hcl
terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.10.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features        = {}
  subscription_id = var.subscription_id
  alias           = "this"
}

module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_servers             = var.dns_servers
  enable_ddos_protection  = var.enable_ddos_protection
  enable_vm_protection    = var.enable_vm_protection

  peerings = var.peerings
}

module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

### **Updated `terraform-azurerm-orca/orca-prod/variables.tf`**

```hcl
variable "subscription_id" {
  description = "Production Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
}

variable "dns_servers" {
  description = "List of DNS servers for the VNet"
  type        = list(string)
  default     = []
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection for the VNet"
  type        = bool
  default     = false
}

variable "enable_vm_protection" {
  description = "Enable VM Protection for the VNet"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnets"
  type = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, null)
    route_table_name = optional(string, null)
    delegations = optional(list(object({
      name                = string
      service_delegation  = object({
        name    = string
        actions = list(string)
      })
    })), [])
    service_endpoints = optional(list(string), [])
  }))
}

variable "nsgs" {
  description = "List of NSG configurations"
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
  description = "Map of VNet peering configurations"
  type = map(object({
    name                       = string
    remote_vnet_id             = string
    allow_forwarded_traffic    = bool
    allow_gateway_transit      = bool
    allow_virtual_network_access = bool
    use_remote_gateways        = bool
  }))
  default = {}
}
```

### **Updated `terraform-azurerm-orca/orca-prod/terraform.tfvars`**

As shown earlier, ensure that all new variables are appropriately defined with actual values.

```hcl
subscription_id     = "YOUR_PROD_SUBSCRIPTION_ID"
location            = "eastus"
resource_group_name = "rg-orca-prod"
vnet_name           = "vnet-orca-prod"
address_space       = ["10.0.0.0/16"]

dns_servers = ["10.1.0.4", "10.1.0.5"]

enable_ddos_protection = true
enable_vm_protection   = true

subnets = [
  {
    name             = "subnet-app"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "nsg-app"
    route_table_name = "rt-app"
    delegations = [
      {
        name = "delegation-app-service"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    ]
    service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
  },
  {
    name             = "subnet-db"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "nsg-db"
    route_table_name = null
    delegations      = []
    service_endpoints = []
  }
]

nsgs = [
  {
    name = "nsg-app"
    security_rules = [
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
      },
      {
        name                       = "AllowHTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name = "nsg-db"
    security_rules = [
      {
        name                       = "AllowSQL"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "*"
      }
    ]
  }
]

route_tables = [
  {
    name = "rt-app"
    routes = [
      {
        name                   = "route-to-internet"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "Internet"
        next_hop_in_ip_address = null
      }
    ]
  }
]

peerings = {
  "prod-to-dev" = {
    name                       = "prod-to-dev"
    remote_vnet_id             = "/subscriptions/YOUR_DEV_SUBSCRIPTION_ID/resourceGroups/rg-orca-dev/providers/Microsoft.Network/virtualNetworks/vnet-orca-dev"
    allow_forwarded_traffic    = true
    allow_gateway_transit      = false
    allow_virtual_network_access = true
    use_remote_gateways        = false
  }
}
```

**Explanation of Enhancements:**

- **`dns_servers`:**
  - Added custom DNS servers for the VNet.

- **`enable_ddos_protection` & `enable_vm_protection`:**
  - Enabled both features for enhanced security.

- **`peerings`:**
  - Defined a VNet peering named `prod-to-dev` to connect the production VNet with the development VNet.
  
- **Subnets:**
  - Included `delegations` and `service_endpoints` for `subnet-app` to support specific Azure services.

### **5. `terraform-azurerm-orca/orca-prod/backend.tf`**

Ensure your backend is correctly configured to store Terraform state remotely.

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorageprod"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

**Note:** Make sure that the Azure Storage Account (`tfstatestorageprod`) and the container (`tfstate`) exist in the specified Resource Group (`tfstate-rg`).

---

## **Ensuring Compatibility and Best Practices**

### **1. Provider Version Compatibility**

- **Terraform Version:** Ensure you are using Terraform version **1.0.0** or higher as specified in your prerequisites.
  
  ```bash
  terraform version
  ```

- **AzureRM Provider:** The module is configured to use version `~> 4.10.0` of the AzureRM provider. Ensure this aligns with your organization's standards.

### **2. Remote State Management**

- **Security:** Protect your Terraform state by storing it remotely in Azure Storage. Ensure that access to the storage account is restricted and secured.

- **Consistency:** Use consistent backend configurations across environments to prevent state conflicts.

### **3. Code Quality and Linting**

- **Pre-commit Hooks:** Utilize pre-commit hooks to maintain code quality. Ensure `.pre-commit-config.yaml` is properly configured to include all necessary hooks.

- **Terraform Format and Validation:**
  
  ```bash
  terraform fmt
  terraform validate
  ```

- **Linting with TFLint:**
  
  ```bash
  tflint
  ```

### **4. Documentation**

- **Module Documentation:** Keep `README.md` files within each module up-to-date to reflect any changes or enhancements.

- **Usage Examples:** Provide clear usage examples to aid other team members in understanding how to integrate the modules.

### **5. Version Control**

- **Git:** Commit all changes to your Git repository with clear and descriptive commit messages.

- **Branching Strategy:** Implement a branching strategy (e.g., GitFlow) to manage changes across different environments effectively.

### **6. Security and Compliance**

- **Sensitive Variables:** Ensure that sensitive information (like subscription IDs) is managed securely. Consider using Azure Key Vault or Terraform variables with sensitive flags.

- **Role-Based Access Control (RBAC):** Implement RBAC to restrict access to Azure resources based on the principle of least privilege.

---

## **Testing the Enhanced Configuration**

After updating the modules and environment configurations, it's crucial to test the changes to ensure they work as expected.

### **1. Initialize Terraform**

Navigate to the environment directory (`orca-prod`) and initialize Terraform.

```bash
cd terraform-azurerm-orca/orca-prod
terraform init
```

**Expected Outcome:**

- Terraform initializes successfully.
- Downloads the specified provider versions.
- Configures the backend for remote state storage.

### **2. Validate the Configuration**

Ensure that your Terraform files are syntactically correct.

```bash
terraform validate
```

**Expected Outcome:**

- No errors; validation is successful.

### **3. Plan the Deployment**

Preview the changes Terraform will make.

```bash
terraform plan
```

**Expected Outcome:**

- A detailed execution plan showing the resources that will be created, modified, or destroyed.
- Confirmation that the enhancements (like DNS servers, DDoS protection, peerings) are recognized.

### **4. Apply the Configuration**

Apply the changes to create or update the infrastructure.

```bash
terraform apply
```

- Review the proposed changes.
- Type `yes` to confirm and apply.

**Expected Outcome:**

- Terraform provisions the specified resources in Azure.
- Outputs like `vnet_id` and `peerings` are displayed upon successful completion.

---

## **Example Terraform.tfvars for Development Environment**

For completeness, here's an example of how you might configure the `terraform.tfvars` for the **Development** environment (`orca-dev`). This assumes similar enhancements as in the production environment.

### **`terraform-azurerm-orca/orca-dev/terraform.tfvars`**

```hcl
subscription_id     = "YOUR_DEV_SUBSCRIPTION_ID"
location            = "eastus"
resource_group_name = "rg-orca-dev"
vnet_name           = "vnet-orca-dev"
address_space       = ["10.1.0.0/16"]

dns_servers = ["10.2.0.4", "10.2.0.5"]

enable_ddos_protection = false
enable_vm_protection   = false

subnets = [
  {
    name             = "subnet-app"
    address_prefixes = ["10.1.1.0/24"]
    nsg_name         = "nsg-app"
    route_table_name = "rt-app"
    delegations = [
      {
        name = "delegation-app-service"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    ]
    service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
  },
  {
    name             = "subnet-db"
    address_prefixes = ["10.1.2.0/24"]
    nsg_name         = "nsg-db"
    route_table_name = null
    delegations      = []
    service_endpoints = []
  }
]

nsgs = [
  {
    name = "nsg-app"
    security_rules = [
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
      },
      {
        name                       = "AllowHTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name = "nsg-db"
    security_rules = [
      {
        name                       = "AllowSQL"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.1.1.0/24"
        destination_address_prefix = "*"
      }
    ]
  }
]

route_tables = [
  {
    name = "rt-app"
    routes = [
      {
        name                   = "route-to-internet"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "Internet"
        next_hop_in_ip_address = null
      }
    ]
  }
]

peerings = {
  # Example: Add peerings if needed
}
```

**Explanation:**

- **DDoS Protection & VM Protection:** Disabled for the development environment as they might not be necessary.
- **DNS Servers:** Different DNS servers for the development environment.
- **Peerings:** You can define additional peerings as needed.

---

## **Additional Adjustments Based on New Structure**

- **Module Source Paths:** Updated module source paths in `main.tf` files to reflect the new directory structure.
  - From `"../modules/vnet"` to `"../../azure-tf-modules/terraform-azurerm-vnet"`
  - From `"../modules/subnet"` to `"../../azure-tf-modules/terraform-azurerm-subnet"`

- **Provider Alias:** Changed provider alias from `azurerm.prod` and `azurerm.dev` to `azurerm.this` for consistency in both environments.

- **Environment Directories:** Renamed environment directories to `orca-prod` and `orca-dev` as per your structure.

---

## **Best Practices Recap**

1. **Modular Design:**
   - Keep modules focused on specific resources (VNet, Subnet) for reusability and maintainability.

2. **Dynamic Blocks:**
   - Use dynamic blocks to handle optional configurations, enabling flexibility.

3. **Remote State Management:**
   - Securely store Terraform state in Azure Storage Accounts with proper access controls.

4. **Code Quality:**
   - Utilize pre-commit hooks and linters (`tflint`, `tfsec`) to maintain high code quality and security standards.

5. **Version Control:**
   - Track all changes using Git, following a clear branching strategy to manage different environments.

6. **Documentation:**
   - Maintain up-to-date `README.md` files within each module to aid team collaboration and onboarding.

7. **Security and Compliance:**
   - Implement RBAC and manage sensitive variables securely, possibly integrating with Azure Key Vault.

---

## **Conclusion**

By enhancing both your **VNet** and **Subnet** modules with dynamic configurations and additional features like DNS servers, DDoS protection, and VM protection, you've made your Terraform infrastructure more robust and flexible. These updates facilitate better resource management, scalability, and adherence to best practices.

Ensure that all team members are aware of these enhancements and update their workflows accordingly. Regularly review and update your modules to incorporate new Azure features and Terraform updates, maintaining the infrastructure's efficiency and security.

---

**Please let me know if you need further assistance or additional enhancements!**
