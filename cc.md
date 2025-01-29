### **JIRA Ticket: Configure Log Analytics for Azure SQL Managed Instances**  

**Summary:**  
Set up a dedicated Log Analytics Workspace (LAWS) in the Azure sandbox subscription and configure diagnostic settings for all 13 Azure SQL Managed Instances across different subscriptions to send logs for monitoring and auditing.  

---

### **Description:**  
To improve visibility into the usage of our Azure SQL Managed Instances, we need to track login activities and database utilization. Currently, we have 13 SQL Managed Instances spread across different subscriptions, and we are unsure if all of them are actively used.  

As part of this initiative, I will:  

- Create a **dedicated Log Analytics Workspace (LAWS)** in our Azure sandbox subscription.  
- Configure **diagnostic settings** for each of the 13 SQL Managed Instances to send logs to this centralized LAWS.  
- **Analyze login patterns and database activity** to determine which instances are actively used.  
- Based on findings, recommend **cleanup actions** for unused or rarely used databases.  
- Once the analysis is complete, either **clean up the LAWS** or repurpose it for monitoring other Azure resources.  

---

### **Acceptance Criteria:**  

✅ A new **Log Analytics Workspace (LAWS)** is successfully created in the sandbox subscription.  
✅ Diagnostic settings are configured on **all 13 SQL Managed Instances** to forward logs to this LAWS.  
✅ Login and usage data is successfully **ingested and available for analysis** in LAWS.  
✅ A report is generated that outlines **active vs. inactive databases** based on login and usage patterns.  
✅ A cleanup plan is proposed for **unused or underutilized** SQL instances.  
✅ A decision is made on whether to **delete or retain** the LAWS after analysis.  

---

**Priority:** Medium  
**Labels:** Azure, Log Analytics, SQL MI, Monitoring  
**Assignee:** [Your Name]  
**Reporter:** [Your Name]  
**Due Date:** [Set Based on Your Timeline]  

Let me know if you need any changes! 🚀
