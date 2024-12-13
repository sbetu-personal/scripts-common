These `tfvars` files will help you manage configurations for multiple VNets across different regions and environments. Below are the detailed configurations tailored to your infrastructure setup.

---

## **1. Understanding the Structure**

### **Virtual Networks (VNets):**
- **North Central:**
  - `orca-vnet-dev-nc` (Development)
  - `orca-vnet-prod-nc` (Production)
  
- **South Central:**
  - `orca-vnet-dev-sc` (Development)
  - `orca-vnet-prod-sc` (Production)

### **Subnets per VNet:**
- **App Subnet:**
  - CIDR Block: `/24`
  - Associated with NSG and Route Table

- **GatewaySubnet:**
  - CIDR Block: `/27`
  - **No NSG or Route Table**

---

## **2. Updated `dev.tfvars`**

This file contains configuration settings for the **Development** environment, covering both North Central and South Central VNets.

```hcl
# Development Environment Variable Definitions

# List of Virtual Networks
vnets = [
  {
    name                = "orca-vnet-dev-nc"                     # VNet Name in North Central
    address_space       = ["10.0.0.0/16"]                        # Address space for the VNet
    location            = "northcentralus"                       # Azure region
    resource_group_name = "rg-orca-dev-nc"                       # Resource Group

    dns_servers         = ["10.1.0.4", "10.1.0.5"]               # Custom DNS server IPs
    enable_ddos_protection = false                                # DDoS Protection
    enable_vm_protection   = false                                # VM Protection

    subnets = [
      {
        name               = "app-subnet-dev-nc"                  # App Subnet Name
        address_prefixes   = ["10.0.1.0/24"]                       # CIDR for App Subnet
        nsg_name           = "app-nsg-dev-nc"                      # NSG for App Subnet
        route_table_name   = "app-route-table-dev-nc"              # Route Table for App Subnet
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      },
      {
        name               = "GatewaySubnet"                       # Gateway Subnet Name (standard)
        address_prefixes   = ["10.0.254.0/27"]                      # CIDR for GatewaySubnet
        nsg_name           = null                                   # No NSG
        route_table_name   = null                                   # No Route Table
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      }
    ]

    nsgs = [
      {
        name = "app-nsg-dev-nc"                                       # NSG Name
        security_rules = [
          {
            name                       = "Allow-HTTP"
            priority                   = 100                          # Priority (lower number = higher priority)
            direction                  = "Inbound"                    # Direction: Inbound or Outbound
            access                     = "Allow"                      # Access: Allow or Deny
            protocol                   = "Tcp"                        # Protocol: Tcp, Udp, or *
            source_port_range          = "*"                          # Source Port Range
            destination_port_range     = "80"                         # Destination Port Range
            source_address_prefix      = "*"                          # Source Address Prefix
            destination_address_prefix = "*"                          # Destination Address Prefix
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
      }
    ]

    route_tables = [
      {
        name   = "app-route-table-dev-nc"                            # Route Table Name
        routes = [
          {
            name           = "Internet"                               # Route Name
            address_prefix = "0.0.0.0/0"                              # Address Prefix
            next_hop_type  = "Internet"                               # Next Hop Type
          }
        ]
      }
    ]

    peerings = [
      {
        name                        = "dev-nc-to-dev-sc-peering"      # Peering Name
        remote_virtual_network_id   = "/subscriptions/YOUR_DEV_SC_SUBSCRIPTION_ID/resourceGroups/YOUR_DEV_SC_RG/providers/Microsoft.Network/virtualNetworks/orca-vnet-dev-sc" # Remote VNet ID
        allow_forwarded_traffic     = true                            # Allow Forwarded Traffic
        allow_virtual_network_access = true                            # Allow Virtual Network Access
        allow_gateway_transit       = false                           # Allow Gateway Transit
        use_remote_gateways         = false                           # Use Remote Gateways
      }
    ]
  },

  {
    name                = "orca-vnet-dev-sc"                     # VNet Name in South Central
    address_space       = ["10.2.0.0/16"]                        # Address space for the VNet
    location            = "southcentralus"                       # Azure region
    resource_group_name = "rg-orca-dev-sc"                       # Resource Group

    dns_servers         = ["10.3.0.4", "10.3.0.5"]               # Custom DNS server IPs
    enable_ddos_protection = false                                # DDoS Protection
    enable_vm_protection   = false                                # VM Protection

    subnets = [
      {
        name               = "app-subnet-dev-sc"                  # App Subnet Name
        address_prefixes   = ["10.2.1.0/24"]                       # CIDR for App Subnet
        nsg_name           = "app-nsg-dev-sc"                      # NSG for App Subnet
        route_table_name   = "app-route-table-dev-sc"              # Route Table for App Subnet
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      },
      {
        name               = "GatewaySubnet"                       # Gateway Subnet Name (standard)
        address_prefixes   = ["10.2.254.0/27"]                      # CIDR for GatewaySubnet
        nsg_name           = null                                   # No NSG
        route_table_name   = null                                   # No Route Table
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      }
    ]

    nsgs = [
      {
        name = "app-nsg-dev-sc"                                       # NSG Name
        security_rules = [
          {
            name                       = "Allow-HTTP"
            priority                   = 100                          # Priority (lower number = higher priority)
            direction                  = "Inbound"                    # Direction: Inbound or Outbound
            access                     = "Allow"                      # Access: Allow or Deny
            protocol                   = "Tcp"                        # Protocol: Tcp, Udp, or *
            source_port_range          = "*"                          # Source Port Range
            destination_port_range     = "80"                         # Destination Port Range
            source_address_prefix      = "*"                          # Source Address Prefix
            destination_address_prefix = "*"                          # Destination Address Prefix
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
      }
    ]

    route_tables = [
      {
        name   = "app-route-table-dev-sc"                            # Route Table Name
        routes = [
          {
            name           = "Internet"                               # Route Name
            address_prefix = "0.0.0.0/0"                              # Address Prefix
            next_hop_type  = "Internet"                               # Next Hop Type
          }
        ]
      }
    ]

    peerings = [
      {
        name                        = "dev-sc-to-dev-nc-peering"      # Peering Name
        remote_virtual_network_id   = "/subscriptions/YOUR_DEV_NC_SUBSCRIPTION_ID/resourceGroups/YOUR_DEV_NC_RG/providers/Microsoft.Network/virtualNetworks/orca-vnet-dev-nc" # Remote VNet ID
        allow_forwarded_traffic     = true                            # Allow Forwarded Traffic
        allow_virtual_network_access = true                            # Allow Virtual Network Access
        allow_gateway_transit       = false                           # Allow Gateway Transit
        use_remote_gateways         = false                           # Use Remote Gateways
      }
    ]
  }
]
```

