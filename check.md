Thanks for confirming. Since you're **still getting the same `MissingSubscription` error**, even after setting the subscription, let's isolate and fix it properly.

---

## 🔍 **Root Cause Analysis**

The error message:

> `(MissingSubscription) The request did not have a subscription or a valid tenant level resource provider.`

means **Azure CLI is not applying the subscription context correctly**, even after `az account set`.

This can happen due to:

1. You **don't have access** to that subscription.
2. You're **using `az role assignment create` without specifying `--subscription` explicitly**, which occasionally fails even after `az account set`.
3. Azure CLI cache/session issues.

---

## ✅ **Definitive Fix: Use `--subscription` in `az role assignment create`**

Update the script to **explicitly pass the `--subscription` parameter** to the `az role assignment create` commands:

---

### ✅ **Fully Updated Script (with explicit `--subscription`)**

```bash
#!/bin/bash

# Define variables
app_name="SNW-ServiceNow-Prod"
custom_role_name="ServiceNow Contributor"
builtin_role="Reader"

# List of Azure subscription IDs
subscriptions=(
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
  # Add all 12 subscription IDs here
)

# Get SP Object ID
echo "🔍 Fetching Service Principal Object ID for '$app_name'..."
sp_object_id=$(az ad sp list --filter "displayName eq '$app_name'" --query "[0].id" -o tsv)

if [ -z "$sp_object_id" ]; then
  echo "❌ Error: Service Principal '$app_name' not found. Exiting."
  exit 1
fi

echo "✅ Found SP Object ID: $sp_object_id"

# Loop through each subscription
for sub in "${subscriptions[@]}"
do
  echo -e "\n🔄 Processing subscription: $sub"
  
  echo "🔧 Assigning built-in '$builtin_role' role..."
  if ! az role assignment create \
    --assignee-object-id "$sp_object_id" \
    --assignee-principal-type ServicePrincipal \
    --role "$builtin_role" \
    --scope "/subscriptions/$sub" \
    --subscription "$sub"; then
    echo "⚠️ Warning: Failed to assign '$builtin_role' role in $sub"
  fi

  echo "🔧 Assigning custom '$custom_role_name' role..."
  if ! az role assignment create \
    --assignee-object-id "$sp_object_id" \
    --assignee-principal-type ServicePrincipal \
    --role "$custom_role_name" \
    --scope "/subscriptions/$sub" \
    --subscription "$sub"; then
    echo "⚠️ Warning: Failed to assign '$custom_role_name' role in $sub"
  fi

  echo "✅ Completed role assignments for subscription: $sub"
done

echo -e "\n🎉 All role assignments processed."
```

---

## ✅ Additional Checks

* Run `az account list --output table` and verify the subscriptions are **listed and accessible**.
* Test one subscription manually:

  ```bash
  az role assignment create \
    --assignee-object-id <SP-ID> \
    --assignee-principal-type ServicePrincipal \
    --role "Reader" \
    --scope "/subscriptions/<sub-id>" \
    --subscription <sub-id>
  ```

---

Let me know what happens after running this exact script, or share the next error if it still fails.
