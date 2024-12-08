# Terraform Azure Infrastructure for Orca Project

This repository contains Terraform configurations for deploying Azure infrastructure for the **Orca Project**. It includes separate environments for **Production (orca-prod)** and **Development (orca-dev)**, utilizing modular design with dedicated modules for Virtual Networks (VNets) and Subnets, including Network Security Groups (NSGs) and Route Tables.

---

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Authentication](#authentication)
- [Modules](#modules)
  - [terraform-azurerm-vnet](#terraform-azurerm-vnet)
  - [terraform-azurerm-subnet](#terraform-azurerm-subnet)
- [Environment Configuration](#environment-configuration)
  - [orca-prod Environment](#orca-prod-environment)
  - [orca-dev Environment](#orca-dev-environment)
- [Usage Instructions](#usage-instructions)
  - [Initializing Terraform](#initializing-terraform)
  - [Planning Infrastructure Changes](#planning-infrastructure-changes)
  - [Applying Infrastructure Changes](#applying-infrastructure-changes)
- [Variables and Customization](#variables-and-customization)
  - [Common Variables](#common-variables)
  - [Customizing for Your Environment](#customizing-for-your-environment)
- [Working with Modules](#working-with-modules)
- [Adding New Environments or Subscriptions](#adding-new-environments-or-subscriptions)
- [Best Practices](#best-practices)
- [Pre-Commit Hooks and Linting](#pre-commit-hooks-and-linting)
- [Additional Resources](#additional-resources)
- [Contact Information](#contact-information)

---

## Introduction

The goal of this project is to provide a scalable and maintainable Terraform codebase for managing Azure infrastructure for the Orca Project. The infrastructure is organized into separate environments (`orca-prod` and `orca-dev`), each with its own Terraform configurations and state management.

---

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

- **Terraform CLI** (version 1.0.0 or higher)
- **Azure CLI** (for authentication)
- **Git** (for version control)
- **Pre-commit** (optional, for code quality checks)
- **TFLint** (optional, for Terraform linting)

---

## Project Structure

```bash
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

- **/azure-tf-modules**: Contains reusable Terraform modules.
  - **terraform-azurerm-vnet**: Module for creating Virtual Networks and VNet peerings.
  - **terraform-azurerm-subnet**: Module for creating Subnets, NSGs, and Route Tables.
- **/terraform-azurerm-orca**: Contains environment-specific configurations for the Orca project.
  - **orca-prod**: Configuration for the production environment.
  - **orca-dev**: Configuration for the development environment.

---

## Authentication

Since you're running Terraform from your local laptop using your own Azure ID (without Service Principals), you'll need to authenticate using the Azure CLI.

### Steps to Authenticate:

1. **Login to Azure CLI:**

   ```bash
   az login
   ```

   This will open a browser window for you to log in with your Azure credentials.

2. **Set the Subscription Context:**

   ```bash
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   ```

   Replace `"YOUR_SUBSCRIPTION_ID"` with the ID of the subscription you want to work with (`orca-prod` or `orca-dev`).

---

## Modules

### terraform-azurerm-vnet

The **terraform-azurerm-vnet** module is responsible for creating Virtual Networks and setting up VNet peering.

#### Path:

```
/terraform/azure-tf-modules/terraform-azurerm-vnet
```

#### Files:

- `main.tf`: Defines the resources for the VNet and peering.
- `variables.tf`: Declares the input variables.
- `outputs.tf`: Exports outputs such as VNet IDs.
- `provider.tf`: Empty file (providers are specified in root modules).

#### Usage:

```hcl
module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  providers = {
    azurerm = azurerm.this
  }

  peerings = var.peerings
}
```

---

### terraform-azurerm-subnet

The **terraform-azurerm-subnet** module handles the creation of Subnets, NSGs, and Route Tables, and associates them appropriately.

#### Path:

```
/terraform/azure-tf-modules/terraform-azurerm-subnet
```

#### Files:

- `main.tf`: Defines the resources for Subnets, NSGs, Route Tables, and their associations.
- `variables.tf`: Declares the input variables.
- `outputs.tf`: Exports outputs such as Subnet IDs.
- `provider.tf`: Empty file (providers are specified in root modules).

#### Usage:

```hcl
module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  providers = {
    azurerm = azurerm.this
  }

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

---

## Environment Configuration

### orca-prod Environment

**Path:** `/terraform/terraform-azurerm-orca/orca-prod`

This directory contains the Terraform code for the production environment.

#### Key Files:

- `main.tf`: Entry point for Terraform; defines provider configurations and module calls.
- `variables.tf`: Declares variables used in `main.tf`.
- `terraform.tfvars`: Provides values for the variables.
- `backend.tf`: Configures remote state storage.

#### Example `main.tf`:

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
  alias           = "this"
}

module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  providers = {
    azurerm = azurerm.this
  }

  peerings = var.peerings
}

module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  providers = {
    azurerm = azurerm.this
  }

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

---

### orca-dev Environment

**Path:** `/terraform/terraform-azurerm-orca/orca-dev`

This directory contains the Terraform code for the development environment. It mirrors the production setup with environment-specific configurations.

---

## Usage Instructions

### Initializing Terraform

Navigate to the environment directory (`/orca-prod` or `/orca-dev`) and run:

```bash
terraform init
```

This command initializes the working directory, downloads provider plugins, and sets up the backend for state storage.

### Planning Infrastructure Changes

To see what changes Terraform will make without actually applying them:

```bash
terraform plan
```

This will show you a detailed execution plan.

### Applying Infrastructure Changes

To apply the changes:

```bash
terraform apply
```

Review the plan and confirm the apply by typing `yes` when prompted.

---

## Variables and Customization

### Common Variables

- `subscription_id`: Azure Subscription ID.
- `location`: Azure region (e.g., `eastus`).
- `resource_group_name`: Name of the Resource Group.
- `vnet_name`: Name of the Virtual Network.
- `address_space`: Address space for the VNet (e.g., `["10.0.0.0/16"]`).

### Customizing for Your Environment

Edit the `terraform.tfvars` file in the environment directory to provide values specific to your environment.

#### Example `terraform.tfvars`:

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

## Working with Modules

### Updating Modules

If you need to modify the infrastructure logic, consider updating the modules:

- **terraform-azurerm-vnet**: For changes related to Virtual Networks and peerings.
- **terraform-azurerm-subnet**: For changes related to Subnets, NSGs, and Route Tables.

### Documentation Generation

We use `terraform-docs` with pre-commit hooks to generate and maintain documentation in `README.md` files within each module.

- **Markers**: Ensure `README.md` files contain `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers for automatic updates.

---

## Adding New Environments or Subscriptions

To add a new environment:

1. **Create a New Directory**: Copy the `/orca-prod` or `/orca-dev` directory and rename it to your new environment (e.g., `/orca-staging`).

2. **Update Configurations**:

   - Edit `terraform.tfvars` with environment-specific values.
   - Update `backend.tf` to point to a new state file.

3. **Initialize and Deploy**:

   - Run `terraform init`.
   - Run `terraform apply`.

---

## Best Practices

- **Version Control**: Commit all changes to your Git repository.

- **State Management**: Use remote state backends to manage state files securely.

- **Code Quality**: Use pre-commit hooks and linters to maintain code quality.

- **Environment Isolation**: Keep configurations for different environments separate to prevent accidental changes.

- **Documentation**: Keep documentation up-to-date for team collaboration.

---

## Pre-Commit Hooks and Linting

We utilize pre-commit hooks to ensure code quality and consistency.

### Setup

1. **Install Pre-commit**:

   ```bash
   pip install pre-commit
   ```

2. **Install Hooks**:

   ```bash
   pre-commit install
   ```

3. **Manual Execution**:

   ```bash
   pre-commit run --all-files
   ```

### Configured Hooks

- **terraform_fmt**: Ensures code is properly formatted.
- **terraform_validate**: Validates Terraform code.
- **terraform_tflint**: Runs TFLint for linting.
- **terraform_tfsec**: Runs security scans.
- **terraform_docs**: Generates module documentation.
- **Standard Hooks**: Trailing whitespace removal, end-of-file fixer, YAML checks.

### .pre-commit-config.yaml

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.77.0  # Use the latest stable version
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
        args: ["--init"]
      - id: terraform_tfsec
      - id: terraform_docs
        args: ["--sort-inputs-by-required"]
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.3.0  # Use the latest stable version
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-merge-conflict
      - id: check-yaml
```

---

## Additional Resources

- **Terraform Documentation**: [https://www.terraform.io/docs](https://www.terraform.io/docs)
- **Azure Terraform Provider**: [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- **Azure CLI Documentation**: [https://docs.microsoft.com/en-us/cli/azure/](https://docs.microsoft.com/en-us/cli/azure/)
- **Pre-commit Hooks for Terraform**: [https://github.com/antonbabenko/pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
- **TFLint**: [https://github.com/terraform-linters/tflint](https://github.com/terraform-linters/tflint)

---

## Contact Information

For questions or assistance, please reach out to the infrastructure team or your project manager.

---

**Note**: Remember to replace placeholder values like `"YOUR_PROD_SUBSCRIPTION_ID"` with actual values relevant to your Azure subscriptions.

---

## Additional Adjustments Based on New Structure

- **Module Source Paths**: Updated module source paths in `main.tf` files to reflect the new directory structure.
  - From `"../modules/vnet"` to `"../../azure-tf-modules/terraform-azurerm-vnet"`
  - From `"../modules/subnet"` to `"../../azure-tf-modules/terraform-azurerm-subnet"`

- **Provider Alias**: Changed provider alias from `azurerm.prod` and `azurerm.dev` to `azurerm.this` for consistency in both environments.

- **Environment Directories**: Renamed environment directories to `orca-prod` and `orca-dev` as per your structure.

---

## Example `main.tf` in `orca-prod`

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
  alias           = "this"
}

module "vnet" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  providers = {
    azurerm = azurerm.this
  }

  peerings = var.peerings
}

module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  resource_group_name  = module.vnet.resource_group_name
  virtual_network_name = module.vnet.name
  location             = var.location

  providers = {
    azurerm = azurerm.this
  }

  subnets      = var.subnets
  nsgs         = var.nsgs
  route_tables = var.route_tables
}
```

---

## Example `backend.tf` in `orca-prod`

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

## Example `variables.tf` in `orca-prod`

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
  type = map(object({
    name           = string
    remote_vnet_id = string
  }))
  default = {}
}
```

---

## .gitignore File

```gitignore
# Local .terraform directories
**/.terraform/*

# Terraform state files
*.tfstate
*.tfstate.*
terraform.tfstate.backup

# Crash log files
crash.log

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore any .tfvars files containing sensitive variables
*.tfvars
!example.tfvars

# Ignore .DS_Store files on macOS
.DS_Store

# Ignore Terraform plan output files
*.tfplan

# Ignore terraform lock file
.terraform.lock.hcl
```

---

## Additional Notes

- **Azure Authentication**: Ensure you have access to the subscriptions and resources defined in your configurations.
- **State Backend**: The `backend.tf` files specify Azure Storage accounts for remote state storage. Make sure these exist or adjust accordingly.
- **Module Versions**: Consider versioning your modules for better control over changes.

---

**Please let me know if you need any further adjustments or additional information!**
