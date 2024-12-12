Certainly! Setting up your Azure infrastructure for the Orca project using Terraform requires comprehensive information to ensure all components are correctly configured and integrated. Below is a detailed list of the required details you should gather from your Orca vendor and network team. This list is organized into categories for clarity and ease of reference.

---

## **1. General Information**
- **Project Name**: A unique identifier for the infrastructure deployment.
- **Azure Subscription IDs**:
  - **Hub Subscription**: Confirm the subscription ID, resource group, and permissions.
  - **Spoke/Sub-Subscriptions**: Any additional subscriptions involved.
- **Resource Group Names**: Names of existing or intended Azure Resource Groups for organizing resources.
- **Azure Region/Location**: The Azure regions where resources will be deployed (e.g., East US, West Europe).

---

## **2. Virtual Network (VNet) Details**
- **VNet Name**: The desired name for the Virtual Network (e.g., `orca-vnet-dev`, `orca-vnet-prod`).
- **Address Space (CIDR Blocks)**: The IP address range for the VNet (e.g., `10.0.0.0/16`).
- **DNS Servers**:
  - **Custom DNS Server IPs**: IP addresses of custom DNS servers (e.g., `10.1.0.4`, `10.1.0.5`).
  - **DNS Zones**: Information about any internal DNS zones if applicable.
- **DDoS Protection**:
  - **Enabled/Disabled**: Whether DDoS protection is enabled.
  - **Protection Plan**: Basic or Standard.
- **VM Protection**:
  - **Enabled/Disabled**: Whether VM protection is enabled.

---

## **3. Subnet Details**
For each subnet within the VNet:
- **Subnet Name**: Unique name for each subnet (e.g., `orca-subnet-dev`, `collector-subnet-prod`).
- **Address Prefix (CIDR Block)**: IP range for the subnet (e.g., `10.0.1.0/24`).
- **Network Security Group (NSG) Name**: The NSG to associate with the subnet.
- **Route Table Name**: The Route Table to associate with the subnet.
- **Delegations**:
  - **Service Delegations**: Any service delegations required (e.g., Azure Kubernetes Service).
- **Service Endpoints**: Specific Azure services enabled for the subnet (e.g., `Microsoft.Storage`, `Microsoft.Sql`).

---

## **4. DNS Configuration**
- **DNS Server IPs**: IP addresses of DNS servers used by the VNet.
- **DNS Zones**: Details about any internal DNS zones or configurations.

---

## **5. Network Security Groups (NSGs)**
For each NSG:
- **NSG Name**: Unique name for the NSG (e.g., `orca-nsg-dev`, `collector-nsg-prod`).
- **Security Rules**:
  - **Rule Name**: Descriptive name for each rule (e.g., `Allow-HTTP`, `Deny-All`).
  - **Priority**: Determines the order of rule application (lower numbers have higher priority).
  - **Direction**: Inbound or Outbound.
  - **Access**: Allow or Deny.
  - **Protocol**: TCP, UDP, or `*` for all.
  - **Source Port Range**: Port range for incoming traffic.
  - **Destination Port Range**: Port range for outgoing traffic.
  - **Source Address Prefix**: IP ranges or `*` for all.
  - **Destination Address Prefix**: IP ranges or `*` for all.
- **Associated Subnets or NICs**: Which subnets or network interfaces the NSG is associated with.

---

## **6. Route Tables**
For each Route Table:
- **Route Table Name**: Unique name (e.g., `orca-route-table-dev`, `collector-route-table-prod`).
- **Routes**:
  - **Route Name**: Descriptive name for each route (e.g., `Internet`).
  - **Address Prefix**: Destination CIDR block (e.g., `0.0.0.0/0` for Internet).
  - **Next Hop Type**: Type of next hop (e.g., `Internet`, `Virtual Network`, `Virtual Appliance`).
  - **Next Hop IP Address**: If applicable, the IP address for the next hop.
- **Associated Subnets**: Which subnets are using the Route Table.

---

## **7. Peering Information**
For each VNet peering:
- **Peering Name**: Unique name for the peering connection (e.g., `orca-to-hub-peering-dev`).
- **Remote VNet ID**: The full Azure resource ID of the VNet to peer with.
- **Peering Settings**:
  - **Allow Forwarded Traffic**: `true` or `false`.
  - **Allow Virtual Network Access**: `true` or `false`.
  - **Allow Gateway Transit**: `true` or `false`.
  - **Use Remote Gateways**: `true` or `false`.
- **Subscription and Resource Group of Remote VNet**: Necessary for cross-subscription peerings.

---

## **8. Firewall Details**
- **Firewall Name**: If using Azure Firewall or another firewall service.
- **Firewall IP Addresses**:
  - **Public IP**: If applicable.
  - **Private IP**: Within the VNet.
- **Firewall Rules**:
  - **Inbound Rules**: Rules governing incoming traffic.
  - **Outbound Rules**: Rules governing outgoing traffic.
