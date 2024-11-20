# Retrieve all subscriptions
$subscriptions = Get-AzSubscription

# Initialize an array to store VM details
$vmDetails = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current context to the subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Retrieve all VMs in the current subscription
    $vms = Get-AzVM -Status

    # Loop through each VM to extract details
    foreach ($vm in $vms) {
        # Create a custom object with VM details
        $vmInfo = [PSCustomObject]@{
            SubscriptionName = $subscription.Name
            ResourceGroup    = $vm.ResourceGroupName
            VMName           = $vm.Name
            Location         = $vm.Location
            OSType           = $vm.StorageProfile.OsDisk.OsType
            OSName           = $vm.OsName
            OSVersion        = $vm.OsVersion
            PowerState       = $vm.PowerState
        }
        # Add the VM details to the array
        $vmDetails += $vmInfo
    }
}

# Export the VM details to a CSV file
$vmDetails | Export-Csv -Path "AzureVM_OS_Details.csv" -NoTypeInformation -Encoding UTF8

# Display the VM details in the console
$vmDetails | Format-Table -AutoSize
