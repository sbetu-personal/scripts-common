Here's the simplified command to get all VNets across all subscriptions in the exact format your script needs (without subnets):

```bash
#!/bin/bash

# 1. Get all subscription IDs
echo "SUBSCRIPTIONS=("
az account list --query "[].id" -o tsv | while read -r SUBID; do
  echo "  \"$SUBID\""
done
echo ")"

# 2. Get all VNets (without subnets)
echo "TARGETS=("
az account list --query "[].id" -o tsv | while read -r SUBID; do
  az account set --subscription "$SUBID" > /dev/null
  az network vnet list --query "[].{sub:id, rg:resourceGroup, name:name, location:location}" -o json | \
    jq -r ".[] | \"\(.sub|split(\"/\")[2])|\(.rg)|\(.name)|ANY_SUBNET|\(.location)\"" | \
    while IFS="|" read -r SUB RG VNET SUBNET LOC; do
      echo "  \"$SUB|$RG|$VNET|ANY_SUBNET|$LOC\""
    done
done
echo ")"
```

### Key Changes:
1. **Simplified Output**: Only includes VNet-level information
2. **Placeholder for Subnet**: Uses "ANY_SUBNET" as placeholder (you can replace this with your preferred default subnet name)
3. **Proper Format**: Maintains the exact `subscription|resourceGroup|vnetName|subnet|region` format your script expects

### Example Output:
```bash
SUBSCRIPTIONS=(
  "00000000-aaaa-bbbb-cccc-111111111111"
  "22222222-dddd-eeee-ffff-333333333333"
)

TARGETS=(
  "00000000-aaaa-bbbb-cccc-111111111111|rg-prod-net|vnet-prod-east|ANY_SUBNET|eastus"
  "00000000-aaaa-bbbb-cccc-111111111111|rg-prod-net|vnet-prod-west|ANY_SUBNET|westus"
  "22222222-dddd-eeee-ffff-333333333333|rg-dev-net|vnet-dev-east|ANY_SUBNET|eastus"
)
```

### Without jq Dependency:
```bash
echo "TARGETS=("
az account list --query "[].id" -o tsv | while read -r SUBID; do
  az account set --subscription "$SUBID" > /dev/null
  az network vnet list --query "[].{rg:resourceGroup, name:name, location:location}" -o tsv | \
    while read -r RG VNET LOC; do
      echo "  \"$SUBID|$RG|$VNET|ANY_SUBNET|$LOC\""
    done
done
echo ")"
```

You can replace "ANY_SUBNET" with your preferred default subnet name (like "subnet1") if you want to use the same subnet name for all VNets.
