**Understood! Let's tailor the architecture to accommodate separate folders for each subscription, with one being production (prod) and the other development (dev). We'll adjust the Terraform code and folder structure accordingly, ensuring best practices are followed.**

---

## **Updated Azure Infrastructure Design for Separate Subscriptions**

### **1. Overview**

You're setting up infrastructure for **Orca** in Azure, with two subscriptions:

- **Production Subscription (prod)**
- **Development Subscription (dev)**

Each subscription will have its own dedicated folder containing its Terraform configurations. We'll create dedicated modules for VNets and Subnets, with peering included in the VNet module. This approach enhances separation of concerns, facilitates team collaboration, and aligns with best practices for managing environments.

---

### **2. Folder Structure**

Organize your Terraform code with separate folders for each subscription:

```
/terraform
├── modules
│   ├── vnet
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── subnet
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
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

**Explanation:**

- **`/modules`**: Contains reusable Terraform modules (VNet and Subnet).
- **`/prod` and `/dev`**: Separate folders for production and development subscriptions, each with their own Terraform configurations.

---

### **3. Modules**

#### **a. VNet Module with Peering**

Include peering within the VNet module to manage VNet creation and peering in a single place.

**Module Path:** `/modules/vnet`

**Module Files:**

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `README.md`

##### **Module Code**

**`main.tf`:**

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  provider = var.provider
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  provider            = var.provider
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

  provider = var.provider
}
```

**`variables.tf`:**

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

variable "provider" {
  description = "Azure provider configuration"
  type        = any
}

variable "peerings" {
  description = "Map of peering configurations"
  type = map(object({
    name           = string
    remote_vnet_id = string
    provider       = any
  }))
  default = {}
}
```

**`outputs.tf`:**

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

#### **b. Subnet Module**

**Module Path:** `/modules/subnet`

**Module Files:**

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `README.md`

##### **Module Code**

**`main.tf`:**

```hcl
resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  address_prefixes     = each.value.address_prefixes
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name

  # Optional Associations
  network_security_group_id = each.value.nsg_id
  route_table_id            = each.value.route_table_id

  provider = var.provider
}
```

**`variables.tf`:**

```hcl
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
    nsg_id           = optional(string)
    route_table_id   = optional(string)
  }))
}

variable "provider" {
  description = "Azure provider configuration"
  type        = any
}
```

**`outputs.tf`:**

```hcl
output "subnet_ids" {
  description = "Map of subnet IDs"
  value       = { for subnet in azurerm_subnet.this : subnet.name => subnet.id }
}
```

---

### **4. Subscription-Specific Configurations**

Each subscription (prod and dev) will have its own Terraform configurations.

#### **a. Production Subscription**

**Folder Path:** `/prod`

**Files:**

- `main.tf`
- `variables.tf`
- `terraform.tfvars`
- `backend.tf`

##### **`main.tf`:**

```hcl
# Specify the provider for the production subscription
provider "azurerm" {
  features        = {}
  subscription_id = var.subscription_id
  alias           = "prod"
}

# Use the VNet module
module "vnet" {
  source              = "../modules/vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  provider            = azurerm.prod

  peerings = var.peerings
}

# Use the Subnet module
module "subnets" {
  source               = "../modules/subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  provider             = azurerm.prod

  subnets = var.subnets
}
```

##### **`variables.tf`:**

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
  type        = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_id           = optional(string)
    route_table_id   = optional(string)
  }))
}

variable "peerings" {
  description = "Map of peering configurations"
  type        = map(any)
  default     = {}
}
```

##### **`terraform.tfvars`:**

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
    nsg_id           = null
    route_table_id   = null
  },
  {
    name             = "subnet-db"
    address_prefixes = ["10.0.2.0/24"]
    nsg_id           = null
    route_table_id   = null
  }
]

peerings = {
  "prod-to-dev" = {
    name           = "prod-to-dev"
    remote_vnet_id = "REMOTE_DEV_VNET_ID"  # Will be replaced after dev VNet is created
    provider       = azurerm.prod
  }
}
```

##### **`backend.tf`:**

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

#### **b. Development Subscription**

**Folder Path:** `/dev`

**Files:**

- `main.tf`
- `variables.tf`
- `terraform.tfvars`
- `backend.tf`

##### **`main.tf`:**

```hcl
# Specify the provider for the development subscription
provider "azurerm" {
  features        = {}
  subscription_id = var.subscription_id
  alias           = "dev"
}

# Use the VNet module
module "vnet" {
  source              = "../modules/vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  provider            = azurerm.dev

  peerings = var.peerings
}

# Use the Subnet module
module "subnets" {
  source               = "../modules/subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  provider             = azurerm.dev

  subnets = var.subnets
}
```

##### **`variables.tf`:**

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
  type        = list(object({
    name             = string
    address_prefixes = list(string)
    nsg_id           = optional(string)
    route_table_id   = optional(string)
  }))
}

variable "peerings" {
  description = "Map of peering configurations"
  type        = map(any)
  default     = {}
}
```

