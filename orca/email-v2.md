Below is an **updated, detailed email** that not only covers the **infrastructure requirements** but also includes a section asking for **clarification on whether Orca’s side scanning uses snapshots or only metadata** when sending data from Azure to AWS.

---

**Subject:** Infrastructure Requirements & Data Flow Clarification for Orca SideScanning (Dev & Prod) in Azure

**Hello [Team / Architect Name],**

I hope you’re doing well. I’m writing to confirm the **Azure infrastructure** setup for our **Orca SideScanning** (Dev and Prod) deployments and to clarify exactly **what data** (snapshots vs. metadata) flows from Azure to AWS.

---

### 1. **Subscriptions & Regions**

We currently have the following **Orca**-specific Azure subscriptions:  
- **Orca Dev Subscription**  
- **Orca Prod Subscription**

Within each subscription, we need VNets in **North Central** and **South Central** regions:

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

*(Please adjust names and IP ranges to fit our existing standards.)*

---

### 2. **VNet Peering via Hub Subscription**

Each of these VNets (Dev and Prod) should be **peered** with our **Hub VNet** in the **Hub Subscription**. This will let the Orca scanning environment communicate with:

- Our **target Azure subscriptions** (through the hub-and-spoke model).  
- Our **on-prem datacenter** (via ExpressRoute or VPN), allowing traffic to reach AWS privately.

**Action Items**:
- Set up **VNet peering** between each Orca VNet and the Hub VNet.  
- Enable the correct options (`AllowGatewayTransit`, `UseRemoteGateways`, etc.) if we’re leveraging a central gateway.

---

### 3. **Route Tables & Network Security Groups (NSGs)**

- **Route Tables**:  
  - Ensure that traffic destined for AWS or on-prem routes correctly through the hub or any firewall/NVA.  
  - If we’re forcing traffic to on-prem DNS or to a private AWS endpoint, we need the appropriate routes for 0.0.0.0/0 or specific IP blocks.

- **NSGs**:  
  - Assign an NSG to each **App Subnet** and **Gateway Subnet**.  
  - Outbound traffic (TCP 443) must be allowed to on-prem and AWS S3 endpoints.  
  - Inbound rules, if needed, for the gateway subnet will depend on whether we’re terminating VPN or just using ExpressRoute.

---

### 4. **Custom DNS Servers**

We have **on-prem custom DNS** that each Orca VNet must use to resolve certain domains (e.g., `s3.amazonaws.com`) to **private IP addresses** in AWS (via PrivateLink). 

**Key Points**:  
1. Configure each VNet’s DNS settings to use our on-prem DNS servers (not Azure’s default).  
2. Ensure our on-prem DNS has the correct forwarders/records to resolve AWS endpoints privately.

---

### 5. **End-to-End Traffic Flow**

The planned path for Orca side scanning data is:

1. **Azure (Orca Dev/Prod)** → **Hub VNet** → **ExpressRoute** → **On-Prem Datacenter** → **AWS** (PrivateLink endpoint, S3).  
2. DNS queries for S3 will resolve to a private IP, ensuring no public internet usage.

Once data is in **our** AWS S3 bucket (Dev or Prod), Orca can read it via external trust.  

---

### 6. **Clarification: Snapshots vs. Metadata**

Based on Orca’s documentation, **SideScanning** generally collects **partial disk snapshots (raw blocks)** or at least some disk-level data. However, I’ve heard internally that we might only be sending **metadata** from Azure to AWS. 

- **Could you please confirm** if we’re leveraging the default Orca approach (which typically includes disk snapshots or partial block data) or if there’s a custom configuration that sends only metadata?  
- If we’re indeed sending snapshots or partial disk blocks, we need to ensure our network can handle that traffic volume. Conversely, if it’s strictly metadata, that’s a lighter load.

Your guidance on this will help us size the connectivity and validate the correct data flow.

---

### 7. **Next Steps & Questions**

1. **VNet Creation & Configuration**: Please proceed with creating the VNets, subnets, route tables, and NSGs as described.  
2. **Peering**: Implement peering to the Hub VNet and confirm the correct route paths.  
3. **Custom DNS**: Set or verify custom DNS for the Orca VNets.  
4. **Data Flow Confirmation**:  
   - If the SideScanning process includes disk snapshots, we must confirm there are no bandwidth or firewall constraints.  
   - If only metadata is sent, that’s simpler, but we need explicit confirmation.  

Please let me know if you need any additional details—IP address ranges, naming conventions, or security/compliance requirements. I appreciate your assistance in ensuring this environment is configured correctly so we can finalize our Orca Security integration.

**Thank you, and I look forward to your feedback.**

---

**Best Regards,**  
[Your Name]  
[Your Title / Team]  
[Contact Information]
