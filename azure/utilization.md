Got it! If you need **VM utilization metrics (CPU, memory, disk, etc.)** for the past 90 days and **don’t use Log Analytics Workspaces (LAWS)**, you can still extract this data directly from Azure Monitor Metrics. Here’s how to automate this:

---

### **Option 1: Use Azure Portal Metrics Explorer (Manual Export)**
1. **Navigate to your VM → Monitoring → Metrics**.
2. **Select Metrics** (e.g., `Percentage CPU`, `Available Memory Bytes`).
3. **Adjust Time Range** to 90 days.
4. **Export to CSV**:
   - Click the **...</>** (Automation Options) button → **Download to CSV**.

   ![Azure Metrics Export](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/media/metrics-charts/export-csv.png)

---

### **Option 2: Automate with PowerShell (No LAWS Needed)**
Use the `Az.Monitor` PowerShell module to pull metrics directly from Azure Monitor’s REST API.  

#### **Step 1: Install Required Modules**
```powershell
Install-Module -Name Az.Accounts, Az.Monitor, Az.Compute
Connect-AzAccount
```

#### **Step 2: Script to Pull VM Metrics**
```powershell
# Define time range (last 90 days)
$endTime = Get-Date
$startTime = $endTime.AddDays(-90)

# Get all VMs in a subscription
$vms = Get-AzVM

# Metrics to collect (CPU, Memory, Disk, Network)
$metrics = @(
    "Percentage CPU",
    "Available Memory Bytes",
    "Disk Read Bytes",
    "Disk Write Bytes",
    "Network In Total",
    "Network Out Total"
)

# Collect metrics for each VM
$results = @()
foreach ($vm in $vms) {
    $resourceId = $vm.Id
    $vmName = $vm.Name

    foreach ($metric in $metrics) {
        $metricData = Get-AzMetric -ResourceId $resourceId -MetricName $metric -StartTime $startTime -EndTime $endTime -AggregationType Average -Interval 01:00:00
        
        foreach ($data in $metricData.Data) {
            $results += [PSCustomObject]@{
                VMName       = $vmName
                MetricName   = $metric
                Timestamp    = $data.TimeStamp
                AverageValue = $data.Average
                Unit         = $metricData.Unit
            }
        }
    }
}

# Export to CSV
$results | Export-Csv -Path "C:\VM_Metrics_90Days.csv" -NoTypeInformation
```

#### **Explanation**:
- **Aggregation**: Uses `Average` over `1-hour` intervals (adjust with `-Interval`).
- **Metrics**: Includes CPU, memory, disk, and network metrics (customize as needed).
- **Output**: CSV with timestamps and average values.

---

### **Option 3: Azure CLI**
```bash
# Login
az login

# Get VM resource ID
vm_resource_id=$(az vm show --name <VM_NAME> --resource-group <RG_NAME> --query id --output tsv)

# Pull CPU metrics for last 90 days
az monitor metrics list --resource $vm_resource_id \
  --metric "Percentage CPU" \
  --start-time $(date -u -d "90 days ago" '+%Y-%m-%dT%H:%M:%SZ') \
  --end-time $(date -u '+%Y-%m-%dT%H:%M:%SZ') \
  --interval 1h \
  --output table
```

---

### **Option 4: Automate with Azure Automation**
1. **Create an Automation Account**.
2. **Import Modules**: Ensure `Az.Monitor` and `Az.Compute` are imported.
3. **Create a Runbook**:
   - Use the PowerShell script above.
4. **Schedule the Runbook**:
   - Run weekly/monthly to export metrics to Azure Storage/Email.

---

### **Key Notes**:
1. **Retention**: Azure Monitor Metrics retains data for 90 days by default (no LAWS required).
2. **Granularity**: 
   - Metrics are stored at **1-minute granularity**, but you can aggregate to hourly/daily.
3. **Permissions**: 
   - Your account needs the **Monitoring Reader** role on the VMs.
4. **Cost**: 
   - Querying metrics is free, but Automation Accounts incur minimal costs.

---

### **Sample CSV Output**:
| VMName      | MetricName          | Timestamp           | AverageValue | Unit  |
|-------------|---------------------|---------------------|--------------|-------|
| MyVM1       | Percentage CPU      | 2023-10-01 00:00:00 | 12.5         | Percent |
| MyVM1       | Available Memory    | 2023-10-01 00:00:00 | 4096         | Bytes |

---

### **Troubleshooting**:
- **No Data?** Ensure Azure VM diagnostics are enabled (no LAWS required for basic metrics).
- **Permissions?** Run `Get-AzMetric` with `-Debug` to see errors.

This avoids scripts from GitHub and uses native Azure tooling. Let me know if you need help refining the queries! 😊
