Below is an **updated email** that incorporates the **metadata-only** scanning confirmation, the **hub network and private endpoint** routing requirements, and a request for **route table** and **NSG** configuration details.

---

**Subject:** Final Confirmation on Orca SideScanning Setup (Metadata-Only) & Request for RT/NSG Details

**Hello [Team / Architects],**

I hope you’re all doing well. I’m writing to finalize our **Orca SideScanning** deployment details across our **Dev and Prod** Azure subscriptions, incorporating the latest clarification that **only metadata** (rather than full disk snapshots) will be transmitted to Orca’s S3. Below is a summary of the setup and the outstanding items we need to confirm.

---

### 1. **High-Level Setup: Orca Azure Scanner + Private S3 Endpoint**

1. **Orca Azure Scanner Subscription**  
   - We will run Orca’s scanner engine **within** our Azure environment (in the dedicated Orca Dev/Prod subscriptions).  
   - This engine analyzes VM disks locally and sends **metadata/findings** to Orca’s backend.

2. **Network Flow**  
   - Traffic from our Azure environment **privately** routes to Orca’s S3 bucket in AWS using a **VPC Endpoint** (i.e., no public internet path).  
   - We do **not** maintain our own S3 bucket for this integration; the data lands directly in **Orca’s** bucket via the private endpoint.

3. **No Full Snapshots**  
   - The latest confirmation is that **only metadata** is transmitted out of Azure to Orca’s S3—**no** disk-level snapshots, which significantly reduces bandwidth concerns.

---

### 2. **Required Azure Infrastructure**

As part of the **hub-and-spoke** model, we have the following:

- **Orca Dev Subscription**
  - VNet(s) in North Central and South Central (App + Gateway subnets)

- **Orca Prod Subscription**
  - VNet(s) in North Central and South Central (App + Gateway subnets)

- **Hub Subscription** with a **Hub VNet**  
  - Handles connectivity for on-prem / ExpressRoute and possibly central services like firewalls or Azure Firewall.

**We need to confirm** the following:

1. **VNet Peerings**  
   - Orca Dev and Prod VNets peered to the Hub VNet (with correct `AllowGatewayTransit`, `UseRemoteGateways`, etc.).

2. **Route Tables**  
   - We must ensure outbound traffic for the Orca scanner can reach the **private S3 endpoint** in AWS via our on-prem or direct ExpressRoute.  
   - Please provide the details on:
     - Which **route tables** apply to the Orca subnets.  
     - Any **custom routes** (e.g., 0.0.0.0/0 → Hub firewall or NVA) that might affect traffic flow to AWS.

3. **Network Security Groups (NSGs)**  
   - Outbound rules in the Orca subnets must allow HTTPS (TCP/443) to the private S3 endpoint.  
   - Are there any **inbound** rules we need to adjust for the scanner or related services?

4. **DNS Settings**  
   - The Orca VNets (Dev and Prod) should point to **on-prem custom DNS** so that `s3.amazonaws.com` (and relevant subdomains) resolve to a **private IP** in AWS.  
   - Confirm any firewall or DNS forwarding rules that might be needed so the scanner can route metadata correctly to Orca’s S3.

---

### 3. **Confirmations & Next Steps**

To proceed smoothly, could you please:

1. **Confirm** the **route table** assignments for each of the Orca Dev/Prod subnets and how traffic is routed to the private S3 endpoint (via the Hub Subscription)?  
2. Provide the **NSG configuration** or at least confirm we have **TCP/443** outbound allowed for the relevant subnets, ensuring no conflicts with default-deny policies.  
3. Verify that DNS resolution for `s3.amazonaws.com` is correctly mapped to the private IP of the AWS endpoint (i.e., no public IP resolution).  
4. Acknowledge that **only metadata** will flow—no full disk blocks—so our bandwidth planning can align with this reduced data volume.

Once I have these details, I can finalize the deployment scripts/templates and complete the Orca side scanner configuration in the Dev and Prod subscriptions. Please let me know if there’s any additional information you need from my side.

**Thank you all for your help** in making this a successful and secure integration!

---

**Best Regards,**  
[Your Name]  
[Your Title / Team]  
[Contact Information]
