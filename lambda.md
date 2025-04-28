Got it! Here's the **modified script that checks only `us-east-1` and `us-east-2`** (your approved regions):

---

### 🔒 **Region-Locked Script**
```bash
#!/bin/bash
REGIONS=("us-east-1" "us-east-2")  # Only your approved regions
OUTPUT_FILE="approved_lambdas_without_vpc.txt"

# Clear previous output (optional)
> "$OUTPUT_FILE"

for region in "${REGIONS[@]}"; do
  echo "Checking region: $region"
  aws lambda list-functions --region "$region" --no-cli-pager --output json \
  | jq -r --arg region "$region" '.Functions[] | 
      select(.VpcConfig.SubnetIds == null or (.VpcConfig.SubnetIds | length == 0) or .VpcConfig.VpcId == null) | 
      "\(.FunctionName) [\($region)]"' \
  >> "$OUTPUT_FILE"
done

echo "Results saved to: $OUTPUT_FILE"
```

---

### 🔍 **Key Changes**:
1. **Hardcoded Approved Regions**:  
   Explicitly checks only `us-east-1` and `us-east-2` (no dynamic region fetching).

2. **Enhanced VPC Check**:  
   Added `.VpcConfig.VpcId == null` to ensure Lambdas with empty VPC metadata are included.

3. **Output Format**:  
   Appends `[region]` to each Lambda name for clarity (e.g., `my-lambda [us-east-1]`).

---

### 📂 **Example Output** (`approved_lambdas_without_vpc.txt`):
```
my-lambda-dev [us-east-1]
weather-api [us-east-1]
data-processor [us-east-2]
```

---

### ⚙️ **How to Run**:
1. Save the script as `check-lambdas.sh`
2. Make it executable:  
   ```bash
   chmod +x check-lambdas.sh
   ```
3. Run it:  
   ```bash
   ./check-lambdas.sh
   ```

---

### 📝 **Notes**:
- Ensure your AWS CLI credentials have permissions to `lambda:ListFunctions` in both regions.
- If you ever need to add/remove regions, simply edit the `REGIONS` array in the script.

Need further tweaks? Let me know! 😊
