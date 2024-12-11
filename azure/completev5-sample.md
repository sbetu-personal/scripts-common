Certainly! I'll help you create an updated `terraform.tfvars` file based on the provided Bash script and your specified requirements. Additionally, I'll provide the complete Terraform configuration files for the **orca-dev** environment to ensure consistency and clarity.

### **Summary of Requirements:**

1. **Peering to Hub Subscription:**
   - Establish VNet peering between the **orca-dev** VNet and the **Hub** VNet located in a different subscription.

2. **DDoS Protection:**
   - **Disabled by default** for the VNet.

3. **Custom DNS Servers:**
   - Configure **2 custom DNS servers** for the VNet.

4. **Encryption:**
   - **Disabled** (Assuming no specific encryption configurations are needed as Terraform modules do not explicitly handle encryption in the provided setup).

---

## **1. Updated `terraform.tfvars` for `orca-dev` Environment**

Based on the Bash script and your requirements, here's the updated `terraform.tfvars` for the **orca-dev** environment:

```hcl
# terraform-azurerm-orca/orca-dev/terraform.tfvars

subscription_id     = "YOUR_DEV_SUBSCRIPTION_ID" # Replace with your Development Subscription ID
location            = "eastus"
resource_group_name = "rg-orca-dev"
vnet_name           = "orca-vnet-eastus"
address_space       = ["10.0.0.0/16"] # Updated to a /16 for better subnet allocation

# Custom DNS Servers
dns_servers = ["10.1.0.4", "10.1.0.5"]

# Disable DDoS Protection and VM Protection
enable_ddos_protection = false
enable_vm_protection   = false

# Subnet Configurations
subnets = [
  {
    name             = "orca-subnet-eastus"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "orca-subnet-security-group-eastus"
    route_table_name = null
    delegations      = []
    service_endpoints = []
  },
  {
    name             = "orca-collector-subnet-eastus"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "orca-collector-security-group-eastus"
    route_table_name = null
    delegations      = []
    service_endpoints = []
  }
]

# Network Security Groups (NSGs) Configurations
nsgs = [
  {
    name = "orca-subnet-security-group-eastus"
    security_rules = [
      {
        name                       = "collector-https-rule"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "collector-vnet-outbound-rule"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "VirtualNetwork"
        source_port_range          = "*"
        destination_address_prefix = "VirtualNetwork"
        destination_port_range     = "*"
      },
      {
        name                       = "collector-deny-rule"
        priority                   = 150
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "*"
      }
    ]
  },
  {
    name = "orca-collector-security-group-eastus"
    security_rules = [
      {
        name                       = "collector-https-rule"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "collector-vnet-outbound-rule"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "VirtualNetwork"
        source_port_range          = "*"
        destination_address_prefix = "VirtualNetwork"
        destination_port_range     = "*"
      },
      {
        name                       = "collector-deny-rule"
        priority                   = 150
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "*"
      }
    ]
  }
]

# Route Tables Configurations (Disabled by Default)
route_tables = []

# VNet Peerings to Hub Subscription
peerings = {
  "orca-dev-to-hub" = {
    name                        = "orca-dev-to-hub"
    remote_vnet_id              = "/subscriptions/HUB_SUBSCRIPTION_ID/resourceGroups/HUB_RG/providers/Microsoft.Network/virtualNetworks/hub-vnet" # Replace with Hub VNet ID
    allow_forwarded_traffic     = true
    allow_gateway_transit       = false
    allow_virtual_network_access = true
    use_remote_gateways         = false
  }
}
```

### **Explanation of `terraform.tfvars` Updates:**

1. **Subscription and Resource Group:**
   - **`subscription_id`**: Set to your development subscription ID.
   - **`resource_group_name`**: As per the Bash script (`rg-orca-dev`).

2. **VNet Configuration:**
   - **`vnet_name`**: `orca-vnet-eastus` matching the script.
   - **`address_space`**: Updated to `["10.0.0.0/16"]` for better subnet allocation.

