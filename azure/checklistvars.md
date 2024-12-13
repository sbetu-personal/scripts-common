
---

## **1. `dev.tfvars`**

This file contains configuration settings for your **Development** environment with an **App Subnet** and a **GatewaySubnet**.

```hcl
# Development Environment Variable Definitions

# Virtual Network (VNet) Configuration
vnet_name            = "orca-vnet-dev"                       # Name of the Virtual Network
address_space        = ["10.0.0.0/16"]                       # Address space for the VNet
location             = "eastus"                              # Azure region for deployment
resource_group_name  = "rg-orca-dev"                         # Name of the Resource Group

dns_servers          = ["10.1.0.4", "10.1.0.5"]              # Custom DNS server IPs
enable_ddos_protection = false                                # Enable/Disable DDoS Protection
enable_vm_protection   = false                                # Enable/Disable VM Protection

# Subnets Configuration
subnets = [
  {
    name               = "app-subnet-dev"                       # Name of the App Subnet
    address_prefixes   = ["10.0.1.0/24"]                        # CIDR block for the App Subnet
    nsg_name           = "app-nsg-dev"                          # Associated NSG name for App Subnet
    route_table_name   = "app-route-table-dev"                  # Associated Route Table name for App Subnet
    delegations        = []                                      # Service delegations (if any)
    service_endpoints  = []                                      # Service endpoints (if any)
  },
  {
    name               = "GatewaySubnet"                        # Name of the GatewaySubnet (standard naming)
    address_prefixes   = ["10.0.254.0/24"]                      # CIDR block for the GatewaySubnet
    nsg_name           = "gateway-nsg-dev"                      # Associated NSG name for GatewaySubnet
    route_table_name   = "gateway-route-table-dev"              # Associated Route Table name for GatewaySubnet
    delegations        = [
      {
        name = "GatewayDelegation"
        service_delegation = {
          name    = "Microsoft.Network/expressRouteGateways"  # Example delegation
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    ]
    service_endpoints  = ["Microsoft.Storage", "Microsoft.Sql"]  # Example service endpoints
  }
]

# Network Security Groups (NSGs) Configuration
nsgs = [
  {
    name = "app-nsg-dev"                                         # NSG Name for App Subnet
    security_rules = [
      {
        name                       = "Allow-HTTP"                 # Rule Name
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
  },
  {
    name = "gateway-nsg-dev"                                     # NSG Name for GatewaySubnet
    security_rules = [
      {
        name                       = "Allow-Any-Inbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
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
    name   = "app-route-table-dev"                                # Route Table Name for App Subnet
    routes = [
      {
        name           = "Internet"                               # Route Name
        address_prefix = "0.0.0.0/0"                              # Address Prefix for the Route
        next_hop_type  = "Internet"                               # Next Hop Type (e.g., Internet, Virtual Network)
      }
    ]
  },
  {
    name   = "gateway-route-table-dev"                            # Route Table Name for GatewaySubnet
    routes = [
      {
        name           = "Internet"                               # Route Name
        address_prefix = "0.0.0.0/0"                              # Address Prefix for the Route
        next_hop_type  = "Internet"                               # Next Hop Type
      },
      {
        name           = "ExpressRoute"                           # Example additional route
        address_prefix = "10.2.0.0/16"                            # Example address prefix
        next_hop_type  = "VirtualAppliance"                       # Example next hop type
        next_hop_in_ip_address = "10.0.254.4"                     # Example next hop IP
      }
    ]
  }
]

# Peering Information
peerings = [
  {
    name                        = "orca-to-hub-peering-dev"           # Peering Name
    remote_virtual_network_id   = "/subscriptions/YOUR_HUB_SUBSCRIPTION_ID/resourceGroups/YOUR_HUB_RG/providers/Microsoft.Network/virtualNetworks/hub-vnet" # Remote VNet ID
    allow_forwarded_traffic     = true                                # Allow Forwarded Traffic
    allow_virtual_network_access = true                                # Allow Virtual Network Access
    allow_gateway_transit       = false                               # Allow Gateway Transit
    use_remote_gateways         = false                               # Use Remote Gateways
  }
]
```

