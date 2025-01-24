Here is the updated **Change Control Document** reflecting the use of Terraform variables from `.tfvars` files, deployment in both **North Central** and **South Central** regions, execution from a local laptop, and the absence of a pipeline.

---

### **Change Control Document**  
#### **Title:** Deployment of Azure VNet, Subnet, NSG, Route Table, and VNet Peering in Orca Development Subscription for North Central and South Central Regions Using Terraform  
#### **Change Request ID:** [Enter ID]  
#### **Requested By:** [Your Name/Team]  
#### **Planned Execution Date:** [Enter Date]  
#### **Purpose:**  
To deploy network infrastructure in the Orca development subscription for **North Central** and **South Central** regions, including VNet, subnet, NSG, route table, and VNet peering with the hub subscription using Terraform executed locally.

---

### **Scope:**  
The change involves deploying the following resources using Terraform:
1. Virtual Network (VNet) for both North Central and South Central regions.  
2. Subnets within each VNet.  
3. Network Security Groups (NSG) for subnets in both regions.  
4. Route Tables for managing network traffic in both regions.  
5. VNet Peering for both regions with the hub subscription.

---

### **Pre-Requisites:**  
1. Terraform is installed and configured on the local laptop.  
2. `.tfvars` files for **North Central** and **South Central** regions contain all necessary variables (e.g., CIDR ranges, resource group names, subscription details).  
3. Ensure access to the Orca development subscription and hub subscription.  
4. Validate CIDR ranges for VNets and subnets to prevent conflicts.  
5. Validate NSG and route table configurations.  
6. Internet access is available for Terraform to connect to Azure.  
7. Access to the Bitbucket repository containing the Terraform code.

---

### **Detailed Steps for Execution:**  

#### **Preparation Phase:**  
1. **Review Terraform Code:**
   - Clone the Terraform code from the Bitbucket repository:
     ```bash
     git clone <Bitbucket-repo-URL>
     cd <repository-folder>
     ```
   - Verify the `main.tf`, `variables.tf`, `outputs.tf`, and `.tfvars` files for correctness.

2. **Test the Configuration:**
   - Test the Terraform configuration locally with `terraform validate`:
     ```bash
     terraform validate
     ```
   - Ensure no errors are present in the configuration.

3. **Backup Current State:**  
   - Document existing resources in the Orca development subscription and hub subscription for rollback purposes.

4. **Inform Stakeholders:**  
   - Notify network administrators, security teams, and stakeholders about the deployment plan and regions affected.

#### **Deployment Phase:**  
1. **Initialize Terraform:**
   - In the local folder containing the Terraform configuration, run:
     ```bash
     terraform init
     ```

2. **Deploy in North Central Region:**
   - Switch to the North Central `.tfvars` file and execute the Terraform plan:
     ```bash
     terraform plan -var-file="northcentral.tfvars"
     ```
   - Review the plan output to ensure correct resources are being deployed.
   - Apply the configuration:
     ```bash
     terraform apply -var-file="northcentral.tfvars"
     ```
   - Confirm the deployment when prompted.

3. **Deploy in South Central Region:**
   - Switch to the South Central `.tfvars` file and repeat the process:
     ```bash
     terraform plan -var-file="southcentral.tfvars"
     ```
     ```bash
     terraform apply -var-file="southcentral.tfvars"
     ```

4. **Verify Deployment:**
   - Log in to the Azure portal and confirm the following for both regions:
     - VNet and subnets are deployed with correct CIDR ranges.  
     - NSG rules are correctly applied to subnets.  
     - Route tables have expected entries for traffic routing.  
     - VNet peering is successfully configured and shows "Connected" status.

5. **Test Connectivity:**
   - Test connectivity between resources in the Orca development VNets and the hub VNet.
   - Validate that NSG rules allow required traffic and route tables are functioning as expected.

#### **Post-Deployment Phase:**  
1. **Validation:**  
   - Ensure all resources are functional in both regions.
   - Check for any connectivity issues or misconfigured resources.

2. **Document Deployed Resources:**  
   - Record the details of the deployed VNets, subnets, NSG rules, route tables, and VNet peering configurations.

3. **Inform Stakeholders:**  
   - Share deployment results with stakeholders, including connectivity and validation outcomes.

4. **Enable Monitoring:**  
   - Set up monitoring for VNets, subnets, and peering connections using Azure Monitor or equivalent tools.

---

### **Roll-Back Plan:**  
1. **Revert Changes for North Central and South Central Regions:**
   - If deployment fails in any region, revert using:
     ```bash
     terraform destroy -var-file="northcentral.tfvars"
     terraform destroy -var-file="southcentral.tfvars"
     ```
   - Validate that all resources are removed.

2. **Restore Previous State:**  
   - Recreate any previously existing resources that were impacted during the deployment.  

3. **Troubleshoot and Retry:**  
   - Identify the issue in the Terraform configuration or Azure environment, fix it, and redeploy.

---

### **Impact Analysis:**  
- **Users:** Minimal to no impact as the deployment is in the development subscription.  
- **Systems:** Network connectivity between the development VNet and the hub VNet may be disrupted if configurations are incorrect.  
- **Risks:**  
   - Incorrect CIDR ranges could cause routing conflicts.  
   - Misconfigured NSG or route tables could block required traffic.

---

### **Approval and Notifications:**  
- Submit the change control document for approval by the Change Advisory Board (CAB).  
- Notify all stakeholders once the change is approved and the execution date is finalized.

---

Let me know if you need help drafting the `.tfvars` structure or further clarifications!
