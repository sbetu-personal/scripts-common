## **Updated Subnet Module with NSG and Route Table Code**

### **Module Structure**

```
/modules/subnet
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

### **Updated Code**

#### **`main.tf`**

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74.0"
    }
  }
}

# Create NSGs
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

# Create Subnets and associate NSGs and Route Tables
resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  address_prefixes     = each.value.address_prefixes
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name

  network_security_group_id = each.value.nsg_name != null ? azurerm_network_security_group.nsg[each.value.nsg_name].id : null
  route_table_id            = each.value.route_table_name != null ? azurerm_route_table.route_table[each.value.route_table_name].id : null
}
```

---

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
    name                = string
    address_prefixes    = list(string)
    nsg_name            = optional(string)
    route_table_name    = optional(string)
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
    })))
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
      next_hop_in_ip_address = optional(string)
    })))
  }))
  default = []
}
```

---

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
```

---

### **Explanation**

- **NSG Creation**: The module now includes resources to create Network Security Groups (`azurerm_network_security_group.nsg`) based on the `nsgs` variable.
- **Route Table Creation**: Similarly, Route Tables are created using the `route_tables` variable.
- **Associations**: Subnets are associated with NSGs and Route Tables using the `nsg_name` and `route_table_name` attributes in the `subnets` variable.
- **Dynamic Blocks**: Dynamic blocks are used to define security rules within NSGs and routes within Route Tables, allowing for flexible configurations.

---

### **Updating Root Module Configuration**

In your root module (e.g., `/prod/main.tf`), you need to supply the new variables (`nsgs`, `route_tables`) to the subnet module.

#### **`/prod/main.tf`**

```hcl
# Provider configuration
provider "azurerm" {
  features        = {}
  subscription_id = var.subscription_id
  alias           = "prod"
}

# VNet module remains unchanged
module "vnet" {
  source              = "../modules/vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  providers = {
    azurerm = azurerm.prod
  }

  peerings = var.peerings
}

# Subnet module with NSG and Route Table configurations
module "subnets" {
  source               = "../modules/subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  providers = {
    azurerm = azurerm.prod
  }

  subnets       = var.subnets
  nsgs          = var.nsgs
  route_tables  = var.route_tables
}
```

---

### **Updating Variables and Terraform Variables File**

#### **`/prod/variables.tf`**

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
  description = "Name of the resource group"
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

variable "subnets" {
  description = "List of subnets"
  type        = list(any)
}

variable "nsgs" {
  description = "List of NSG configurations"
  type        = list(any)
  default     = []
}

variable "route_tables" {
  description = "List of Route Table configurations"
  type        = list(any)
  default     = []
}

variable "peerings" {
  description = "Map of peering configurations"
  type        = map(any)
  default     = {}
}
```

#### **`/prod/terraform.tfvars`**

```hcl
subscription_id     = "YOUR_PROD_SUBSCRIPTION_ID"
location            = "eastus"
resource_group_name = "rg-orca-prod"
vnet_name           = "vnet-orca-prod"
address_space       = ["10.0.0.0/16"]

subnets = [
  {
    name                = "subnet-app"
    address_prefixes    = ["10.0.1.0/24"]
    nsg_name            = "nsg-app"
    route_table_name    = "rt-app"
  },
  {
    name                = "subnet-db"
    address_prefixes    = ["10.0.2.0/24"]
    nsg_name            = "nsg-db"
    route_table_name    = null
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
      }
    ]
  }
]
```

---

### **Explanation of Changes**

- **`nsgs` Variable**: Added to define the NSGs and their security rules.
- **`route_tables` Variable**: Added to define the Route Tables and their routes.
- **`subnets` Variable**: Updated to include `nsg_name` and `route_table_name` for associating NSGs and Route Tables with subnets.
- **Associations in Subnet Resource**: In `main.tf`, the `azurerm_subnet` resource now associates the subnet with the specified NSG and Route Table.

---

### **Handling Optional Associations**

In cases where a subnet does not need an NSG or Route Table, you can set `nsg_name` or `route_table_name` to `null` or omit them in the `subnets` variable.

```hcl
{
  name                = "subnet-db"
  address_prefixes    = ["10.0.2.0/24"]
  nsg_name            = null  # No NSG association
  route_table_name    = null  # No Route Table association
}
```

---

### **Ensuring Correct Provider Usage**

As previously discussed, providers cannot be passed as variables. Ensure that:

- **Providers are defined in the root module (`/prod/main.tf`)** and passed to the module using the `providers` argument.
- **Do not include `provider` configurations inside module resources** or as variables.

---

### **Testing and Validation**

Before deploying to production:

1. **Validate the Configuration**: Run `terraform validate` in your root module to ensure there are no syntax errors.
2. **Plan the Deployment**: Use `terraform plan` to review the changes that will be made.
3. **Apply in a Test Environment**: If possible, test the updated module in a non-production environment.

---

### **Best Practices**

- **Modularization**: Keep modules focused and reusable. While we've added NSG and Route Table creation to the subnet module per your request, consider whether separate modules might offer better reusability.
- **Documentation**: Update the `README.md` file in the subnet module to reflect the new variables and usage instructions.
- **Version Control**: Commit all changes to your version control system (e.g., Bitbucket) and consider using feature branches for development.

---

### **Sample Usage in the Dev Environment**

For your development subscription (`/dev`), you can replicate the same setup with appropriate values in `terraform.tfvars`.

#### **`/dev/terraform.tfvars`**

```hcl
subscription_id     = "YOUR_DEV_SUBSCRIPTION_ID"
location            = "eastus"
resource_group_name = "rg-orca-dev"
vnet_name           = "vnet-orca-dev"
address_space       = ["10.1.0.0/16"]

subnets = [
  {
    name                = "subnet-app"
    address_prefixes    = ["10.1.1.0/24"]
    nsg_name            = "nsg-app"
    route_table_name    = "rt-app"
  },
  {
    name                = "subnet-db"
    address_prefixes    = ["10.1.2.0/24"]
    nsg_name            = null
    route_table_name    = null
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
      # Additional rules...
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
      }
    ]
  }
]
```

---

### **Conclusion**

By updating the subnet module to include NSG and Route Table creation and associations, you can manage all related networking resources within a single module, enhancing convenience and cohesion.

---

**Let me know if you have any questions or need further assistance with this setup!**
