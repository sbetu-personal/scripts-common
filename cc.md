Here's an Azure Resource Graph query to list all virtual machines along with their operating system information:

```kusto
resources
| where type == "microsoft.compute/virtualmachines"
| extend osType = properties.storageProfile.osDisk.osType
| extend imageReference = properties.storageProfile.imageReference
| project 
    VMName = name,
    ResourceGroup = resourceGroup,
    OS = tostring(osType),
    Publisher = tostring(imageReference.publisher),
    Offer = tostring(imageReference.offer),
    SKU = tostring(imageReference.sku),
    Version = tostring(imageReference.version)
| order by VMName asc
```

This query will:
1. Filter resources to only show VMs (`microsoft.compute/virtualmachines`)
2. Extract OS type from the OS disk properties
3. Extract image reference details (publisher, offer, SKU, version)
4. Display results with columns:
   - VM Name
   - Resource Group
   - OS Type (Windows/Linux)
   - Image Publisher
   - Image Offer
   - Image SKU
   - Image Version

The `osType` will show either "Windows" or "Linux", while the image reference fields will show details about the marketplace image used to create the VM (if applicable).

To run this query:
1. Go to Azure Portal
2. Open Azure Resource Graph Explorer
3. Paste the query and click "Run Query"

Note: For VMs using custom images, some image reference fields might be empty, but the OS type will still be shown.
