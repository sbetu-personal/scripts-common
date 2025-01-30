Change Control Document

Title: Setup of Log Analytics Workspace for Azure SQL Managed Instance (MI) Monitoring

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
	1.	Create a new Log Analytics Workspace (LAWS) in the Azure sandbox subscription.
	2.	Configure diagnostic settings for all 13 Azure SQL Managed Instances to send logs to this LAWS.
	3.	Validate log ingestion by checking for successful data flow.
	4.	Analyze usage patterns (database access, login frequency).
	5.	Based on findings, recommend cleanup actions for unused databases.
	6.	Decide the fate of LAWS after analysis – either clean it up or repurpose it for monitoring other Azure resources.

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

Implementation Steps:

1️⃣ Create Log Analytics Workspace in Azure sandbox subscription.
2️⃣ Apply diagnostic settings on all 13 SQL Managed Instances.
3️⃣ Verify logs are being ingested successfully.
4️⃣ Analyze database login activity & usage trends.
5️⃣ Generate reports on active vs. inactive databases.
6️⃣ Based on findings, recommend cleanup actions.
7️⃣ Decide whether to retain or delete LAWS.

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