Below are **pure‑Azure‑CLI** one‑liners (no `jq`, no extra tools) that dump text you can
*copy‑paste straight into the two arrays* in your flow‑log script.

---

## ① Build the `SUBSCRIPTIONS=( … )` array

```bash
az account list --query "[].id" -o tsv |
while read SUB; do
  printf '  "%s"\n' "$SUB"
done
```

**What you get**

```
  "00000000-aaaa-bbbb-cccc-111111111111"
  "22222222-dddd-eeee-ffff-333333333333"
```

Copy those quoted IDs between the parentheses of `SUBSCRIPTIONS=( … )`.

---

## ② Build the `TARGETS=( … )` lines

(one line **per subnet**)

```bash
az account list --query "[].id" -o tsv |
while read SUB; do
  az account set --subscription "$SUB"

  # loop through every VNet in this subscription
  az network vnet list --query "[].[name,resourceGroup,location]" -o tsv |
  while IFS=$'\t' read -r VNET RG LOC; do

    # loop through every subnet in that VNet
    az network vnet subnet list -g "$RG" --vnet-name "$VNET" \
        --query "[].name" -o tsv |
    while read SUBNET; do
      # emit the TARGET line
      echo "$SUB|$RG|$VNET|$SUBNET|$LOC"
    done
  done
done
```

**Sample output**

```
00000000-aaaa-bbbb-cccc-111111111111|rg-net-prod|vnet-prod-east|sub-web      |eastus
00000000-aaaa-bbbb-cccc-111111111111|rg-net-prod|vnet-prod-east|sub-flowlogs |eastus
22222222-dddd-eeee-ffff-333333333333|rg-net-dev |vnet-dev-east |sub-dev      |eastus
```

* Keep only the lines you actually want flow logs on.
* Paste them into your script like:

  ```bash
  TARGETS=(
    "00000000-aaaa-bbbb-cccc-111111111111|rg-net-prod|vnet-prod-east|sub-flowlogs|eastus"
    "22222222-dddd-eeee-ffff-333333333333|rg-net-dev |vnet-dev-east |sub-dev     |eastus"
  )
  ```

---

### Filtering tips

* **Specific subnet name**
  Append `| grep sub-flowlogs` after the final `echo …` loop.
* **Only certain regions**
  Insert `if [[ $LOC != "eastus" ]]; then continue; fi` inside the VNet loop.

That’s all you need—no external utilities, works in Bash on macOS, Linux, and Cloud Shell. Let me know if you’d like more filtering examples!