- **Associated Route Tables**: Route Tables directing traffic through the firewall.

---

## **9. DDoS Protection Settings**
- **DDoS Protection Plan**: Whether enabled and which plan (Basic or Standard).
- **Protected Resources**: VNets or specific resources under DDoS protection.
- **Metrics and Alerts**: Any monitoring or alerting configurations related to DDoS.

---

## **10. Azure Subscription Information**
- **Hub Subscription Confirmation**:
  - **Subscription ID**: To confirm and reference.
  - **Resource Group**: Name of the resource group in the Hub subscription.
- **Access Permissions**:
  - **Service Principal or Managed Identity**: Ensure it has necessary permissions.
  - **Role Assignments**: Roles assigned to manage resources across subscriptions.
- **Subscription Policies**: Any governance or compliance policies that need to be adhered to.

---

## **11. Other Networking Components**
- **Virtual Network Gateways**:
  - **Gateway SKU**: Size and capabilities (e.g., VpnGw1, VpnGw2).
  - **Gateway Type**: VPN or ExpressRoute.
  - **Gateway IP Configuration**: Details about IP configurations.
- **Public IP Addresses**:
  - **For Load Balancers, Firewalls, etc.**: IP details and usage.
- **Load Balancers**:
  - **Configuration Details**: Frontend IPs, backend pools, probes, and rules.
- **Application Gateways**:
  - **Configuration Details**: Listeners, backend pools, routing rules, and WAF settings.

---

## **12. Monitoring and Logging**
- **Log Analytics Workspace**: Details for Azure Monitor logs.
- **Network Watcher**: Ensure it's enabled in the regions used.
- **Diagnostic Settings**: Configurations for sending logs and metrics to Log Analytics, Event Hubs, or Storage Accounts.

---

## **13. Service Endpoints and Private Endpoints**
- **Enabled Services**: Specific Azure services for which service endpoints are enabled in subnets.
- **Private Endpoints**: Configuration details for services accessed via private endpoints (e.g., Azure SQL, Storage).

---

## **14. Tagging Strategy**
- **Resource Tags**: Key-value pairs for resources to aid in organization, billing, or management (e.g., `Environment: Dev`, `Owner: TeamA`).

---

## **15. Governance and Compliance**
- **Policies and Compliance Requirements**: Any specific requirements or policies the infrastructure must comply with.
- **Role-Based Access Control (RBAC)**: Roles and permissions for users and service principals.

---

## **16. High Availability and Redundancy**
- **Availability Zones**: Whether resources need to be deployed across availability zones.
- **Redundancy Plans**: Strategies for ensuring high availability (e.g., multiple instances of critical services).

---

## **17. Security and Access Controls**
- **Azure Active Directory (AAD) Integration**: If AAD is used for identity management.
- **Access Control Lists (ACLs)**: Any additional access controls required.
- **Encryption Requirements**: Data encryption in transit and at rest.

---

## **18. Naming Conventions**
- **Resource Naming Standards**: Guidelines for naming resources consistently (e.g., prefix/suffix conventions, abbreviations).

---

## **19. Existing Infrastructure**
- **Existing Resources**: Information about any pre-existing resources that need to be integrated or considered.
- **Integration Points**: Services or resources that will interact with the new infrastructure.

---

## **20. Support and Maintenance**
- **Support Contacts**: Who to contact for issues related to the infrastructure.
- **Maintenance Windows**: Scheduled maintenance periods, if any.

---

## **Checklist Summary**

To ensure you have all necessary information, here's a condensed checklist:

- [ ] **General Information**
  - Project name
  - Azure subscription IDs
  - Resource group names
  - Azure region/location

- [ ] **VNet Details**
  - VNet name
  - Address space (CIDR)
  - DNS servers
  - DDoS protection settings
  - VM protection settings

- [ ] **Subnets**
  - Subnet names
  - Address prefixes (CIDR)
  - NSG names
  - Route table names
  - Delegations
  - Service endpoints

- [ ] **DNS Configuration**
  - DNS server IPs
  - DNS zones

- [ ] **NSGs**
  - NSG names
  - Security rules details

- [ ] **Route Tables**
  - Route table names
  - Route details
  - Associated subnets

- [ ] **Peering Information**
  - Peering names
  - Remote VNet IDs
  - Peering settings

- [ ] **Firewall Details**
  - Firewall names and IPs
  - Firewall rules
  - Associated route tables

- [ ] **DDoS Protection**
  - DDoS protection plan
  - Protected resources

- [ ] **Azure Subscription**
  - Hub subscription confirmation
  - Access permissions
  - Subscription policies

- [ ] **Other Networking Components**
  - Virtual network gateways
  - Public IPs
  - Load balancers
  - Application gateways

- [ ] **Monitoring and Logging**
  - Log Analytics workspace
  - Network Watcher
  - Diagnostic settings

- [ ] **Service Endpoints and Private Endpoints**
  - Enabled services
  - Private endpoints details

