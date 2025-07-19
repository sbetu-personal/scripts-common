#!/usr/bin/env bash
# enable‑vnet‑flowlogs.sh
set -Eeuo pipefail

###############################################################################
# EDIT THESE                                                                ###
###############################################################################
declare -a SUBSCRIPTIONS=(
  "00000000-aaaa-bbbb-cccc-111111111111"   # prod
  "22222222-dddd-eeee-ffff-333333333333"   # non‑prod
)

# Per‑VNet targets:  "subscriptionID|resourceGroup|vnetName|subnetName|region"
declare -a TARGETS=(
  "00000000-aaaa-bbbb-cccc-111111111111|rg-net-prod|vnet-prod-east|sub-flowlogs|eastus"
  "22222222-dddd-eeee-ffff-333333333333|rg-net-dev |vnet-dev-east |sub-flowlogs|eastus"
)

SA_PREFIX="flowlogsa"        # storage‑acct name starts with this (lowercase)
RETENTION_DAYS=30
FLOW_LOG_VERSION=2
###############################################################################

# ───────── helper: version compare ─────────
ver() { printf '%s\n' "$1" | awk -F. '{printf("%d%03d%03d\n",$1,$2,$3);}'; }

# ───────── guard: azure‑cli≥2.55.0 for --vnet‑name ─────────
REQ="2.55.0"
INST=$(az version --query '"azure-cli"' -o tsv)
if (( $(ver "$INST") < $(ver "$REQ") )); then
  echo "❌ Azure CLI $REQ or newer required. You have $INST." >&2
  exit 1
fi

# ───────── trap for printable errors ─────────
trap 'echo -e "\n❌  Error on line $LINENO while executing: ${BASH_COMMAND}\nAborting." >&2' ERR

# ───────── main loop ─────────
for SUB in "${SUBSCRIPTIONS[@]}"; do
  echo "▶ Subscription $SUB"
  az account set --subscription "$SUB"

  for LINE in "${TARGETS[@]}"; do
    IFS='|' read -r LINE_SUB RG VNET SUBNET REGION <<< "$LINE"
    [[ $LINE_SUB != "$SUB" ]] && continue

    echo "  • $VNET/$SUBNET  (RG=$RG, $REGION)"

    # 1) Enable service endpoint on the subnet (idempotent)
    az network vnet subnet update \
         -g "$RG" --vnet-name "$VNET" -n "$SUBNET" \
         --service-endpoints Microsoft.Storage > /dev/null

    # 2) Create storage account with network rule baked in
    RAND=$(tr -dc 'a-z0-9' </dev/urandom | head -c6)
    SA_NAME=$(printf "%.24s" "${SA_PREFIX}${RAND}")
    echo "    ↳ creating Storage acct $SA_NAME"
    az storage account create \
        -n "$SA_NAME" -g "$RG" -l "$REGION" \
        --sku Standard_LRS --kind StorageV2 \
        --allow-blob-public-access false \
        --public-network-access Enabled \
        --default-action Deny \
        --vnet-name "$VNET" --subnet "$SUBNET"

    # 3) Guarantee Network Watcher is on and grab its RG
    az network watcher configure --locations "$REGION" --enabled true > /dev/null
    read NW_NAME NW_RG <<< "$(az network watcher list \
          --query "[?location=='$REGION'] | [0].{name:name,rg:resourceGroup}" \
          -o tsv)"
    if [[ -z $NW_NAME || -z $NW_RG ]]; then
      echo "❌  Network Watcher not found in $REGION for sub $SUB" >&2
      exit 1
    fi

    # 4) Enable VNet flow log in the Network Watcher RG
    FLOW_NAME="${VNET}-flowlog"
    echo "    ↳ enabling flow log $FLOW_NAME (NW RG: $NW_RG)"
    az network watcher flow-log create \
        -l "$REGION" -g "$NW_RG" -n "$FLOW_NAME" \
        --vnet "$VNET" --storage-account "$SA_NAME" \
        --retention "$RETENTION_DAYS" \
        --format JSON --log-version "$FLOW_LOG_VERSION" \
        --enabled true
  done
done

echo -e "\n✅ All VNets processed successfully."