3. **DNS Servers:**
   - **`dns_servers`**: Set to your two custom DNS server IPs (`10.1.0.4` and `10.1.0.5`).

4. **DDoS and VM Protection:**
   - **`enable_ddos_protection`**: Set to `false` to disable DDoS protection.
   - **`enable_vm_protection`**: Set to `false` to disable VM protection.

5. **Subnets:**
   - **`subnets`**: Defined two subnets (`orca-subnet-eastus` and `orca-collector-subnet-eastus`) with distinct address prefixes to avoid overlap.
     - **`nsg_name`**: Associates each subnet with its respective NSG.
     - **`route_table_name`**: Set to `null` as route tables are disabled.
     - **`delegations`** & **`service_endpoints`**: Left empty as per the script requirements.

6. **Network Security Groups (NSGs):**
   - **`nsgs`**: Defined two NSGs (`orca-subnet-security-group-eastus` and `orca-collector-security-group-eastus`) with the specified security rules.

7. **Route Tables:**
   - **`route_tables`**: Left empty (`[]`) to disable route tables as per your requirements.

8. **Peerings:**
   - **`peerings`**: Established a VNet peering (`orca-dev-to-hub`) to the Hub VNet.
     - **`remote_vnet_id`**: Replace with the actual Resource ID of your Hub VNet.
     - **`allow_forwarded_traffic`**, **`allow_virtual_network_access`**: Enabled.
     - **`allow_gateway_transit`**, **`use_remote_gateways`**: Disabled.

---

## **2. Complete Terraform Configuration for `orca-dev` Environment**

To ensure clarity and completeness, here's the full Terraform configuration for the **orca-dev** environment, integrating the updated `terraform.tfvars` and adhering to your requirements.

### **Project Structure**

```
/terraform
└── terraform-azurerm-orca
    └── orca-dev
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── backend.tf
```

### **a. `orca-dev/main.tf`**

```hcl
# terraform-azurerm-orca/orca-dev/main.tf

terraform {
  required_version = ">= 1.0.0"

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

# Virtual Network Module
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

# Subnets Module
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

### **b. `orca-dev/variables.tf`**

```hcl
# terraform-azurerm-orca/orca-dev/variables.tf

variable "subscription_id" {
  description = "Development Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
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
  description = "Address space for the Virtual Network"
  type        = list(string)
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
  description = "Map of VNet peering configurations"
  type = map(object({
    name                        = string
    remote_vnet_id              = string
    allow_forwarded_traffic     = bool
    allow_gateway_transit       = bool
    allow_virtual_network_access = bool
    use_remote_gateways         = bool
  }))
  default = {}
}
```

### **c. `orca-dev/backend.tf`**

Ensure that the backend is correctly configured to store Terraform state remotely in Azure Blob Storage.

```hcl
# terraform-azurerm-orca/orca-dev/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragedev" # Replace with your dev storage account name
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

**Note:**
- **Storage Account:** Ensure that the Azure Storage Account (`tfstatestoragedev`) and the container (`tfstate`) exist in the specified Resource Group (`tfstate-rg`). If not, create them before initializing Terraform.

### **d. `orca-dev/terraform.tfvars`**

As provided earlier, here's the complete `terraform.tfvars` for **orca-dev**:

