Change Control Document

Title: Setup of Log Analytics Workspace (LAWS) for Azure SQL Managed Instance (MI) Monitoring

1. Change Request Details

Change Requestor:

[Your Name]

Change Owner:

[Your Name or Relevant Team Lead]

Change Category:

☑️ Minor Change ☐ Major Change ☐ Emergency Change

Change Type:

☑️ Standard Change ☐ Normal Change ☐ Emergency Change

Change Justification:

Currently, we have 13 Azure SQL Managed Instances across different subscriptions, and we need to monitor their usage and user login activities. This change will help us:
	•	Audit who is logging into the databases and track activity.
	•	Determine which databases are actively used and which can be considered for cleanup.
	•	Centralize logs into a dedicated Log Analytics Workspace (LAWS) for efficient monitoring.

2. Change Description

This change involves:
	1.	Creating a new Log Analytics Workspace (LAWS) in the Azure sandbox subscription.
	2.	Configuring diagnostic settings for all 13 Azure SQL Managed Instances to send logs to this LAWS.
	3.	Validating log ingestion by checking for successful data flow.
	4.	Analyzing usage patterns (database access, login frequency).
	5.	Based on findings, recommending cleanup actions for unused databases.
	6.	Deciding the fate of LAWS after analysis – either clean it up or repurpose it for monitoring other Azure resources.

3. Impact Analysis

Impact on Services:
	•	No direct impact on database operations.
	•	Minimal resource usage in Azure for LAWS and logging.
	•	Potential cost impact due to log ingestion (to be monitored).

Risk Assessment:

Risk	Probability	Impact	Mitigation Plan
Log ingestion may fail	Low	Medium	Validate diagnostic settings and test logs
High log volume may increase cost	Medium	Medium	Monitor costs and adjust retention period
Cross-subscription log forwarding issues	Medium	Medium	Ensure all subscriptions are under the same Azure AD tenant

4. Rollout Plan

Pre-Implementation Steps:

✅ Verify subscriptions and permissions for cross-subscription logging.
✅ Ensure required RBAC roles for setting up LAWS.

Implementation Steps (With Details)

Step 1: Log in to Azure
	1.	Open a browser and navigate to Azure Portal.
	2.	Log in using your Azure credentials.
	3.	Ensure you have the right permissions to create a Log Analytics Workspace and modify diagnostic settings.

Step 2: Create a Log Analytics Workspace (LAWS)
	1.	In the Azure Portal, search for Log Analytics workspaces in the search bar.
	2.	Click Create.
	3.	Enter the following details:
	•	Subscription: Select the Azure sandbox subscription.
	•	Resource Group: Choose an existing group or create a new one.
	•	Name: Enter a unique name, e.g., SQL-MI-Monitoring-LAWS.
	•	Region: Choose a region close to your resources.
	•	Pricing Tier: Keep the default Pay-as-you-go option.
	4.	Click Review + Create, then Create.
	5.	Wait for deployment to complete and note down the Workspace ID and Key.

Step 3: Configure Diagnostic Settings for SQL Managed Instances

For each of the 13 Azure SQL Managed Instances, perform the following:
	1.	In Azure Portal, navigate to Azure SQL Managed Instance.
	2.	Select the SQL Managed Instance to configure.
	3.	On the left menu, click Diagnostics settings.
	4.	Click + Add diagnostic setting.
	5.	Name the setting, e.g., SQL-MI-Logs-to-LAWS.
	6.	Under Categories, select:
	•	SQLSecurityAuditEvents (to track login activity)
	•	Errors
	•	ExecutionStatistics
	•	BlockedProcesses
	7.	Under Destination Details, choose Send to Log Analytics workspace.
	8.	Select the Log Analytics Workspace (SQL-MI-Monitoring-LAWS) created earlier.
	9.	Click Save.
	10.	Repeat for all 13 SQL Managed Instances.

Step 4: Validate Log Ingestion
	1.	Go to Log Analytics Workspace (SQL-MI-Monitoring-LAWS).
	2.	Open Logs and run the following query to check for ingested logs:

AzureDiagnostics
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc


	3.	Verify that login attempts and SQL usage logs are appearing.
	4.	If logs are missing, revisit diagnostic settings and troubleshoot.

Step 5: Analyze Usage and Identify Cleanup Candidates
	1.	Use the following query to check login frequency:

AzureDiagnostics
| where Category == "SQLSecurityAuditEvents"
| summarize LoginCount=count() by UserName, ManagedInstanceName
| order by LoginCount desc


	2.	Identify instances with low or no activity.
	3.	Generate a report listing active vs. inactive databases.
	4.	Recommend cleanup actions based on findings.

Step 6: Decision on LAWS Cleanup
	1.	If the workspace is no longer needed after the audit, delete it to save costs.
	2.	If useful for long-term monitoring, repurpose it for Azure resource usage tracking.

5. Rollback Plan
	•	If logs fail to be ingested, revert diagnostic settings to previous state.
	•	If unexpected performance or cost issues occur, disable logging for SQL MIs.
	•	If necessary, delete LAWS without affecting other resources.

6. Testing & Validation

✅ Validate log ingestion in Log Analytics.
✅ Verify queries on collected logs.
✅ Generate test reports to ensure audit data availability.

7. Change Approval

Approver	Role	Status
[Approver Name]	[Team/Manager]	☐ Approved / ☐ Rejected

8. Schedule & Timeline

Task	Owner	Estimated Completion
Create LAWS	[Your Name]	[Date]
Configure Diagnostic Settings	[Your Name]	[Date]
Validate Log Ingestion	[Your Name]	[Date]
Analyze Usage	[Your Name]	[Date]
Recommend Cleanup Actions	[Your Name]	[Date]

9. Additional Notes:
	•	This change follows best practices for Azure Monitor & Log Analytics.
	•	Logs will be deleted or retained based on business decisions after analysis.

Let me know if you need modifications before submitting! 🚀