---

## **3. Updated `prod.tfvars`**

This file contains configuration settings for the **Production** environment, covering both North Central and South Central VNets.

```hcl
# Production Environment Variable Definitions

# List of Virtual Networks
vnets = [
  {
    name                = "orca-vnet-prod-nc"                     # VNet Name in North Central
    address_space       = ["10.3.0.0/16"]                        # Address space for the VNet
    location            = "northcentralus"                       # Azure region
    resource_group_name = "rg-orca-prod-nc"                       # Resource Group

    dns_servers         = ["10.4.0.4", "10.4.0.5"]               # Custom DNS server IPs
    enable_ddos_protection = false                                # DDoS Protection
    enable_vm_protection   = false                                # VM Protection

    subnets = [
      {
        name               = "app-subnet-prod-nc"                  # App Subnet Name
        address_prefixes   = ["10.3.1.0/24"]                       # CIDR for App Subnet
        nsg_name           = "app-nsg-prod-nc"                      # NSG for App Subnet
        route_table_name   = "app-route-table-prod-nc"              # Route Table for App Subnet
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      },
      {
        name               = "GatewaySubnet"                       # Gateway Subnet Name (standard)
        address_prefixes   = ["10.3.254.0/27"]                      # CIDR for GatewaySubnet
        nsg_name           = null                                   # No NSG
        route_table_name   = null                                   # No Route Table
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      }
    ]

    nsgs = [
      {
        name = "app-nsg-prod-nc"                                       # NSG Name
        security_rules = [
          {
            name                       = "Allow-HTTP"
            priority                   = 100                          # Priority (lower number = higher priority)
            direction                  = "Inbound"                    # Direction: Inbound or Outbound
            access                     = "Allow"                      # Access: Allow or Deny
            protocol                   = "Tcp"                        # Protocol: Tcp, Udp, or *
            source_port_range          = "*"                          # Source Port Range
            destination_port_range     = "80"                         # Destination Port Range
            source_address_prefix      = "*"                          # Source Address Prefix
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
      }
    ]

    route_tables = [
      {
        name   = "app-route-table-prod-nc"                            # Route Table Name
        routes = [
          {
            name           = "Internet"                               # Route Name
            address_prefix = "0.0.0.0/0"                              # Address Prefix
            next_hop_type  = "Internet"                               # Next Hop Type
          }
        ]
      }
    ]

    peerings = [
      {
        name                        = "prod-nc-to-prod-sc-peering"      # Peering Name
        remote_virtual_network_id   = "/subscriptions/YOUR_PROD_SC_SUBSCRIPTION_ID/resourceGroups/YOUR_PROD_SC_RG/providers/Microsoft.Network/virtualNetworks/orca-vnet-prod-sc" # Remote VNet ID
        allow_forwarded_traffic     = true                            # Allow Forwarded Traffic
        allow_virtual_network_access = true                            # Allow Virtual Network Access
        allow_gateway_transit       = false                           # Allow Gateway Transit
        use_remote_gateways         = false                           # Use Remote Gateways
      }
    ]
  },

  {
    name                = "orca-vnet-prod-sc"                     # VNet Name in South Central
    address_space       = ["10.4.0.0/16"]                        # Address space for the VNet
    location            = "southcentralus"                       # Azure region
    resource_group_name = "rg-orca-prod-sc"                       # Resource Group

    dns_servers         = ["10.5.0.4", "10.5.0.5"]               # Custom DNS server IPs
    enable_ddos_protection = false                                # DDoS Protection
    enable_vm_protection   = false                                # VM Protection

    subnets = [
      {
        name               = "app-subnet-prod-sc"                  # App Subnet Name
        address_prefixes   = ["10.4.1.0/24"]                       # CIDR for App Subnet
        nsg_name           = "app-nsg-prod-sc"                      # NSG for App Subnet
        route_table_name   = "app-route-table-prod-sc"              # Route Table for App Subnet
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      },
      {
        name               = "GatewaySubnet"                       # Gateway Subnet Name (standard)
        address_prefixes   = ["10.4.254.0/27"]                      # CIDR for GatewaySubnet
        nsg_name           = null                                   # No NSG
        route_table_name   = null                                   # No Route Table
        delegations        = []                                     # Service Delegations (if any)
        service_endpoints  = []                                     # Service Endpoints (if any)
      }
    ]

    nsgs = [
      {
        name = "app-nsg-prod-sc"                                       # NSG Name
        security_rules = [
          {
            name                       = "Allow-HTTP"
            priority                   = 100                          # Priority (lower number = higher priority)
            direction                  = "Inbound"                    # Direction: Inbound or Outbound
            access                     = "Allow"                      # Access: Allow or Deny
            protocol                   = "Tcp"                        # Protocol: Tcp, Udp, or *
            source_port_range          = "*"                          # Source Port Range
            destination_port_range     = "80"                         # Destination Port Range
            source_address_prefix      = "*"                          # Source Address Prefix
            destination_address_prefix = "*"                          # Destination Address Prefix
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
      }
    ]

    route_tables = [
      {
        name   = "app-route-table-prod-sc"                            # Route Table Name
        routes = [
          {
            name           = "Internet"                               # Route Name
            address_prefix = "0.0.0.0/0"                              # Address Prefix
            next_hop_type  = "Internet"                               # Next Hop Type
          }
        ]
      }
    ]

    peerings = [
      {
        name                        = "prod-sc-to-prod-nc-peering"      # Peering Name
        remote_virtual_network_id   = "/subscriptions/YOUR_PROD_NC_SUBSCRIPTION_ID/resourceGroups/YOUR_PROD_NC_RG/providers/Microsoft.Network/virtualNetworks/orca-vnet-prod-nc" # Remote VNet ID
        allow_forwarded_traffic     = true                            # Allow Forwarded Traffic
        allow_virtual_network_access = true                            # Allow Virtual Network Access
        allow_gateway_transit       = false                           # Allow Gateway Transit
        use_remote_gateways         = false                           # Use Remote Gateways
      }
    ]
  }
]
```