---

## **2. `prod.tfvars`**

This file contains configuration settings for your **Production** environment with an **App Subnet** and a **GatewaySubnet**.

```hcl
# Production Environment Variable Definitions

# Virtual Network (VNet) Configuration
vnet_name            = "orca-vnet-prod"                       # Name of the Virtual Network
address_space        = ["10.1.0.0/16"]                         # Address space for the VNet
location             = "eastus"                                # Azure region for deployment
resource_group_name  = "rg-orca-prod"                          # Name of the Resource Group

dns_servers          = ["10.2.0.4", "10.2.0.5"]                # Custom DNS server IPs
enable_ddos_protection = false                                # Enable/Disable DDoS Protection
enable_vm_protection   = false                                # Enable/Disable VM Protection

# Subnets Configuration
subnets = [
  {
    name               = "app-subnet-prod"                      # Name of the App Subnet
    address_prefixes   = ["10.1.1.0/24"]                        # CIDR block for the App Subnet
    nsg_name           = "app-nsg-prod"                         # Associated NSG name for App Subnet
    route_table_name   = "app-route-table-prod"                 # Associated Route Table name for App Subnet
    delegations        = []                                      # Service delegations (if any)
    service_endpoints  = []                                      # Service endpoints (if any)
  },
  {
    name               = "GatewaySubnet"                        # Name of the GatewaySubnet (standard naming)
    address_prefixes   = ["10.1.254.0/24"]                      # CIDR block for the GatewaySubnet
    nsg_name           = "gateway-nsg-prod"                     # Associated NSG name for GatewaySubnet
    route_table_name   = "gateway-route-table-prod"             # Associated Route Table name for GatewaySubnet
    delegations        = [
      {
        name = "GatewayDelegation"
        service_delegation = {
          name    = "Microsoft.Network/expressRouteGateways"  # Example delegation
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    ]
    service_endpoints  = ["Microsoft.Storage", "Microsoft.Sql"]  # Example service endpoints
  }
]

# Network Security Groups (NSGs) Configuration
nsgs = [
  {
    name = "app-nsg-prod"                                         # NSG Name for App Subnet
    security_rules = [
      {
        name                       = "Allow-HTTP"                 # Rule Name
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
  },
  {
    name = "gateway-nsg-prod"                                     # NSG Name for GatewaySubnet
    security_rules = [
      {
        name                       = "Allow-Any-Inbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
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
    name   = "app-route-table-prod"                                # Route Table Name for App Subnet
    routes = [
      {
        name           = "Internet"                               # Route Name
        address_prefix = "0.0.0.0/0"                              # Address Prefix for the Route
        next_hop_type  = "Internet"                               # Next Hop Type (e.g., Internet, Virtual Network)
      }
    ]
  },
  {
    name   = "gateway-route-table-prod"                            # Route Table Name for GatewaySubnet
    routes = [
      {
        name           = "Internet"                               # Route Name
        address_prefix = "0.0.0.0/0"                              # Address Prefix for the Route
        next_hop_type  = "Internet"                               # Next Hop Type
      },
      {
        name           = "ExpressRoute"                           # Example additional route
        address_prefix = "10.2.0.0/16"                            # Example address prefix
        next_hop_type  = "VirtualAppliance"                       # Example next hop type
        next_hop_in_ip_address = "10.1.254.4"                     # Example next hop IP
      }
    ]
  }
]

# Peering Information
peerings = [
  {
    name                        = "orca-to-hub-peering-prod"          # Peering Name
    remote_virtual_network_id   = "/subscriptions/YOUR_HUB_SUBSCRIPTION_ID/resourceGroups/YOUR_HUB_RG/providers/Microsoft.Network/virtualNetworks/hub-vnet" # Remote VNet ID
    allow_forwarded_traffic     = true                                # Allow Forwarded Traffic
    allow_virtual_network_access = true                                # Allow Virtual Network Access
    allow_gateway_transit       = false                               # Allow Gateway Transit
    use_remote_gateways         = false                               # Use Remote Gateways
  }
]
```

