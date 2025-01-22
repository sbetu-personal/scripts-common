Here is a detailed Change Control (CC) plan to run the Azure onboarding script for Orca. The steps account for the resources shown in the images.

---

### **Change Control Document**
#### **Title:** Azure Onboarding Script Execution for Orca Deployment  
#### **Change Request ID:** [Enter ID]  
#### **Requested By:** [Your Name/Team]  
#### **Planned Execution Date:** [Enter Date]  
#### **Purpose:**  
To deploy Azure resources required for Orca Security integration using the onboarding script.  

---

### **Scope:**  
This change involves running the Azure onboarding script to deploy resources such as logic apps, API connections, role definitions, role assignments, and resource groups for Orca Security as detailed in the uploaded screenshots.

---

### **Pre-Requisites:**  
1. Ensure you have the following permissions:
   - Azure AD admin or subscription owner.
   - Permissions to create custom roles, assign roles, and deploy resources in Azure.
2. Verify access to the onboarding script provided by Orca.
3. Ensure the target Azure subscription and resource group are active and accessible.
4. Verify no conflicting roles or resources exist in the subscription.

---

### **Detailed Steps for Execution:**  

#### **Preparation Phase:**  
1. **Review Dependencies:**
   - Confirm the Orca onboarding script prerequisites are satisfied (e.g., existing Azure AD apps, permissions, etc.).
   - Verify resource quotas in the Azure subscription to avoid deployment issues.

2. **Backup Existing Configuration:**
   - Document the existing roles, resource groups, and policies in the Azure subscription to roll back in case of errors.
   - Backup sensitive configuration data such as key vaults, if applicable.

3. **Inform Stakeholders:**
   - Notify all stakeholders, including security teams and application owners, of the planned changes.

#### **Deployment Phase:**  
1. **Run the Azure Onboarding Script:**
   - Open Azure Cloud Shell or a terminal with Azure CLI.
   - Authenticate using `az login` and select the appropriate subscription using `az account set --subscription "<Subscription-ID>"`.

2. **Execute the Script:**
   - Download the onboarding script locally or clone it from the repository.
   - Run the script with required parameters, e.g.:
     ```bash
     ./orca_onboarding_script.sh --subscription-id "<Subscription-ID>" --resource-group "<Resource-Group-Name>"
     ```
   - Provide additional arguments for enabling specific features like ADE-encrypted disk scanning or specific roles.

3. **Monitor Deployment:**
   - Track the deployment logs in real-time.
   - Verify the creation of the following resources as seen in the images:
     - **Resource Groups:** E.g., `OrcaScannerIdentity`, `Scanner Resource Group`.
     - **Logic Apps:** E.g., `CopyDisk`, `UpdateKeyVault`, `CreateDedicatedRG`.
     - **Custom Roles:** E.g., `Orca Security - Function Invoker Role`, `Key Vault Updater Role`.
     - **Role Assignments:** E.g., `Virtual Machine Contributor`, `Network Contributor`, `Managed Identity Operator`.

4. **Validate API Connections:**
   - Confirm the API connections (`copy-disk-arm-connection`, `update-keyvault-arm-connection`, etc.) are functional and linked to the appropriate logic apps.

5. **Verify Resource Descriptions and Roles:**
   - Ensure that the roles and descriptions match the requirements, e.g., permissions to access ADE-encrypted disks and backend operations.

#### **Post-Deployment Phase:**  
1. **Validate Deployment:**
   - Confirm that all resources, roles, and assignments are visible in the Azure portal.
   - Test key functionality, such as scanning encrypted disks, logic app workflows, and API connections.

2. **Document Changes:**
   - Update the change control documentation with the executed steps and results.

3. **Inform Stakeholders:**
   - Share a summary of the deployment and testing results with stakeholders.

4. **Monitor for Issues:**
   - Enable monitoring and alerts for newly created resources to detect any anomalies.

---

### **Roll-Back Plan:**  
1. If the deployment fails, stop the script execution immediately.  
2. Remove partially deployed resources using the Azure CLI or portal:
   - Identify resources using tags or names created by the onboarding script.
   - Delete resources using `az resource delete`.  
3. Revert role definitions and assignments to their previous state using the backup documentation.  
4. Troubleshoot errors and attempt a redeployment after resolving issues.

---

### **Impact Analysis:**  
- **Users:** No immediate user impact.  
- **Systems:** Temporary deployment of resources might cause elevated Azure usage costs.  
- **Risks:** Misconfigured roles or failed deployments could impact Azure subscription configurations.  

---

### **Approval and Notifications:**  
- Submit the CC document for approval by the Change Advisory Board (CAB).  
- Notify stakeholders of the approved change and scheduled execution date.  

---

If you need specific scripts or further details on validation, let me know!