---

## **4. Instructions for Customization**

### **a. Replace Placeholder Values**

Both `dev.tfvars` and `prod.tfvars` contain placeholders that you need to replace with your actual infrastructure details:

- **Subscription IDs & Resource Groups:**
  - **`YOUR_DEV_SC_SUBSCRIPTION_ID`**: Replace with your Development South Central Subscription ID.
  - **`YOUR_DEV_SC_RG`**: Replace with your Development South Central Resource Group name.
  - **`YOUR_DEV_NC_SUBSCRIPTION_ID`**: Replace with your Development North Central Subscription ID.
  - **`YOUR_DEV_NC_RG`**: Replace with your Development North Central Resource Group name.
  - **`YOUR_PROD_SC_SUBSCRIPTION_ID`**: Replace with your Production South Central Subscription ID.
  - **`YOUR_PROD_SC_RG`**: Replace with your Production South Central Resource Group name.
  - **`YOUR_PROD_NC_SUBSCRIPTION_ID`**: Replace with your Production North Central Subscription ID.
  - **`YOUR_PROD_NC_RG`**: Replace with your Production North Central Resource Group name.

### **b. Adjust Network Configurations**

- **VNet Names and Address Spaces:**
  - Ensure that `vnet_name` and `address_space` do not overlap with existing VNets.
  
