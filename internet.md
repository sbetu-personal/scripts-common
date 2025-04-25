Here's the enhanced solution to **check VPC endpoints for services used by your Lambda**:

---

### **1. Updated IAM Permissions**
Add `ec2:DescribeVpcEndpoints` to your Lambda execution role:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:GetFunctionConfiguration",
        "lambda:ListEventSourceMappings",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:GetPolicy",
        "iam:GetRolePolicy",
        "iam:GetPolicyVersion"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeVpcEndpoints",
      "Resource": "*"
    }
  ]
}
```

---

### **2. Enhanced Lambda Code**
```python
import boto3
import json
from botocore.exceptions import ClientError

lambda_client = boto3.client('lambda')
iam_client = boto3.client('iam')
ec2_client = boto3.client('ec2')

def lambda_handler(event, context):
    function_names = event.get("function_names", [])
    vpc_id = event.get("vpc_id")  # Mandatory field
    results = []

    if not vpc_id:
        return {
            "statusCode": 400,
            "body": "Error: Missing 'vpc_id' in event payload"
        }

    for name in function_names:
        result = analyze_lambda(name, vpc_id)
        results.append(result)

    return {
        "statusCode": 200,
        "body": results
    }

def analyze_lambda(lambda_name, vpc_id):
    try:
        config = lambda_client.get_function_configuration(FunctionName=lambda_name)
        
        # Get event source mappings (with pagination)
        paginator = lambda_client.get_paginator('list_event_source_mappings')
        source_mappings = []
        for page in paginator.paginate(FunctionName=lambda_name):
            source_mappings.extend(page.get('EventSourceMappings', []))
        
        role_actions = get_role_permissions(config['Role'])

        services_used = set()
        # Extract services from IAM role permissions
        for action in role_actions:
            if ":" in action:
                service = action.split(":")[0]
                services_used.add(service)
        
        # Extract services from event sources
        for mapping in source_mappings:
            arn = mapping.get('EventSourceArn')
            if arn:
                service = arn.split(':')[2]
                services_used.add(service)

        # Check VPC endpoints for each service
        endpoint_checks = {}
        region = boto3.session.Session().region_name
        for service in services_used:
            endpoint_service = f'com.amazonaws.{region}.{service}'
            try:
                response = ec2_client.describe_vpc_endpoints(
                    Filters=[
                        {'Name': 'vpc-id', 'Values': [vpc_id]},
                        {'Name': 'service-name', 'Values': [endpoint_service]}
                    ]
                )
                endpoints = response.get('VpcEndpoints', [])
                if endpoints:
                    endpoint = endpoints[0]
                    endpoint_checks[service] = {
                        "exists": True,
                        "endpoint_type": endpoint.get('VpcEndpointType'),
                        "state": endpoint.get('State')
                    }
                else:
                    endpoint_checks[service] = {"exists": False}
            except ClientError as e:
                endpoint_checks[service] = {"error": str(e)}

        return {
            "FunctionName": lambda_name,
            "VpcAttached": bool(config.get('VpcConfig', {}).get('SubnetIds')),
            "UsedServices": sorted(services_used),
            "VpcEndpointChecks": endpoint_checks,
            "TargetVpcId": vpc_id
        }
    except ClientError as e:
        return {"FunctionName": lambda_name, "Error": f"AWS Error: {str(e)}"}
    except Exception as e:
        return {"FunctionName": lambda_name, "Error": f"Unexpected Error: {str(e)}"}

# [Keep existing get_role_permissions and helper functions from previous code]
```

---

### **3. Key Improvements**
1. **VPC Endpoint Validation**  
   For each service in `UsedServices`, the script:
   - Constructs the AWS endpoint service name (e.g., `s3` → `com.amazonaws.us-east-1.s3`).
   - Checks if a VPC endpoint exists in the specified VPC for that service.
   - Reports the endpoint type (`gateway`/`interface`) and state (`available`, `pending`).

2. **Input Requirement**  
   The event must now include a `vpc_id` (the VPC where you plan to deploy the Lambda):
   ```json
   {
     "function_names": ["my-function"],
     "vpc_id": "vpc-123456"
   }
   ```

3. **Output Structure**  
   The response includes a new `VpcEndpointChecks` field:
   ```json
   {
     "FunctionName": "my-function",
     "VpcAttached": false,
     "UsedServices": ["s3", "dynamodb"],
     "VpcEndpointChecks": {
       "s3": {
         "exists": true,
         "endpoint_type": "gateway",
         "state": "available"
       },
       "dynamodb": {
         "exists": false
       }
     },
     "TargetVpcId": "vpc-123456"
   }
   ```

---

### **4. Limitations & Notes**
- **Service Name Mapping**: Some services (e.g., API Gateway) use different endpoint names.  
  Example: `apigateway` actions map to `execute-api` endpoints. You may need to manually adjust these cases.
- **Region-Specific**: The script checks endpoints in the same region as the Lambda function.
- **No Resource Impact**: Still read-only. Only uses `DescribeVpcEndpoints`.

---

### **5. Usage Example**
Invoke the Lambda with:
```json
{
  "function_names": ["my-lambda-function"],
  "vpc_id": "vpc-0abcdef123456789"
}
```

This tells you exactly which services need VPC endpoints before migrating your Lambda to the VPC.
