Below is a **pure‑shell / pure‑`az` snippet** (no `jq`, no extra tools) that prints every

```
subscriptionID|resourceGroup|vnetName|subnetName|region
```

line your script expects.

```bash
# ---------------------------------------------------------------------------
# Print TARGETS‑style lines for *every* subnet in *every* subscription you can see
# Requires:  Azure CLI only                (no jq, awk, sed, etc.)
# ---------------------------------------------------------------------------
az account list --query "[].id" -o tsv |           # 1️⃣ all subscription IDs
while read SUB; do
  az account set --subscription "$SUB"            # switch context

  # 2️⃣ list VNets in this subscription:  name  resourceGroup  location
  az network vnet list \
      --query "[].[name,resourceGroup,location]" \
      -o tsv |
  while read VNET RG LOC; do

    # 3️⃣ list subnets in this VNet
    az network vnet subnet list -g "$RG" --vnet-name "$VNET" \
        --query "[].name" -o tsv |
    while read SUBNET; do
      # 4️⃣ emit one TARGET line
      echo "$SUB|$RG|$VNET|$SUBNET|$LOC"
    done
  done
done
```

### How to use it

1. Run the command after `az login`.
2. Copy the lines you want and paste them into the `TARGETS=( … )` block of your flow‑log script.

   ```bash
   TARGETS=(
     "00000000-aaaa-bbbb-cccc-111111111111|rg-net-prod|vnet-prod-east|sub-flowlogs|eastus"
     "…"
   )
   ```

---

#### Need the `SUBSCRIPTIONS=( … )` array too?

```bash
az account list --query "[].id" -o tsv | sed 's/^/  "/;s/$/"/'
```

Outputs:

```
  "00000000-aaaa-bbbb-cccc-111111111111"
  "22222222-dddd-eeee-ffff-333333333333"
```

Paste those lines between the parentheses of `SUBSCRIPTIONS=( … )`.

That’s it—no extra packages required. Let me know if you’d like further tweaks or filtering (e.g., only VNets that contain a subnet named `sub-flowlogs`).
