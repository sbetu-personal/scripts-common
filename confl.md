Here's the improved script with detailed explanations of the changes:

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

# Get SP Object ID with improved filtering
echo "Fetching Service Principal Object ID for '$app_name'..."
sp_object_id=$(az ad sp list --filter "displayName eq '$app_name'" --query "[0].id" -o tsv)

if [ -z "$sp_object_id" ]; then
  echo "Error: Service Principal '$app_name' not found. Exiting."
  exit 1
fi

# Loop through each subscription
for sub in "${subscriptions[@]}"
do
  echo -e "\nProcessing subscription: $sub"
  
  # Set subscription with error handling
  if ! az account set --subscription "$sub" >/dev/null; then
    echo "Error: Failed to switch to subscription $sub. Skipping."
    continue
  fi

  # Assign built-in role with error handling
  echo "Assigning built-in '$builtin_role' role..."
  if ! az role assignment create \
    --assignee-object-id "$sp_object_id" \
    --role "$builtin_role" \
    --scope "/subscriptions/$sub" \
    --description "ServiceNow read access" >/dev/null;
  then
    echo "Warning: Failed to assign '$builtin_role' role in $sub"
  fi

  # Assign custom role with error handling
  echo "Assigning custom '$custom_role_name' role..."
  if ! az role assignment create \
    --assignee-object-id "$sp_object_id" \
    --role "$custom_role_name" \
    --scope "/subscriptions/$sub" \
    --description "ServiceNow contributor access" >/dev/null;
  then
    echo "Warning: Failed to assign '$custom_role_name' role in $sub"
  fi

  echo "Completed role assignments for subscription: $sub"
done

echo -e "\nAll role assignments processed."
```

**Key Improvements:**

1. **Robust Service Principal Lookup:**
```bash
sp_object_id=$(az ad sp list --filter "displayName eq '$app_name'" --query "[0].id" -o tsv)
```
- Uses `--filter` for exact name matching instead of display-name substring search
- More efficient and prevents false matches

2. **Error Handling:**
   - Added error checks for critical operations:
   ```bash
   if ! az account set --subscription "$sub" >/dev/null; then
     echo "Error: Failed to switch to subscription $sub. Skipping."
     continue
   fi
   ```
   - Prevents entire script from failing on subscription switch errors
   - Individual role assignment failures are non-blocking

3. **Idempotency & Clarity:**
   - Added `--description` parameters to document purpose
   - Suppressed command output (`>/dev/null`) for cleaner logs
   - Maintained error messages for visibility

4. **Output Formatting:**
   - Added `echo -e` for better spacing
   - Clear separation between subscription processing blocks
   - Warning messages for failed operations

5. **Security Considerations:**
   - Added proper error messages instead of silent failures
   - Maintained secure role assignment at subscription scope
   - Explicit handling of SP lookup failure

**Critical Fixes:**
- Fixed the SP lookup command to prevent potential mismatches
- Added error handling for subscription switching
- Prevented entire script failure on single subscription errors
- Improved output readability for audit purposes

**Recommendations:**
1. **Test Custom Role Existence:** Add pre-check for custom role in each subscription:
```bash
az role definition list --name "$custom_role_name" --query [].name -o tsv
```
2. **Add Retry Logic:** For transient errors in role assignments
3. **Parallel Processing:** For faster execution across subscriptions (using `&` and `wait`)
4. **Input Validation:** Verify subscription IDs format before processing

**Usage Notes:**
1. Save as `.sh` file and make executable: `chmod +x filename.sh`
2. Run with Azure CLI logged in: `az login`
3. Requires "User Access Administrator" or "Owner" permissions in all subscriptions
4. First run might take 1-2 minutes per subscription for role propagation

The script now handles common Azure CLI failure scenarios gracefully while maintaining the core functionality of assigning roles across multiple subscriptions.
