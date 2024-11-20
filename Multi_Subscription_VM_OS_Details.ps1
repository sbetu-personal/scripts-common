# Authenticate to Azure
Connect-AzAccount

# Retrieve all subscriptions
$subscriptions = Get-AzSubscription

# Initialize an array to store VM details across all subscriptions
$allVmDetails = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    Write-Output "Processing subscription: $($subscription.Name)"

    # Set the context to the current subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Retrieve all VMs in the current subscription
    $vms = Get-AzVM -Status

    foreach ($vm in $vms) {
        # Extract detailed OS information if available
        $osDetails = if ($vm.StorageProfile.ImageReference) {
            $vm.StorageProfile.ImageReference.Offer + " " + $vm.StorageProfile.ImageReference.Sku
        } else {
            "Unknown OS"
        }

        # Add VM details to the array
        $allVmDetails += [PSCustomObject]@{
            Subscription   = $subscription.Name
            ResourceGroup  = $vm.ResourceGroupName
            VMName         = $vm.Name
            Location       = $vm.Location
            OSType         = $vm.StorageProfile.OsDisk.OsType
            OperatingSystem = $osDetails
            PowerState     = $vm.PowerState
        }
    }
}

# Export the VM details to a CSV file
$allVmDetails | Export-Csv -Path "Multi_Subscription_VM_OS_Details.csv" -NoTypeInformation -Encoding UTF8

# Display the VM details in the console
$allVmDetails | Format-Table -AutoSize