##### **`terraform.tfvars`:**

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
    nsg_id           = null
    route_table_id   = null
  },
  {
    name             = "subnet-db"
    address_prefixes = ["10.1.2.0/24"]
    nsg_id           = null
    route_table_id   = null
  }
]

peerings = {
  "dev-to-prod" = {
    name           = "dev-to-prod"
    remote_vnet_id = "REMOTE_PROD_VNET_ID"  # Will be replaced after prod VNet is created
    provider       = azurerm.dev
  }
}
```

##### **`backend.tf`:**

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

### **5. Establishing Peering Between Prod and Dev VNets**

Since the peering requires the VNet IDs from both environments, you'll need to perform a two-step process:

1. **Deploy the VNets without peerings first.**
2. **Update the `terraform.tfvars` files with the remote VNet IDs.**
3. **Deploy again to establish the peering.**

#### **Step 1: Deploy VNets Without Peerings**

In both `terraform.tfvars` files, set the `peerings` variable to an empty map `{}`.

**Prod `terraform.tfvars`:**

```hcl
peerings = {}
```

**Dev `terraform.tfvars`:**

```hcl
peerings = {}
```

**Deploy VNets:**

```bash
# In /prod
terraform init
terraform apply

# In /dev
terraform init
terraform apply
```

#### **Step 2: Update Remote VNet IDs**

After both VNets are created, update the `peerings` variable in each `terraform.tfvars` file with the remote VNet ID.

**Retrieve VNet IDs:**

- **Prod VNet ID:** Run `terraform output -raw module.vnet.id` in `/prod`.
- **Dev VNet ID:** Run `terraform output -raw module.vnet.id` in `/dev`.

**Update `terraform.tfvars`:**

**Prod `terraform.tfvars`:**

```hcl
peerings = {
  "prod-to-dev" = {
    name           = "prod-to-dev"
    remote_vnet_id = "<DEV_VNET_ID>"
    provider       = azurerm.prod
  }
}
```

**Dev `terraform.tfvars`:**

```hcl
peerings = {
  "dev-to-prod" = {
    name           = "dev-to-prod"
    remote_vnet_id = "<PROD_VNET_ID>"
    provider       = azurerm.dev
  }
}
```

#### **Step 3: Deploy Peering Configurations**

Deploy again to establish the peering.

```bash
# In /prod
terraform apply

# In /dev
terraform apply
```

---

### **6. Best Practices and Considerations**

#### **a. Environment Isolation**

- **Separate State Files:** Using separate backends (`backend.tf`) ensures that state files for prod and dev are isolated.
- **Access Control:** Limit access to production configurations and resources to authorized personnel only.

#### **b. Security**

- **Service Principals:** Use Azure Service Principals with least privilege necessary for Terraform deployments.
- **Secrets Management:** Store sensitive data (e.g., subscription IDs, access keys) securely, possibly using Azure Key Vault or environment variables.

#### **c. Naming Conventions**

- **Consistency:** Use consistent naming for resources to simplify management and identification.
- **Environment Prefixes:** Include environment identifiers (e.g., `prod`, `dev`) in resource names.

#### **d. Reusability**

- **Modules:** Keep modules generic and reusable across environments.
- **Variables:** Parameterize configurations using variables.

#### **e. Collaboration**

- **Version Control:** Commit all configurations to your Bitbucket repository.
- **Branching Strategy:** Use branches for feature development and environment-specific changes.

#### **f. Peering Between Environments**

- **Security Risks:** Peering production and development environments can introduce security risks. Ensure appropriate network security measures are in place.
- **Network Security Groups (NSGs):** Use NSGs to control traffic between subnets and VNets.

---

### **7. Enhancements**

#### **a. Automate Peering Setup**

To simplify the peering setup, you can use Azure Resource IDs that are known beforehand or manage outputs and remote state data.

**Option 1: Use Data Sources**

In the prod `main.tf`, reference the dev VNet via a data source.

```hcl
data "azurerm_virtual_network" "dev_vnet" {
  name                = "vnet-orca-dev"
  resource_group_name = "rg-orca-dev"
  provider            = azurerm.prod
}
```

Update `peerings` in the prod `main.tf`:

```hcl
peerings = {
  "prod-to-dev" = {
    name           = "prod-to-dev"
    remote_vnet_id = data.azurerm_virtual_network.dev_vnet.id
    provider       = azurerm.prod
  }
}
```

**Note:** You need appropriate permissions to access the dev subscription from the prod configuration.

**Option 2: Use Remote State Data**

Enable remote state sharing to access the dev VNet ID in the prod configuration.

---

### **8. Conclusion**

By structuring your Terraform code with separate folders for each subscription and utilizing dedicated modules for VNets and Subnets, you achieve:

- **Environment Isolation:** Clear separation between prod and dev environments.
- **Modularity:** Reusable modules promote consistency and ease of maintenance.
- **Scalability:** Easily extend the infrastructure to additional subscriptions or environments in the future.
- **Best Practices Compliance:** Aligns with Terraform and Azure best practices for infrastructure as code.

---

**Let me know if you need further assistance or have any questions about this setup!**