```hcl
# terraform-azurerm-orca/orca-dev/terraform.tfvars

subscription_id     = "YOUR_DEV_SUBSCRIPTION_ID" # Replace with your Development Subscription ID
location            = "eastus"
resource_group_name = "rg-orca-dev"
vnet_name           = "orca-vnet-eastus"
address_space       = ["10.0.0.0/16"] # Updated to a /16 for better subnet allocation

# Custom DNS Servers
dns_servers = ["10.1.0.4", "10.1.0.5"]

# Disable DDoS Protection and VM Protection
enable_ddos_protection = false
enable_vm_protection   = false

# Subnet Configurations
subnets = [
  {
    name             = "orca-subnet-eastus"
    address_prefixes = ["10.0.1.0/24"]
    nsg_name         = "orca-subnet-security-group-eastus"
    route_table_name = null
    delegations      = []
    service_endpoints = []
  },
  {
    name             = "orca-collector-subnet-eastus"
    address_prefixes = ["10.0.2.0/24"]
    nsg_name         = "orca-collector-security-group-eastus"
    route_table_name = null
    delegations      = []
    service_endpoints = []
  }
]

# Network Security Groups (NSGs) Configurations
nsgs = [
  {
    name = "orca-subnet-security-group-eastus"
    security_rules = [
      {
        name                       = "collector-https-rule"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "collector-vnet-outbound-rule"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "VirtualNetwork"
        source_port_range          = "*"
        destination_address_prefix = "VirtualNetwork"
        destination_port_range     = "*"
      },
      {
        name                       = "collector-deny-rule"
        priority                   = 150
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "*"
      }
    ]
  },
  {
    name = "orca-collector-security-group-eastus"
    security_rules = [
      {
        name                       = "collector-https-rule"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "collector-vnet-outbound-rule"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "VirtualNetwork"
        source_port_range          = "*"
        destination_address_prefix = "VirtualNetwork"
        destination_port_range     = "*"
      },
      {
        name                       = "collector-deny-rule"
        priority                   = 150
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "*"
      }
    ]
  }
]

# Route Tables Configurations (Disabled by Default)
route_tables = []

# VNet Peerings to Hub Subscription
peerings = {
  "orca-dev-to-hub" = {
    name                        = "orca-dev-to-hub"
    remote_vnet_id              = "/subscriptions/HUB_SUBSCRIPTION_ID/resourceGroups/HUB_RG/providers/Microsoft.Network/virtualNetworks/hub-vnet" # Replace with Hub VNet ID
    allow_forwarded_traffic     = true
    allow_gateway_transit       = false
    allow_virtual_network_access = true
    use_remote_gateways         = false
  }
}
```

**Key Points:**

- **Subscription IDs and Resource IDs:**
  - Replace `"YOUR_DEV_SUBSCRIPTION_ID"` with your actual Development Azure Subscription ID.
  - Replace `"/subscriptions/HUB_SUBSCRIPTION_ID/resourceGroups/HUB_RG/providers/Microsoft.Network/virtualNetworks/hub-vnet"` with the actual Resource ID of your Hub VNet.

- **DNS Servers:**
  - Ensure that the provided DNS server IPs (`10.1.0.4` and `10.1.0.5`) are reachable and correctly configured within your network.

- **Peerings:**
  - The peering configuration allows the **orca-dev** VNet to communicate with the **Hub** VNet.
  - Adjust the `remote_vnet_id` as per your Hub VNet's actual Resource ID.

---

## **3. Additional Terraform Configuration Files**

For completeness, here's a brief overview of the remaining Terraform configuration files for the **orca-dev** environment.

### **a. `orca-dev/main.tf`**

```hcl
# terraform-azurerm-orca/orca-dev/main.tf

terraform {
  required_version = ">= 1.0.0"

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

# Virtual Network Module
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

# Subnets Module
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

**Note:** This `main.tf` is identical to the one provided earlier. Ensure consistency across environments by maintaining similar structures.

### **b. `orca-dev/variables.tf`**

As provided earlier, no changes are needed here beyond what's already specified.

### **c. `orca-dev/backend.tf`**

```hcl
# terraform-azurerm-orca/orca-dev/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"          # Replace with your state RG if different
    storage_account_name = "tfstatestoragedev"  # Replace with your dev storage account name
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

**Ensure that:**

- The **Storage Account** (`tfstatestoragedev`) exists and is accessible.
- The **Container** (`tfstate`) exists within the specified Resource Group (`tfstate-rg`).

---

## **4. Verification and Deployment Steps**

### **a. Initialize Terraform**

Navigate to the **orca-dev** directory and initialize Terraform:

```bash
cd terraform-azurerm-orca/orca-dev
terraform init
```

