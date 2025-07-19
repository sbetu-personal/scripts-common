Thanks for the image — that repeating error:

```
doesn't exist in cloud 'AzureCloud': <GUID>
```

### 🔍 What’s happening

This is an **Azure CLI bug or logging quirk**, usually triggered when listing VNets/subnets across multiple subscriptions or regions that include:

* **Reserved system subnets**, like:

  * `GatewaySubnet`
  * `AzureBastionSubnet`
* **Empty or invalid VNet objects**
* **Nonexistent resources** (e.g. a deleted VNet still being referenced in some cache)

It’s harmless but noisy.

---

### ✅ Fix: Add a check to skip these system subnets and blank outputs

Modify the subnet listing part of the command like this:

```bash
az network vnet subnet list -g "$RG" --vnet-name "$VNET" --query "[].name" -o tsv |
grep -v -E '^(GatewaySubnet|AzureBastionSubnet|RouteServerSubnet|AzureFirewallSubnet|None)?$' |
while read SUBNET; do
  echo "$SUB|$RG|$VNET|$SUBNET|$LOC"
done
```

This does three things:

| Change                        | Why                                          |
| ----------------------------- | -------------------------------------------- |
| `grep -v -E '…'`              | Filters out system-reserved subnets          |
| `None` or empty lines         | Skips broken/missing subnet values           |
| Quoting `$SUBNET` in the echo | Prevents bad formatting if names have spaces |

---

### ✅ Alternative Full Script (Clean Output)

Here’s a full working, clean version you can run now:

```bash
az account list --query "[].id" -o tsv |
while read SUB; do
  az account set --subscription "$SUB"

  az network vnet list --query "[].[name,resourceGroup,location]" -o tsv |
  while IFS=$'\t' read -r VNET RG LOC; do
    az network vnet subnet list -g "$RG" --vnet-name "$VNET" --query "[].name" -o tsv |
    grep -v -E '^(GatewaySubnet|AzureBastionSubnet|RouteServerSubnet|AzureFirewallSubnet)?$' |
    while read -r SUBNET; do
      [[ -z "$SUBNET" ]] && continue
      echo "$SUB|$RG|$VNET|$SUBNET|$LOC"
    done
  done
done
```

You’ll now only get **real, usable subnets** — no system-reserved ones, no noise.

---

Let me know if you want to filter only subnets with `flow` in the name, or ones in specific regions.
