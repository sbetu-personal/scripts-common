No problem! In **Azure Cloud Shell**, your default directory is `/home/username`. Here’s the adjusted script to save the CSV directly to your home path (`/home/username/`) and work within Azure Cloud Shell’s environment:

---

### **Modified Script for Azure Cloud Shell**
```powershell
# Connect to Azure (if not already authenticated)
Connect-AzAccount

# Define time range (last 90 days in UTC)
$endTime = (Get-Date).ToUniversalTime()
$startTime = $endTime.AddDays(-90)

# Get all VMs in the current subscription
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
        Write-Output "Collecting $metric for $vmName..."
        
        # Use -TimeGrain (e.g., 1 hour granularity)
        $metricData = Get-AzMetric -ResourceId $resourceId -MetricName $metric `
            -StartTime $startTime -EndTime $endTime `
            -AggregationType Average `
            -TimeGrain 01:00:00  # 1-hour intervals
        
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

# Save to CSV in your home directory (/home/username/)
$outputPath = "./VM_Metrics_90Days.csv"  # Path relative to /home/username/
$results | Export-Csv -Path $outputPath -NoTypeInformation

Write-Output "Metrics saved to: $outputPath"
```

---

### **Key Adjustments**:
1. **Output Path**:  
   - `$outputPath = "./VM_Metrics_90Days.csv"` saves the CSV to your current directory (`/home/username/`).  
   - Use `pwd` in Cloud Shell to confirm your working directory.  

2. **TimeGrain**:  
   - Replaced `-Interval` with `-TimeGrain` (valid values: `00:01:00`, `01:00:00`, etc.).  

3. **Cloud Shell Environment**:  
   - No need to install modules (`Az.Monitor`, `Az.Compute` are preinstalled).  
   - Authentication is automatic in Cloud Shell (no need for `Connect-AzAccount` unless switching tenants).  

---

### **How to Run**:
1. Open **Azure Cloud Shell (PowerShell)** from the Azure Portal.  
2. Paste the script.  
3. After execution, the CSV will be in `/home/username/`.  
4. Download it using:  
   ```powershell
   Get-Item "./VM_Metrics_90Days.csv"
   ```

---

### **Notes**:
- **File Persistence**: Files in `/home/username/` persist across Cloud Shell sessions.  
- **Large Subscriptions**: If you have many VMs, add a `-First 10` to test with a subset first.  
- **Permissions**: Ensure your account has **Monitoring Reader** role on the VMs.  

Let me know if you need further tweaks! 😊