---

## **3. Summary of Changes**

1. **Subnets:**
   - **Removed:**
     - `collector-subnet-dev` from `dev.tfvars`
     - `collector-subnet-prod` from `prod.tfvars`
   - **Added:**
     - `app-subnet-dev` and `GatewaySubnet` in `dev.tfvars`
     - `app-subnet-prod` and `GatewaySubnet` in `prod.tfvars`

2. **Network Security Groups (NSGs):**
   - Adjusted to include NSGs for `app-subnet` and `GatewaySubnet` only.

3. **Route Tables:**
   - Associated route tables now correspond to `app-subnet` and `GatewaySubnet`.

4. **Peering Information:**
   - Remains the same but ensure that the `remote_virtual_network_id` points to the correct Hub VNet.

5. **Delegations and Service Endpoints:**
   - Added example delegations and service endpoints for `GatewaySubnet`. Modify these as per your actual requirements.

---

## **4. Instructions for Customization**

### **a. Replace Placeholder Values**

Both `dev.tfvars` and `prod.tfvars` contain placeholders that need to be replaced with your actual infrastructure details:

- **Hub Subscription ID & Resource Group:**
  - **`YOUR_HUB_SUBSCRIPTION_ID`**: Replace with your actual Hub Azure Subscription ID.
  - **`YOUR_HUB_RG`**: Replace with the name of the Resource Group in your Hub subscription that contains the `hub-vnet`.

### **b. Customize Network Configurations**

- **VNet Names and Address Spaces:**
  - Ensure that the `vnet_name` and `address_space` align with your network design and do not overlap with existing VNets.

- **Subnets:**
  - Update `name`, `address_prefixes`, `nsg_name`, and `route_table_name` for each subnet to match your requirements.
  - If you have specific service delegations or service endpoints, populate the `delegations` and `service_endpoints` fields accordingly.

- **Network Security Groups (NSGs):**
  - Review and adjust the `security_rules` to fit your security policies.
  - Ensure that the `nsg_name` corresponds to the NSG configurations you intend to use.

- **Route Tables:**
  - Define the necessary routes in `route_tables`. The example includes a default route to the Internet and an example for ExpressRoute.
  - Modify or add routes based on your routing requirements.

### **c. Peering**

- **Peering Configuration:**
  - Ensure that the `remote_virtual_network_id` accurately points to the VNet you wish to peer with.
  - Adjust the peering settings (`allow_forwarded_traffic`, `allow_virtual_network_access`, etc.) as per your network design.

### **d. DDoS and VM Protection**

- **Enable Protections:**
  - If your environment requires DDoS or VM protection, set `enable_ddos_protection` and `enable_vm_protection` to `true`.

---

## **5. Applying the Updated `tfvars` Files in Terraform**

Once you've customized your `dev.tfvars` and `prod.tfvars` files, you can use them with Terraform commands to deploy your infrastructure.

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

## **6. Additional Recommendations**

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

## **7. Example Peering Configuration**

Ensure that the `remote_virtual_network_id` in your `peerings` section is accurate. Here's how you can retrieve it using Azure CLI:

```bash
az network vnet show --resource-group YOUR_REMOTE_RG --name YOUR_REMOTE_VNET --query id --output tsv
```

Replace `YOUR_REMOTE_RG` and `YOUR_REMOTE_VNET` with the appropriate Resource Group and VNet names.

---

## **8. Contact and Support**

If you encounter any issues or need further assistance:

- **Contact Your Network Team:**
  - Ensure that your network team provides the necessary details and permissions for peering and resource access.
  
- **Vendor Support:**
  - Reach out to your Orca vendor for any specific configurations or support related to their services.

---

By updating your `tfvars` files as shown above, you align your Terraform configurations with your actual infrastructure requirements—utilizing an **App Subnet** and a **GatewaySubnet** instead of a Collector Subnet. Ensure that all placeholder values are correctly replaced with your actual Azure details before applying the configurations.

If you have any further adjustments or questions, feel free to ask!
