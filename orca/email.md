Below is a **detailed email** you might send to your network or cloud infrastructure team to outline everything needed to stand up the Orca Security environments (Dev and Prod) in Azure, including VNet/subnet creation, NSGs, route table configurations, and DNS settings—along with how they’ll communicate with the target Azure subscriptions via the hub subscription.

---

**Subject:** Infrastructure Requirements for Orca SideScanning (Dev & Prod) in Azure

**Hello [Team / Name],**

I hope you are doing well. I’m reaching out to request the creation and configuration of the necessary Azure infrastructure for our **Orca SideScanning** deployments in both **Dev** and **Prod** environments. Below is an overview of the requirements, along with a breakdown of the specific VNets, subnets, route tables, and NSGs we need.

---

### 1. **Subscriptions & Regions**

We currently have the following **Orca**-specific Azure subscriptions:
- **Orca Dev Subscription**  
- **Orca Prod Subscription**

Within each subscription, we need to set up VNets in **North Central** and **South Central** regions as follows:

1. **Orca North Central Prod**  
   - **VNet**: `Orca-NC-Prod-VNet`  
   - **Subnets**:  
     - `Orca-NC-Prod-App-Subnet`  
     - `Orca-NC-Prod-Gateway-Subnet`  

2. **Orca North Central Dev**  
   - **VNet**: `Orca-NC-Dev-VNet`  
   - **Subnets**:  
     - `Orca-NC-Dev-App-Subnet`  
     - `Orca-NC-Dev-Gateway-Subnet`  

3. **Orca South Central Prod**  
   - **VNet**: `Orca-SC-Prod-VNet`  
   - **Subnets**:  
     - `Orca-SC-Prod-App-Subnet`  
     - `Orca-SC-Prod-Gateway-Subnet`  

4. **Orca South Central Dev**  
   - **VNet**: `Orca-SC-Dev-VNet`  
   - **Subnets**:  
     - `Orca-SC-Dev-App-Subnet`  
     - `Orca-SC-Dev-Gateway-Subnet`  

*(Note: The above names are samples; please adjust to match any existing naming conventions.)*

---

### 2. **Hub Subscription & VNet Peering**

Each of these VNets (Dev and Prod, across regions) should be **peered** with our **Hub VNet** in the **Hub Subscription**. This will allow:
- The Orca side scanner environment (in the Orca subscriptions) to communicate with the **target Azure subscriptions** via the hub-and-spoke model.
- Routing of traffic through our centralized services (e.g., firewalls, NVA, or Azure Firewall) if applicable.

**Action Items**:
- Configure **VNet peering** between each Orca VNet (`Orca-NC-Prod-VNet`, `Orca-NC-Dev-VNet`, `Orca-SC-Prod-VNet`, `Orca-SC-Dev-VNet`) and the **Hub VNet**.  
- Ensure the correct **allow-forwarded-traffic** and **allow-gateway-transit** settings, depending on the design (especially if we’re leveraging a central gateway for ExpressRoute or VPN).

---

### 3. **Route Tables & Network Security Groups (NSGs)**

**Route Tables**:
- We’ll need custom route tables if we’re forcing traffic to on-prem or to specific IP ranges.  
- In particular, we must confirm that traffic from the Orca VNets can reach:
  - **On-prem datacenter** (via ExpressRoute or VPN).
  - **AWS environment** (private endpoints for S3 or any other needed endpoints).

**Network Security Groups (NSGs)**:
- We will assign NSGs to each **App Subnet** and **Gateway Subnet** to control inbound/outbound flows.
- Outbound traffic must be allowed on **TCP 443** (HTTPS) to our on-prem private endpoints or to AWS S3 endpoints (if required).
- Inbound rules for the **Gateway Subnet** might vary depending on whether we’re using Azure VPN gateways or only ExpressRoute gateways.

---

### 4. **Custom DNS Servers**

We have **custom DNS servers** (on-prem or in another subscription) that the Orca subnets must use for DNS resolution. This ensures that domain names (e.g., `s3.amazonaws.com`) can resolve to **private IP addresses** within our AWS VPC via PrivateLink.

**Key Points**:
1. Configure **Azure VNet DNS Settings** so that each VNet (Dev and Prod) points to our **on-prem custom DNS** servers rather than default Azure DNS.  
2. Ensure **DNS forwarding** is properly set up so that queries for AWS domains route to the private endpoints, enabling private connectivity.

---

### 5. **End-to-End Traffic Flow**

Here’s the high-level flow we want:

1. **Orca Dev/Prod VMs or Azure Functions** in `Orca-NC-Dev/Prod-VNet` or `Orca-SC-Dev/Prod-VNet` need to communicate with:
   - **Target Azure Subscriptions**: via **Hub Subscription** (peering).
   - **AWS (S3)**: via on-prem datacenter (ExpressRoute) to AWS direct connect (or whatever private link we have in place).

2. **Data Path**:  
   - **Azure (Orca Subscriptions)** → **Hub VNet** → **ExpressRoute** → **On-Prem Datacenter** → **AWS** (PrivateLink endpoint for S3).  
   - DNS resolution ensures `s3.amazonaws.com` (etc.) resolves to private IP addresses in AWS.

3. **Orca Access**:  
   - Orca’s scanning environment will store or retrieve data from our private AWS S3 bucket, and Orca has external trust to read from that bucket.

---

### 6. **Request & Next Steps**

1. **Create the VNets & Subnets** as listed (Dev & Prod in North Central and South Central).  
2. **Configure VNet Peerings** to the Hub VNet, ensuring correct gateway and forwarding settings.  
3. **Set Up NSGs & Route Tables** to allow required outbound/inbound traffic.  
   - Specifically, confirm outbound 443 to on-prem & AWS is permitted.  
4. **Apply Custom DNS Servers** to each Orca VNet so they use on-prem DNS for name resolution.  
5. **Validate Connectivity** by performing test lookups (DNS queries) and pings/tracers to the on-prem and AWS private endpoints.  

Once these are complete, I’ll proceed with installing/configuring the Orca side scanner components in the Dev and Prod subscriptions. If you have any questions or need further clarification on IP ranges, naming conventions, or security constraints, please let me know.

**Thank you for your support, and I look forward to working with you on this.**

---

**Best Regards,**  
[Your Name]  
[Your Title / Team]  
[Contact Information]
