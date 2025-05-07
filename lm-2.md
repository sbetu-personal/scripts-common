Here's a step-by-step guide to test Lambda VPC connectivity to your private Apigee endpoint:

---

### **Step 1: Prepare VPC Resources**
1. **Identify/Create Subnets**
   - Use **two private subnets** in different AZs (same VPC where your other VPC resources reside)
   - *Note:* These subnets need a route to your on-prem network via AWS Direct Connect.

2. **Create Security Group**
   - Name: `lambda-apigee-test-sg`
   - Outbound Rule: Allow HTTPS (port 443) to destination `0.0.0.0/0` (temporarily for testing)
   - *Later:* Restrict to Apigee's private IP/CIDR range if known.

---

### **Step 2: Create Lambda Function**
**Via AWS Console:**
1. **Lambda > Create Function**
   - Name: `test-apigee-vpc-connectivity`
   - Runtime: Python 3.12
   - Architecture: x86_64
   - Permissions: Create new IAM role (we'll edit this later)

2. **Configure VPC**
   - In the Lambda configuration page:
     - VPC: Select your VPC
     - Subnets: Select your two private subnets
     - Security Group: `lambda-apigee-test-sg`

---

### **Step 3: Update IAM Role**
1. Go to IAM > Roles > Find your Lambda role
2. Attach these managed policies:
   - `AWSLambdaVPCAccessExecutionRole` (for ENI management)
   - `AWSLambdaBasicExecutionRole` (for CloudWatch logging)

---

### **Step 4: Lambda Test Code**
Use this Python code to test HTTPS connectivity:

```python
import http.client
import os
import ssl

def lambda_handler(event, context):
    apigee_host = "api.qa.xxxx.com"
    path = "/"

    try:
        # Bypass SSL verification for testing only
        conn = http.client.HTTPSConnection(
            apigee_host,
            context=ssl._create_unverified_context()
        )
        conn.request("GET", path)
        response = conn.getresponse()
        
        return {
            "statusCode": response.status,
            "body": f"Successfully connected to {apigee_host}"
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Connection failed: {str(e)}"
        }
```

---

### **Step 5: Test Execution**
1. Deploy the Lambda code
2. Create a **new test event** (use default template)
3. Click **Test**
4. Check results in:
   - Lambda execution results
   - CloudWatch Logs (`/aws/lambda/test-apigee-vpc-connectivity`)

---

### **Troubleshooting Tips**
If connection fails:
1. **Check Security Groups**: Confirm outbound HTTPS is allowed
2. **Validate Route Tables**: Ensure subnets have routes to your on-prem network via Direct Connect
3. **DNS Resolution**:
   - Verify VPC has `enableDnsHostnames` and `enableDnsSupport` set to `true`
   - Test DNS resolution in your VPC using an EC2 instance if needed
4. **Firewall Rules**: Work with network team to confirm:
   - Your VPC CIDR range is allowed in GCP/Apigee firewall rules
   - Traffic path: Lambda → VPC → AWS Direct Connect → On-Prem Firewall → GCP

---

### **Next Steps**
1. If successful:
   - Update security group to restrict egress to Apigee-specific IPs/CIDR
2. If failed:
   - Collect VPC Flow Logs for analysis
   - Check for timeout errors (indicates routing issues)
   - Check for SSL errors (indicates certificate validation issues)

Let me know if you need help interpreting test results or require firewall rule examples!
