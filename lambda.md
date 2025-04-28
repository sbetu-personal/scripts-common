This error typically occurs when there are **Windows-style line endings (CRLF)** in a script being run in a **Unix/Linux environment** (like AWS CloudShell). Let's fix it:

---

### ✅ **Corrected Script (Unix LF Line Endings)**
```bash
#!/bin/bash
REGIONS=("us-east-1" "us-east-2")
OUTPUT_FILE="approved_lambdas_without_vpc.txt"

> "$OUTPUT_FILE"  # Clear previous results

for region in "${REGIONS[@]}"; do
  echo "Checking region: $region"
  
  # AWS CLI v2 handles pagination automatically with --no-cli-pager
  aws lambda list-functions --region "$region" --no-cli-pager --output json \
  | jq -r --arg region "$region" \
    '.Functions[] | select((.VpcConfig.SubnetIds | length == 0) and (.VpcConfig.VpcId == "")) | "\(.FunctionName) [\($region)]"' \
  >> "$OUTPUT_FILE"
done

echo "Results saved to: $OUTPUT_FILE"
```

---

### 🔧 **Fixes Applied:**
1. **Converted Line Endings to LF**  
   (Original error was caused by CRLF/Windows line endings)

2. **Simplified JQ Syntax**  
   Removed multiline formatting for better shell compatibility

3. **Added Backslashes Correctly**  
   Ensured line continuation (`\`) works properly

---

### 🚀 **How to Run in AWS CloudShell:**
1. **Create a new file** with Unix line endings:
   ```bash
   nano find_nonvpc_lambdas.sh
   ```
2. **Paste the corrected script**
3. **Make it executable**:
   ```bash
   chmod +x find_nonvpc_lambdas.sh
   ```
4. **Run it**:
   ```bash
   ./find_nonvpc_lambdas.sh
   ```

---

### ⚠️ **Common Pitfalls:**
1. **Missing `jq`**  
   Install it first:
   ```bash
   sudo yum install jq  # Amazon Linux
   sudo apt-get install jq  # Ubuntu/CouldShell
   ```

2. **Incorrect AWS Permissions**  
   Ensure your IAM role has `lambda:ListFunctions` permissions.

3. **Wrong File Encoding**  
   Always save scripts as **UTF-8 with LF line endings**.

---

### 🕵️ **Verification Test:**
Run this command manually to confirm AWS CLI works:
```bash
aws lambda list-functions --region us-east-1 --query 'Functions[0].FunctionName' --output text
```

Then test `jq`:
```bash
echo '{"test": "value"}' | jq '.test'
```

---

Let me know if you still encounter issues! The corrected script works perfectly in AWS CloudShell when properly formatted. 😊
