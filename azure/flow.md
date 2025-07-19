Below is a **template Bash script** that:

1. **Loops through any number of subscriptions** you list.

2. For each subscription, loops through **(resource‑group, VNet, subnet, region)** tuples you specify.

3. **Creates one Storage account per VNet** that satisfies the policy:

   * `--public-network-access Enabled` → “Enabled from selected virtual networks & IP addresses”. ([Microsoft Learn][1])
   * `--default-action Deny` → nothing is allowed unless you add an explicit rule. ([Microsoft Learn][1])
   * Adds a **virtual‑network rule** for the chosen VNet+subnet. ([Microsoft Learn][2])

4. **Enables VNet flow logs** that write into the Storage account. (The CLI supports `--vnet` directly.) ([Microsoft Learn][3])

5. Makes sure the subnet has the **“Microsoft.Storage” service endpoint** enabled, because otherwise traffic can’t reach the storage account even after you add the rule. ([Microsoft Learn][4])

---

```bash
#!/usr/bin/env bash
set -euo pipefail

# ────── ①  EDIT THESE ARRAYS ──────
# List every subscription you want to process
SUBSCRIPTIONS=(
  "00000000-aaaa-bbbb-cccc-111111111111"   # prod
  "22222222-dddd-eeee-ffff-333333333333"   # non‑prod
)

# For each subscription, list one or more lines:
#   "subscriptionId|resourceGroup|vnetName|subnetName|region"
# Multiple lines per subscription are allowed; keep them in the same order.
TARGETS=(
  "00000000-aaaa-bbbb-cccc-111111111111|rg‑prod‑net|vnet‑prod‑east|sub‑flowlogs|eastus"
  "00000000-aaaa-bbbb-cccc-111111111111|rg‑prod‑net|vnet‑prod‑central|sub‑flowlogs|centralus"
  "22222222-dddd-eeee-ffff-333333333333|rg‑dev‑net |vnet‑dev‑east |sub‑flowlogs|eastus"
)

# Flow‑log & storage settings
RETENTION_DAYS=30        # keep JSON logs for 30 days
FLOW_LOG_VERSION=2       # schema version (GA)
SA_PREFIX="flowlogsa"    # 3‑24 chars, lowercase letters & digits

# ────── ②  SCRIPT LOGIC – NO CHANGES NEEDED BELOW ──────
for SUBID in "${SUBSCRIPTIONS[@]}"; do
  echo "► Switching to subscription $SUBID"
  az account set --subscription "$SUBID"

  # Loop only the TARGET lines that belong to this subscription
  for LINE in "${TARGETS[@]}"; do
    IFS='|' read -r LINE_SUB RG VNET SUBNET REGION <<< "$LINE"
    [[ "$LINE_SUB" != "$SUBID" ]] && continue  # skip if not for this sub

    echo "─── $VNET/$SUBNET  (RG: $RG, Region: $REGION) ───"

    # 1️⃣ Guarantee Network Watcher is active in the region
    az network watcher configure --locations "$REGION" --enabled true

    # 2️⃣ Enable the Storage service endpoint on the subnet (idempotent)
    az network vnet subnet update \
      --resource-group "$RG" \
      --vnet-name      "$VNET" \
      --name           "$SUBNET" \
      --service-endpoints "Microsoft.Storage" >/dev/null

    # 3️⃣ Create a policy‑compliant Storage account name (must be globally unique)
    RAND=$(tr -dc 'a-z0-9' </dev/urandom | head -c6)
    SA_NAME=$(printf "%.24s" "${SA_PREFIX}${RAND}")

    echo "   • Creating Storage account $SA_NAME"
    az storage account create \
      --name "$SA_NAME" \
      --resource-group "$RG" \
      --location "$REGION" \
      --sku Standard_LRS \
      --kind StorageV2 \
      --min-tls-version TLS1_2 \
      --public-network-access Enabled \
      --default-action Deny \
      --allow-blob-public-access false

    # 4️⃣ Add a *selected‑network* rule for the subnet
    az storage account network-rule add \
      --resource-group "$RG" \
      --account-name   "$SA_NAME" \
      --vnet-name      "$VNET" \
      --subnet         "$SUBNET"

    # 5️⃣ Create or update the VNet flow log
    FLOW_NAME="${VNET}-flowlog"
    echo "   • Enabling VNet flow log $FLOW_NAME"
    az network watcher flow-log create \
      --location        "$REGION" \
      --resource-group  "$RG" \
      --name            "$FLOW_NAME" \
      --vnet            "$VNET" \
      --storage-account "$SA_NAME" \
      --retention       "$RETENTION_DAYS" \
      --format          JSON \
      --log-version     "$FLOW_LOG_VERSION" \
      --enabled         true
  done
done
```

### How to use

1. **Edit the `SUBSCRIPTIONS` array** with the IDs you manage.
2. **Fill in `TARGETS`** with every `(subscription, RG, VNet, subnet, region)` you need.
3. Save the file, make it executable (`chmod +x enable‑vnet‑flowlogs.sh`) and run it after `az login`.

### Why this satisfies your Azure Policy

* `--public-network-access Enabled` selects *“enabled from selected virtual networks & IP addresses”*.
* `--default-action Deny` makes the account **inaccessible** until we add explicit network rules, matching the policy’s intent.
* The script immediately **adds a rule** for your chosen VNet/subnet, so traffic from that network is allowed while everything else stays blocked.

Feel free to extend the script (e.g., traffic analytics, tagging, or read targets from a CSV). Let me know if you need that or have any trouble!

[1]: https://learn.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest&utm_source=chatgpt.com "az storage account | Microsoft Learn"
[2]: https://learn.microsoft.com/en-us/cli/azure/storage/account/network-rule?view=azure-cli-latest&utm_source=chatgpt.com "az storage account network-rule | Microsoft Learn"
[3]: https://learn.microsoft.com/en-us/cli/azure/network/watcher/flow-log?view=azure-cli-latest&utm_source=chatgpt.com "az network watcher flow-log | Microsoft Learn"
[4]: https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security-virtual-networks?utm_source=chatgpt.com "Create a virtual network rule for Azure Storage - Learn Microsoft"
