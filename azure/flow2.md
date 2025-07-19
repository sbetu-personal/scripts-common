Here are two **quick, copy-paste commands** that will dump exactly the snippets you need for the script:

---

## 1 ️⃣  Build the `SUBSCRIPTIONS=( … )` array

```bash
az account list --query "[].id" -o tsv |
awk '{printf "  \"%s\"\n", $0}'
```

* Prints one subscription ID per line, already wrapped in quotes.
* Paste the output between the parentheses of `SUBSCRIPTIONS=( … )`.

---

## 2 ️⃣  Build the `TARGETS=( … )` lines

(one line **per subnet**)

```bash
for SUB in $(az account list --query "[].id" -o tsv); do
  az account set --subscription "$SUB"
  az network vnet list -o json | \
    jq -r --arg SUB "$SUB" '
      .[] as $vnet |
      ($vnet.subnets[]?) as $s |
      "\($SUB)|\($vnet.resourceGroup)|\($vnet.name)|\($s.name)|\($vnet.location)"'
done
```

What you get (example):

```
00000000-aaaa-bbbb-cccc-111111111111|rg-net-prod|vnet-prod-east|sub-web|eastus
00000000-aaaa-bbbb-cccc-111111111111|rg-net-prod|vnet-prod-east|sub-flowlogs|eastus
22222222-dddd-eeee-ffff-333333333333|rg-net-dev |vnet-dev-east |sub-dev   |eastus
```

* Each line already follows the script’s required format:
  `subscriptionID|resourceGroup|vnetName|subnetName|region`
* Copy the lines you want and paste them inside the `TARGETS=( … )` block.
* **Remove** any VNets/subnets you don’t want to include.

> **Dependencies:** the second command uses `jq` for neat JSON flattening.
> `sudo apt install jq` (Debian/Ubuntu) or `brew install jq` (macOS) if it isn’t already installed.

That’s it—fill the two arrays with the generated output, save the script, and run it.
