Here's a simple command to extract all the required information in the exact format needed for your script:

### 1. Get All Subscriptions (for the SUBSCRIPTIONS array)
```bash
az account list --query "[].id" -o tsv
```

### 2. Get All VNets with Subnets (for the TARGETS array)
```bash
az network vnet list --query "[?subnets].{sub:id, rg:resourceGroup, name:name, location:location, subnets:subnets[].name}" -o json
```

### 3. Processed Command (Single Command to Extract in Script Format)
```bash
# Get subscriptions (paste directly into SUBSCRIPTIONS array)
echo "SUBSCRIPTIONS=("
az account list --query "[].id" -o tsv | xargs -I{} echo '  "{}"'
echo ")"

# Get targets (paste directly into TARGETS array)
echo "TARGETS=("
az network vnet list --query "[?subnets].[id, resourceGroup, name, location]" -o tsv | while read -r SUBID RG VNET LOCATION; do
  az network vnet subnet list --vnet-name "$VNET" --resource-group "$RG" --query "[].name" -o tsv | while read -r SUBNET; do
    echo "  \"$(echo $SUBID | cut -d'/' -f3)|$RG|$VNET|$SUBNET|$LOCATION\""
  done
done
echo ")"
```

### How to Use:
1. Run these commands after `az login`
2. Copy the output directly into your script's configuration section
3. Review the subnets and remove any you don't want to monitor (like GatewaySubnet)

### Filtered Version (Only Include Subnets with "flow" in name):
```bash
echo "TARGETS=("
az network vnet list --query "[?subnets].[id, resourceGroup, name, location]" -o tsv | while read -r SUBID RG VNET LOCATION; do
  az network vnet subnet list --vnet-name "$VNET" --resource-group "$RG" --query "[?contains(name,'flow')].[name]" -o tsv | while read -r SUBNET; do
    echo "  \"$(echo $SUBID | cut -d'/' -f3)|$RG|$VNET|$SUBNET|$LOCATION\""
  done
done
echo ")"
```

### Example Output:
```
SUBSCRIPTIONS=(
  "00000000-aaaa-bbbb-cccc-111111111111"
  "22222222-dddd-eeee-ffff-333333333333"
)

TARGETS=(
  "00000000-aaaa-bbbb-cccc-111111111111|rg-prod-net|vnet-prod-east|sub-flowlogs|eastus"
  "00000000-aaaa-bbbb-cccc-111111111111|rg-prod-net|vnet-prod-east|sub-app|eastus"
  "22222222-dddd-eeee-ffff-333333333333|rg-dev-net|vnet-dev-east|sub-flowlogs|eastus"
)
```

You can then manually review and edit the TARGETS array to keep only the subnets you want to monitor (typically ones named *flowlogs* or similar).