- [ ] **Tagging Strategy**
  - Resource tags

- [ ] **Governance and Compliance**
  - Policies and compliance requirements
  - RBAC roles and permissions

- [ ] **High Availability**
  - Availability zones
  - Redundancy plans

- [ ] **Security and Access Controls**
  - AAD integration
  - ACLs
  - Encryption requirements

- [ ] **Naming Conventions**
  - Resource naming standards

- [ ] **Existing Infrastructure**
  - Existing resources
  - Integration points

- [ ] **Support and Maintenance**
  - Support contacts
  - Maintenance windows

---

## **Additional Tips**

- **Documentation**: Ensure all details are well-documented and accessible to the team responsible for deploying and maintaining the infrastructure.
- **Validation**: Double-check all CIDR ranges to avoid overlaps and ensure they fit within your overall network design.
- **Security**: Pay special attention to NSG and firewall configurations to secure your infrastructure effectively.
- **Automation**: Consider automating the collection of some of these details using scripts or Azure APIs if feasible.
- **Version Control**: Use Git or another version control system to track changes and collaborate with team members effectively.

---

## **Sample Questions to Ask Your Orca Vendor and Network Team**

1. **General Information**
   - What is the project name and unique identifier for this deployment?
   - Can you provide the Azure Subscription IDs for both Hub and any Spoke subscriptions?

2. **VNet Details**
   - What is the desired name for the Virtual Network?
   - What CIDR block should the VNet use?
   - Are there custom DNS servers we should configure? If so, what are their IP addresses?
   - Do we need to enable DDoS protection? If yes, which plan?

3. **Subnets**
   - What are the names and CIDR blocks for each subnet?
   - Which NSGs should be associated with each subnet?
   - Are there specific Route Tables to be linked with any subnet?
   - Do any subnets require service delegations or service endpoints?

4. **DNS Configuration**
   - Are there internal DNS zones we need to manage?
   - What are the IP addresses of the DNS servers?

5. **NSGs**
   - What are the security rules for each NSG (names, priorities, directions, access, protocols, ports, IP ranges)?
   - Which subnets or NICs should each NSG be associated with?

6. **Route Tables**
   - What are the routes for each Route Table (names, address prefixes, next hop types, IP addresses)?
   - Which subnets should each Route Table be associated with?

7. **Peering Information**
   - What are the details for VNet peerings (peering names, remote VNet IDs, peering settings)?
   - Are there cross-subscription peerings that need special configurations?

8. **Firewall Details**
   - Are we using Azure Firewall or another firewall service?
   - What are the public and private IP addresses for the firewall?
   - What are the inbound and outbound rules for the firewall?
   - Which Route Tables should direct traffic through the firewall?

9. **DDoS Protection**
   - Is DDoS protection enabled for the VNet? If so, which plan?
   - Which resources are protected under DDoS?

10. **Azure Subscription Information**
    - Can you confirm the Hub Subscription ID and associated Resource Group?
    - What permissions are required for the Terraform service principal or managed identity?
    - Are there any subscription policies we need to adhere to?

11. **Other Networking Components**
    - Do we need Virtual Network Gateways? If so, what are their configurations?
    - Are there any Load Balancers or Application Gateways? Please provide their details.

12. **Monitoring and Logging**
    - Do we have a Log Analytics Workspace set up for monitoring?
    - Is Network Watcher enabled in all relevant regions?
    - What diagnostic settings should be configured for resources?

13. **Service Endpoints and Private Endpoints**
    - Which Azure services should have service endpoints enabled in subnets?
    - Are there any Private Endpoints we need to configure? If so, for which services?

14. **Tagging Strategy**
    - What tagging conventions should we follow for resources?
    - Are there specific tags required for billing, ownership, or environment purposes?

15. **Governance and Compliance**
    - Are there specific compliance requirements the infrastructure must meet?
    - What RBAC roles and permissions need to be configured?

16. **High Availability and Redundancy**
    - Should resources be deployed across Availability Zones?
    - What redundancy measures are required for critical services?

17. **Security and Access Controls**
    - Is Azure Active Directory integration required?
    - Are there additional ACLs or security measures needed?
    - What are the encryption requirements for data in transit and at rest?

18. **Naming Conventions**
    - What are the standardized naming conventions for resources?
    - Are there any prefixes or suffixes that need to be used?

19. **Existing Infrastructure**
    - Are there any existing resources that need to be integrated?
    - What are the integration points with other services or resources?

20. **Support and Maintenance**
    - Who are the primary contacts for support related to the infrastructure?
    - Are there scheduled maintenance windows we need to be aware of?

---

## **Conclusion**

Gathering all the above information will provide a solid foundation for setting up your Azure infrastructure using Terraform. Ensure clear communication with your Orca vendor and network team to obtain accurate and comprehensive details. Proper planning and thorough information collection are crucial for a smooth and successful infrastructure deployment.

Feel free to reach out if you need further assistance or clarification on any of these points. Happy infrastructure building!
