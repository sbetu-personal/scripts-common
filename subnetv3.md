## **Updated Subnet Module Compatible with Azurerm Provider 4.10.0**

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
      version = "~> 4.10.0"
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

# Create Subnets
resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  address_prefixes     = each.value.address_prefixes
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "nsg_name", null) != null
  }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_name].id
}

# Associate Route Tables with Subnets
resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "route_table_name", null) != null
  }

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.route_table[each.value.route_table_name].id
}
```

---

#### **Explanation**

- **Separate Association Resources**:
  - **`azurerm_subnet_network_security_group_association`**: Associates NSGs with subnets.
  - **`azurerm_subnet_route_table_association`**: Associates Route Tables with subnets.
- **Conditional Creation**: The association resources are only created if `nsg_name` or `route_table_name` is specified in the subnet configuration.
- **Dynamic Blocks**: Not used in this context, as we're using separate resources.

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
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string)
    route_table_name = optional(string)
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

Unchanged:

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

### **Adjusting the Root Module**

#### **`/prod/main.tf`**

Ensure that you have the correct provider version specified.

```hcl
# Provider configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.10.0"
    }
  }
}

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

### **Explanation of Changes**

- **Removed Deprecated Properties**: The properties `network_security_group_id` and `route_table_id` are no longer used in the `azurerm_subnet` resource.
- **Separate Association Resources**: The associations are now handled by separate resources as per the updated provider requirements.

---

### **Sample `terraform.tfvars` File**

#### **`/prod/terraform.tfvars`**

```hcl
subscription_id     = "YOUR_PROD_SUBSCRIPTION_ID"
location            = "eastus"
resource_group_name = "rg-orca-prod"
vnet_name           = "vnet-orca-prod"
address_space       = ["10.0.0.0/16"]

subnets = [
  {
    name             = "subnet-app"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "nsg-app"
    route_table_name = "rt-app"
  },
  {
    name             = "subnet-db"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "nsg-db"
    route_table_name = null
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

peerings = {
  # Update with actual peering configurations if needed
}
```

---

### **Testing the Updated Configuration**

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```

2. **Validate the Configuration**:

   ```bash
   terraform validate
   ```

3. **Plan the Deployment**:

   ```bash
   terraform plan
   ```

4. **Apply the Configuration**:

   ```bash
   terraform apply
   ```

   - Review the proposed changes carefully before confirming.

---

### **Important Notes**

- **Provider Version Compatibility**: Always ensure that your Terraform code is compatible with the version of the provider you're using. Changes in provider versions can introduce breaking changes.
- **Use of Separate Association Resources**: From version 3.0 onwards, the association of NSGs and Route Tables to subnets must be done using separate resources.
- **Conditional Resource Creation**: The `for_each` expressions in the association resources include a condition to only create the resource if the association is specified.

---

### **Additional Adjustments**

#### **Variable Type Adjustments**

If you encounter errors related to variable types, you might need to adjust the types in your `variables.tf` files.

For example, you might need to specify that `nsg_name` and `route_table_name` are of type `string` but can be `null`.

```hcl
variable "subnets" {
  description = "List of subnet configurations"
  type = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, null)
    route_table_name = optional(string, null)
  }))
}
```

---

### **Ensuring Compatibility**

To avoid similar issues in the future:

- **Regularly Review Provider Documentation**: Check the official Terraform provider documentation for any changes or deprecations.
- **Pin Provider Versions**: Specify the provider version in your `terraform` block to prevent unexpected upgrades.

---

### **Conclusion**

By updating the subnet module to use separate resources for NSG and Route Table associations, the code is now compatible with `azurerm` provider version **4.10.0**. This approach aligns with the provider's requirements and ensures that your Terraform configurations will function correctly.

---

**Please let me know if you have any further questions or need assistance with any other aspect of your Terraform setup!**