- **Subnets:**
  - **App Subnets**: Defined with `/24` CIDR blocks, associated with NSGs and Route Tables.
  - **GatewaySubnets**: Defined with `/27` CIDR blocks, no NSGs or Route Tables.

- **Network Security Groups (NSGs):**
  - Verify that NSG names (`app-nsg-dev-nc`, `app-nsg-dev-sc`, etc.) are unique and correspond to the correct subnets.

- **Route Tables:**
  - Ensure that Route Tables (`app-route-table-dev-nc`, `app-route-table-dev-sc`, etc.) are correctly defined and associated with the App Subnets.

### **c. Peering Configurations**

- **Remote VNet IDs:**
  - Use Azure CLI or Portal to retrieve the full resource IDs of the remote VNets you wish to peer with.
  
  **Example Azure CLI Command:**
  ```bash
  az network vnet show --resource-group YOUR_REMOTE_RG --name YOUR_REMOTE_VNET --query id --output tsv
  ```

- **Peering Names:**
  - Use descriptive names to easily identify peering relationships.

### **d. Delegations and Service Endpoints**

- **Service Delegations:**
  - If your App Subnets require service delegations (e.g., for Azure Kubernetes Service), define them within the `delegations` field.

- **Service Endpoints:**
  - Specify any Azure services that should have service endpoints enabled for the App Subnets.

### **e. DDoS and VM Protection**

- Set `enable_ddos_protection` and `enable_vm_protection` to `true` if required.

---

## **5. Example Terraform Configuration Adjustments**

To handle multiple VNets as defined in the `tfvars` files, ensure that your Terraform configuration is set up to iterate over the `vnets` list. Here's an example of how you might adjust your `main.tf` to accommodate multiple VNets:

```hcl
# terraform-azurerm-orca/orca/main.tf

# Iterate over each VNet defined in the tfvars
module "vnets" {
  source              = "../../azure-tf-modules/terraform-azurerm-vnet"
  for_each            = { for vnet in var.vnets : vnet.name => vnet }
  name                = each.value.name
  address_space       = each.value.address_space
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  dns_servers              = each.value.dns_servers
  enable_ddos_protection   = each.value.enable_ddos_protection
  enable_vm_protection     = each.value.enable_vm_protection

  peerings = each.value.peerings
}

# Iterate over each VNet's subnets
module "subnets" {
  source               = "../../azure-tf-modules/terraform-azurerm-subnet"
  for_each             = {
    for vnet in var.vnets :
    for subnet in vnet.subnets :
    "${vnet.name}-${subnet.name}" => {
      name                 = subnet.name
      resource_group_name  = vnet.resource_group_name
      virtual_network_name = module.vnets[vnet.name].name
      address_prefixes     = subnet.address_prefixes
      nsg_id               = subnet.nsg_name != null ? azurerm_network_security_group.this[subnet.nsg_name].id : null
      route_table_id       = subnet.route_table_name != null ? azurerm_route_table.this[subnet.route_table_name].id : null
      delegations          = subnet.delegations
      service_endpoints    = subnet.service_endpoints
    }
  }

  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
  address_prefixes     = each.value.address_prefixes
  nsg_id               = each.value.nsg_id
  route_table_id       = each.value.route_table_id
  delegations          = each.value.delegations
  service_endpoints    = each.value.service_endpoints
}

# Create Network Security Groups (NSGs) if any
resource "azurerm_network_security_group" "this" {
  for_each = {
    for vnet in var.vnets :
    for nsg in vnet.nsgs :
    nsg.name => nsg
  }

  name                = each.value.name
  location            = lookup({ for vnet in var.vnets : vnet.name => vnet.location }, each.key)
  resource_group_name = lookup({ for vnet in var.vnets : vnet.name => vnet.resource_group_name }, each.key)

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

# Create Route Tables if any
resource "azurerm_route_table" "this" {
  for_each = {
    for vnet in var.vnets :
    for rt in vnet.route_tables :
    rt.name => rt
  }

  name                = each.value.name
  location            = lookup({ for vnet in var.vnets : vnet.name => vnet.location }, each.key)
  resource_group_name = lookup({ for vnet in var.vnets : vnet.name => vnet.resource_group_name }, each.key)

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
```

**Note:** Ensure that your Terraform modules (`terraform-azurerm-vnet` and `terraform-azurerm-subnet`) are designed to handle multiple VNets and their respective subnets. The above configuration assumes that these modules can be instantiated multiple times using `for_each`.