**Expected Outcome:**

- Terraform initializes successfully.
- Downloads the specified AzureRM provider version.
- Configures the backend for remote state storage.

### **b. Validate Configuration**

Ensure that your Terraform configuration is syntactically correct:

```bash
terraform validate
```

**Expected Outcome:**

- No errors; validation is successful.

### **c. Plan the Deployment**

Preview the changes Terraform will make:

```bash
terraform plan
```

**Expected Outcome:**

- A detailed execution plan outlining the resources to be created.
- Confirmation that DDoS protection is disabled, custom DNS servers are set, and VNet peering is configured.

### **d. Apply the Configuration**

Apply the changes to deploy the infrastructure:

```bash
terraform apply
```

- Review the proposed changes.
- Type `yes` to confirm and proceed.

**Expected Outcome:**

- Terraform provisions the specified resources in Azure.
- Outputs such as `vnet_id` and `peerings` are displayed upon successful completion.

---

## **5. Important Considerations**

1. **Address Space Allocation:**
   - **VNet Address Space (`10.0.0.0/16`)** allows for multiple subnets without overlap.
   - **Subnet Address Prefixes:** Ensure that each subnet has a unique and non-overlapping address prefix within the VNet.

2. **VNet Peering:**
   - **Hub VNet:** Ensure that the Hub VNet exists and that you have the necessary permissions to peer with it.
   - **Permissions:** Both subscriptions (development and hub) must allow peering. Confirm that the Hub subscription permits peering connections from the Development subscription.

3. **Network Security Groups (NSGs):**
   - **Outbound Rules:** The defined outbound rules in the NSGs ensure that only specific traffic (e.g., HTTPS to port 443) is allowed, with a deny-all rule as a fallback.
   - **Inbound Rules:** Currently, only outbound rules are defined. If you require inbound traffic controls, consider adding inbound rules accordingly.

4. **Route Tables:**
   - **Disabled by Default:** Since `route_tables` is an empty list, no custom routing is applied. If you need specific routing rules in the future, update the `route_tables` variable.

5. **Service Endpoints & Delegations:**
   - **Service Endpoints:** Currently left empty (`[]`). If you need to enable service endpoints for specific Azure services (e.g., `Microsoft.Storage`), add them to the `service_endpoints` list within each subnet.
   - **Delegations:** Also left empty. Add delegations if you plan to delegate subnet management to specific Azure services.

6. **State Management:**
   - **Remote State:** Ensure that the backend storage account is secure and that access is restricted to authorized personnel only.
   - **State Locking:** Azure Blob Storage handles state locking, preventing concurrent modifications.

7. **Encryption:**
   - **Default Encryption:** Azure VNets encrypt data in transit by default. Since no specific encryption configurations are applied in the Terraform modules, no additional encryption settings are needed.
   - **Storage Encryption:** If you use Azure Storage Accounts within your infrastructure, encryption is enabled by default. To disable it (not recommended), you'd need to adjust the respective resource configurations.

8. **Peering to Hub Subscription:**
   - **Resource IDs:** Ensure that the `remote_vnet_id` accurately reflects the Resource ID of the Hub VNet.
   - **DNS Resolution:** VNet peering enables name resolution between VNets if configured. If you have custom DNS servers, ensure they are properly resolving resources across peered VNets.

---

## **6. Final Notes**

- **Consistency Across Environments:** Ensure that any changes made to the **orca-dev** environment are also reflected (with necessary adjustments) in the **orca-prod** environment to maintain consistency.

- **Testing:** Before deploying to production, thoroughly test the **orca-dev** environment to ensure that all configurations work as expected.

- **Documentation:** Keep your Terraform modules and environment configurations well-documented to facilitate team collaboration and future maintenance.

- **Security:** Regularly review your NSG rules and other security configurations to adhere to the principle of least privilege and to comply with organizational security policies.

---

**Feel free to reach out if you need further assistance or additional enhancements! Happy Terraforming! 🚀**
