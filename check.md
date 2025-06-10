Sure! Here's the **fully revised and robust Azure CLI Bash script** with all the fixes applied:

---

### ✅ **Revised `azi-roles.sh` Script**

```bash
#!/bin/bash

# Define variables
app_name="SNW-ServiceNow-Prod"
custom_role_name="ServiceNow Contributor"
builtin_role="Reader"

# List of Azure subscription IDs (replace with your actual 12 subscriptions)
subscriptions=(
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
  # Add the rest here
)

# Get SP Object ID with filtering
echo "Fetching Service Principal Object ID for '$app_name'..."
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
  
  # Set the subscription
  if ! az account set --subscription "$sub"; then
    echo "❌ Error: Failed to switch to subscription $sub. Skipping."
    continue
  fi

  # Optional: show the active subscription
  az account show --query "{Name:name, ID:id}" -o table

  # Assign built-in Reader role
  echo "🔧 Assigning built-in '$builtin_role' role..."
  if ! az role assignment create \
    --assignee-object-id "$sp_object_id" \
    --assignee-principal-type ServicePrincipal \
    --role "$builtin_role" \
    --scope "/subscriptions/$sub"; then
    echo "⚠️ Warning: Failed to assign '$builtin_role' role in $sub"
  fi

  # Assign custom ServiceNow Contributor role
  echo "🔧 Assigning custom '$custom_role_name' role..."
  if ! az role assignment create \
    --assignee-object-id "$sp_object_id" \
    --assignee-principal-type ServicePrincipal \
    --role "$custom_role_name" \
    --scope "/subscriptions/$sub"; then
    echo "⚠️ Warning: Failed to assign '$custom_role_name' role in $sub"
  fi

  echo "✅ Completed role assignments for subscription: $sub"
done

echo -e "\n🎉 All role assignments processed."
```

---

### 📌 **Key Fixes Applied:**

* Ensures `az account set` works and displays current context.
* Uses `--assignee-principal-type ServicePrincipal` as recommended.
* Removes `--description` to avoid preview issues.
* Includes clear logging and warnings.

---

Let me know if you'd like a version that logs everything to a file or verifies the role assignments afterward.