---

## **6. Applying the Updated `tfvars` Files in Terraform**

Once you've customized your `dev.tfvars` and `prod.tfvars` files, you can proceed with the Terraform workflow to deploy your infrastructure.

### **a. Initialize Terraform**

Navigate to your Terraform configuration directory and initialize Terraform:

```bash
cd terraform/terraform-azurerm-orca/orca
terraform init
```

### **b. Validate Configuration**

Ensure that your configurations are syntactically correct:

```bash
terraform validate -var-file="env/dev.tfvars"  # For Development
terraform validate -var-file="env/prod.tfvars" # For Production
```

### **c. Plan Deployment**

Preview the changes Terraform will make:

```bash
terraform plan -var-file="env/dev.tfvars"  # For Development
terraform plan -var-file="env/prod.tfvars" # For Production
```

### **d. Apply Configuration**

Deploy the infrastructure:

```bash
terraform apply -var-file="env/dev.tfvars"  # For Development
terraform apply -var-file="env/prod.tfvars" # For Production
```

- **Review Changes:** Terraform will display the proposed changes.
- **Confirm Deployment:** Type `yes` to proceed with the deployment.

### **e. Verify Deployment**

After applying, verify that the resources are created as expected using the Azure Portal or Azure CLI.

---

## **7. Additional Recommendations**

### **a. Secure Sensitive Data**

- **Exclude from Version Control:**
  - Ensure that `*.tfvars` files are added to your `.gitignore` to prevent sensitive information from being committed to version control.

  ```gitignore
  # Ignore Terraform variable files
  *.tfvars
  ```

- **Use Environment Variables or Secret Managers:**
  - For highly sensitive data, consider using environment variables or Azure Key Vault integrated with Terraform.

### **b. State Management**

- **Backend Configuration:**
  - Ensure that your `backend.tf` is correctly configured to store Terraform state securely, preferably in Azure Blob Storage with proper access controls.

### **c. Modular Design**

- **Reusable Modules:**
  - Leverage Terraform modules to promote reusability and maintainability across different environments.

### **d. Documentation**

- **Maintain Clear Documentation:**
  - Keep documentation up-to-date to facilitate onboarding and maintenance. This includes details about variable configurations, network design, and security policies.

### **e. Testing**

- **Test in Development First:**
  - Always deploy and test your configurations in the Development environment before applying them to Production to identify and rectify any issues.

### **f. Monitoring and Alerts**

- **Implement Monitoring:**
  - Set up Azure Monitor and Log Analytics to track the health and performance of your infrastructure.

- **Configure Alerts:**
  - Configure alerts for critical metrics to ensure timely responses to potential issues.

---

## **8. Final Checklist**

Before deploying, verify that you have gathered and correctly filled in the following details:

- **Subscription and Resource Groups:**
  - Subscription IDs for all VNets.
  - Resource Group names.

- **VNet Details:**
  - VNet names and address spaces.
  - Locations (North Central and South Central).

- **Subnets:**
  - App Subnet names and CIDR blocks (/24).
  - GatewaySubnet (standard naming) and CIDR blocks (/27).
  - Ensure GatewaySubnet has no NSGs and route tables.

- **Network Security Groups and Route Tables:**
  - NSG names and security rules for App Subnets.
  - Route Table names and routes for App Subnets.

- **Peering:**
  - Peering names and remote VNet IDs.

- **DNS Servers:**
  - Custom DNS server IPs.

- **Protections:**
  - DDoS and VM protection settings.

Ensure that all these configurations align with your organization's networking policies and architecture requirements.

---

## **Conclusion**

By updating your `dev.tfvars` and `prod.tfvars` files as shown above, you can effectively manage multiple VNets across different Azure regions and environments. This setup ensures that each VNet has an App Subnet with appropriate NSGs and Route Tables, as well as a GatewaySubnet without NSGs and Route Tables, aligning with your specified infrastructure requirements.

**Next Steps:**

1. **Customize the `tfvars` Files:**
   - Replace all placeholder values with your actual Azure resource details.

2. **Adjust Terraform Configuration:**
   - Ensure your Terraform modules are designed to handle multiple VNets.
   - Modify `main.tf` and `variables.tf` as necessary to support the `vnets` list.

3. **Initialize and Deploy:**
   - Follow the Terraform workflow to initialize, validate, plan, and apply your configurations.

4. **Verify and Monitor:**
   - After deployment, verify the infrastructure via the Azure Portal or CLI.
   - Set up monitoring and alerts to maintain infrastructure health.

