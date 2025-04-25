This happens because of double JSON serialization. Let's fix the output formatting by adjusting how we handle the response:

```python
import boto3
import json
from datetime import datetime
from botocore.exceptions import ClientError

# Initialize AWS clients
lambda_client = boto3.client('lambda')
iam_client = boto3.client('iam')
ec2_client = boto3.client('ec2')

def json_serializer(obj):
    """Custom JSON serializer for datetime objects"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

def lambda_handler(event, context):
    """Main Lambda handler"""
    function_names = event.get("function_names", [])
    vpc_id = event.get("vpc_id")
    
    if not vpc_id:
        return {
            "statusCode": 400,
            "body": {"error": "Missing vpc_id"}  # Return dict instead of string
        }

    try:
        results = [analyze_lambda(name, vpc_id) for name in function_names]
        return {
            "statusCode": 200,
            "body": results  # Let Lambda handle JSON serialization
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": {"error": str(e)}
        }

# (Keep all other functions the same as previous version except...)

def check_vpc_endpoints(services, vpc_id):
    """Check VPC endpoints for services"""
    if not services:
        return {}
    
    region = boto3.session.Session().region_name
    endpoint_checks = {}
    
    try:
        service_names = [f'com.amazonaws.{region}.{service}' for service in services]
        
        response = ec2_client.describe_vpc_endpoints(
            Filters=[
                {'Name': 'vpc-id', 'Values': [vpc_id]},
                {'Name': 'service-name', 'Values': service_names}
            ]
        )
        
        # Convert datetime to string before building response
        endpoints = []
        for endpoint in response.get('VpcEndpoints', []):
            sanitized = {k: v.isoformat() if isinstance(v, datetime) else v 
                        for k, v in endpoint.items()}
            endpoints.append(sanitized)
        
        endpoint_map = {e['ServiceName'].split('.')[-1]: e for e in endpoints}
        
        # Build clean response structure
        for service in services:
            if service in endpoint_map:
                endpoint_checks[service] = {
                    "exists": True,
                    "type": endpoint_map[service].get('VpcEndpointType'),
                    "state": endpoint_map[service].get('State'),
                    "id": endpoint_map[service].get('VpcEndpointId')
                }
            else:
                endpoint_checks[service] = {"exists": False}
                
    except ClientError as e:
        endpoint_checks = {"error": str(e)}
    
    return endpoint_checks
```

### Key Fixes:
1. **Removed Manual JSON Serialization**  
   Instead of using `json.dumps()`, let Lambda handle the JSON conversion automatically by returning Python dictionaries.

2. **Simplified Endpoint Response**  
   Created a cleaner output structure for VPC endpoints:
   ```json
   "VpcEndpointChecks": {
     "s3": {
       "exists": true,
       "type": "Gateway",
       "state": "available",
       "id": "vpce-123456"
     }
   }
   ```

3. **Consistent Data Types**  
   Ensure all values are JSON-serializable types (strings, booleans, numbers) before building the response.

### Updated IAM Permissions (Same as Before):
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
        "iam:GetPolicyVersion",
        "ec2:DescribeVpcEndpoints"
      ],
      "Resource": "*"
    }
  ]
}
```

### Sample Output Now:
```json
{
  "statusCode": 200,
  "body": [
    {
      "FunctionName": "my-function",
      "VpcAttached": false,
      "UsedServices": ["s3", "dynamodb"],
      "VpcEndpointChecks": {
        "s3": {
          "exists": true,
          "type": "Gateway",
          "state": "available",
          "id": "vpce-123456"
        },
        "dynamodb": {
          "exists": false
        }
      },
      "TargetVpcId": "vpc-123456"
    }
  ]
}
```

This version will produce clean JSON output without escaped characters or formatting issues.
