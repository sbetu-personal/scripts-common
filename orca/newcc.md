Here’s a revised **Change Control Document** tailored for ARM template deployment via Azure custom deployment (no tables, simplified for ServiceNow change records):  

---

### **Change Control Document: Orca Azure SaaS Integration via ARM Template**  
**Date:** [Insert Date]  
**Change Owner:** [Name/Title]  
**Change Type:** Standard  

---

### **1. Purpose**  
Deploy the Orca Security SaaS integration into the **Orca-dev Azure subscription** using an ARM template and JSON parameters file. This integration enables centralized security monitoring and establishes a baseline for future subscription rollouts.  

---

### **2. Scope**  
- **In Scope:**  
  - Deploy ARM template via Azure custom deployment to the `Orca-dev` subscription.  
  - Configure required Azure AD permissions (pre-registered Enterprise App).  
  - Validate data flow from Azure to Orca Security.  
- **Out of Scope:**  
  - Other Azure subscriptions (post-validation).  
  - Modifications outside Orca integration resources.  
- **Affected Components:**  
  - Azure Subscription: `Orca-dev`  
  - Azure AD Tenant: `[Tenant ID/Name]`  
  - Orca Security Platform  

---

### **3. Change Details**  

#### **3.1 Pre-Change Steps**  
1. **Validate ARM Template & Parameters File:**  
   - Confirm the ARM template (`orca-integration-template.json`) and parameters file (`parameters-orca-dev.json`) are configured for the `Orca-dev` subscription.  
   - Ensure least-privilege permissions (e.g., `Reader` role assignments).  
2. **Verify Azure AD Enterprise App:**  
   - Confirm the Orca Azure AD Enterprise App (`Orca-Security-Integration`) has required API permissions (e.g., `Microsoft Graph.Read`, `Azure Resource Manager.Read`).  
3. **Stakeholder Notification:**  
   - Inform DevOps, Security, and Azure teams of the deployment window.  

#### **3.2 Deployment Steps**  
1. **Deploy ARM Template via Azure Portal:**  
   - Navigate to Azure Portal > **Custom Deployment**.  
   - Upload `orca-integration-template.json` and `parameters-orca-dev.json`.  
   - Select `Orca-dev` subscription and target resource group.  
   - Start deployment; monitor for success status.  
   - **Expected Outcome:**  
     - Service principal for Orca is created.  
     - Diagnostic settings and role assignments (e.g., `Reader`) are applied.  
2. **Grant Admin Consent for Azure AD App:**  
   - In Azure AD, grant admin consent to the Orca Enterprise App for delegated permissions.  
3. **Orca Configuration:**  
   - Provide Orca with the Azure AD App credentials (Client ID, Tenant ID, Secret) for API integration.  

#### **3.3 Post-Deployment Validation**  
1. **ARM Deployment Validation:**  
   - Check deployment status in Azure Portal > **Deployments** for `Succeeded` state.  
   - Verify resources (e.g., diagnostic settings, role assignments) are created.  
2. **Orca Data Ingestion Test:**  
   - Trigger a test event (e.g., create a non-compliant storage account).  
   - Confirm Orca dashboard displays the event within 15 minutes.  
3. **Error Logging Review:**  
   - Check Azure Activity Logs and Orca logs for connectivity or permission issues.  

---

### **4. Risk Assessment**  
- **Risk 1:** ARM template misconfiguration (e.g., incorrect resource group).  
  - **Mitigation:** Pre-validate template syntax with `az deployment group validate`.  
- **Risk 2:** Orca API authentication failures.  
  - **Mitigation:** Verify Azure AD App secrets and permissions pre-deployment.  
- **Risk 3:** Data latency in Orca.  
  - **Mitigation:** Coordinate with Orca support for real-time monitoring checks.  

---

### **5. Rollback Plan**  
1. **Delete Deployment Resources:**  
   - Remove the ARM deployment via Azure Portal or CLI:  
     ```bash  
     az deployment group delete --name [DeploymentName] --resource-group [ResourceGroup]  
     ```  
2. **Revoke Azure AD Permissions:**  
   - Remove API permissions from the Orca Enterprise App in Azure AD.  
3. **Delete Service Principal:**  
   - Remove the Orca service principal from Azure AD.  

---

### **6. Approval**  
- **Azure DevOps Lead:** [Name/Approval Date]  
- **Security Officer:** [Name/Approval Date]  
- **Change Manager:** [Name/Approval Date]  

---

### **7. Post-Implementation Review**  
- **Validation Criteria:**  
  - Orca successfully ingests Azure resource data from `Orca-dev`.  
  - No critical errors in Azure/Orca logs.  
- **Review Date:** [3 business days post-deployment].  
- **Documentation Update:** Update integration playbook with lessons learned.  

--- 

**Notes for ServiceNow:**  
- Attach ARM template, parameters file, and Azure AD App screenshots to the change record.  
- Use the **Implementation Plan** section to paste steps 3.1–3.3.  
- Link this document to the parent change ticket for traceability.  

Let me know if further adjustments are needed!
