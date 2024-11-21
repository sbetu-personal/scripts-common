## **Complete Terraform Configuration**

### **1. Folder Structure**

```
/terraform
├── modules
│   ├── vnet
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── provider.tf
│   └── subnet
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── provider.tf
├── prod
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── backend.tf
└── dev
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars
    └── backend.tf
```

---

### **2. Modules**

#### **a. VNet Module**

**Module Path:** `/terraform/modules/vnet`

##### **Files:**

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `provider.tf`

---

##### **`main.tf`**

```hcl
terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.10.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

# Optional Peering
resource "azurerm_virtual_network_peering" "peerings" {
  for_each = var.peerings

  name                       = each.value.name
  resource_group_name        = azurerm_resource_group.this.name
  virtual_network_name       = azurerm_virtual_network.this.name
  remote_virtual_network_id  = each.value.remote_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  # If cross-subscription peering is required, ensure appropriate permissions
  # provider = each.value.provider
}
```

---

##### **`variables.tf`**

```hcl
variable "name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "The address space used by the virtual network"
  type        = list(string)
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "peerings" {
  description = "Map of peering configurations"
  type = map(object({
    name           = string
    remote_vnet_id = string
    # Remove provider if not needed
    # provider       = optional(any)
  }))
  default = {}
}
```

---

##### **`outputs.tf`**

```hcl
output "id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.this.name
}

output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = azurerm_resource_group.this.name
}
```

---

##### **`provider.tf`**

```hcl
# Empty provider.tf file to satisfy Terraform's requirement
# Providers are specified in the root module
```

---

#### **b. Subnet Module**

**Module Path:** `/terraform/modules/subnet`

##### **Files:**

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `provider.tf`

---

##### **`main.tf`**

```hcl
terraform {
  required_version = ">= 0.13"

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

##### **`variables.tf`**

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
    nsg_name         = optional(string, null)
    route_table_name = optional(string, null)
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

---

##### **`outputs.tf`**

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

##### **`provider.tf`**

```hcl
# Empty provider.tf file to satisfy Terraform's requirement
# Providers are specified in the root module
```

---

### **3. Root Modules**

#### **a. Production Environment**

**Folder Path:** `/terraform/prod`

##### **Files:**

- `main.tf`
- `variables.tf`
- `terraform.tfvars`
- `backend.tf`

---

##### **`main.tf`**

```hcl
terraform {
  required_version = ">= 0.13"

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

# VNet module
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

# Subnet module
module "subnets" {
  source               = "../modules/subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  providers = {
    azurerm = azurerm.prod
  }

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

---

##### **`variables.tf`**

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
  type = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, null)
    route_table_name = optional(string, null)
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
  description = "Map of peering configurations"
  type        = map(object({
    name           = string
    remote_vnet_id = string
    # provider       = optional(any)
  }))
  default = {}
}
```

---

##### **`terraform.tfvars`**

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
        next_hop_in_ip_address = null
      }
    ]
  }
]

peerings = {
  # "prod-to-dev" = {
  #   name           = "prod-to-dev"
  #   remote_vnet_id = "REMOTE_DEV_VNET_ID"
  # }
}
```

---

##### **`backend.tf`**

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

---

#### **b. Development Environment**

**Folder Path:** `/terraform/dev`

##### **Files:**

- `main.tf`
- `variables.tf`
- `terraform.tfvars`
- `backend.tf`

---

##### **`main.tf`**

```hcl
terraform {
  required_version = ">= 0.13"

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
  alias           = "dev"
}

# VNet module
module "vnet" {
  source              = "../modules/vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  providers = {
    azurerm = azurerm.dev
  }

  peerings = var.peerings
}

# Subnet module
module "subnets" {
  source               = "../modules/subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  providers = {
    azurerm = azurerm.dev
  }

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

---

##### **`variables.tf`**

```hcl
variable "subscription_id" {
  description = "Development Subscription ID"
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
  type = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_name         = optional(string, null)
    route_table_name = optional(string, null)
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
  description = "Map of peering configurations"
  type        = map(object({
    name           = string
    remote_vnet_id = string
    # provider       = optional(any)
  }))
  default = {}
}
```

---

##### **`terraform.tfvars`**

```hcl
subscription_id     = "YOUR_DEV_SUBSCRIPTION_ID"
location            = "eastus"
resource_group_name = "rg-orca-dev"
vnet_name           = "vnet-orca-dev"
address_space       = ["10.1.0.0/16"]

subnets = [
  {
    name             = "subnet-app"
    address_prefixes = ["10.1.1.0/24"]
    nsg_name         = "nsg-app"
    route_table_name = "rt-app"
  },
  {
    name             = "subnet-db"
    address_prefixes = ["10.1.2.0/24"]
    nsg_name         = null
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
        next_hop_in_ip_address = null
      }
    ]
  }
]

peerings = {
  # "dev-to-prod" = {
  #   name           = "dev-to-prod"
  #   remote_vnet_id = "REMOTE_PROD_VNET_ID"
  # }
}
```

---

##### **`backend.tf`**

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragedev"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

---

### **4. Notes and Explanations**

#### **Variable Definitions**

- The variables `nsgs` and `route_tables` are defined in the `variables.tf` files of the root modules (`/prod` and `/dev`).
- Ensure that these variables are correctly defined as per the types expected.

#### **Type Constraints**

- In `variables.tf`, I've adjusted the variable types to match what's expected in the `terraform.tfvars` files.
- For example, `nsgs` and `route_tables` are defined with specific object types.

#### **Provider Version**

- All configurations are compatible with `azurerm` provider version `4.10.0`.
- The `terraform` block in `main.tf` specifies the required provider version.

#### **Providers in Modules**

- Providers are specified in the root modules (`/prod` and `/dev`) and passed to the modules using the `providers` argument.
- The modules themselves have an empty `provider.tf` file, as they do not specify providers directly.

#### **Peerings**

- In the `terraform.tfvars` files, the `peerings` variable is left commented out.
- You can uncomment and update it when you're ready to establish VNet peerings.

#### **Testing the Configuration**

- **Initialize Terraform**:

  ```bash
  terraform init
  ```

- **Validate the Configuration**:

  ```bash
  terraform validate
  ```

- **Plan the Deployment**:

  ```bash
  terraform plan
  ```

- **Apply the Configuration**:

  ```bash
  terraform apply
  ```

#### **Possible Errors**

- **Variable Mismatch**: Ensure that all variables used in the `terraform.tfvars` file match the definitions in `variables.tf`.
- **Type Errors**: If you encounter type errors, double-check the variable types and the data provided in `terraform.tfvars`.

#### **Common Issues**

- **"Not Expected Here" Errors**: If Terraform reports that a variable is "not expected here," it usually means that the variable is not defined in `variables.tf` or there's a type mismatch.
- **Optional Fields**: Use `optional(string, null)` in variable definitions for optional string variables that can be `null`.

---

### **Conclusion**

This complete configuration should resolve the issues you've encountered with the `nsgs` and `route_tables` variables. The variables are now properly defined, and the modules are updated to work with `azurerm` provider version `4.10.0`.

---

**Please let me know if you have any further questions or if you encounter any other issues. I'm here to help you get your Terraform configuration working smoothly!**
