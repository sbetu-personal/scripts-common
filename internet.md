The **timeout error** occurs because the Lambda function is taking longer than the configured timeout (default: 3 seconds) to analyze multiple functions. Let's fix this with **3 key improvements**:

---

### **1. Increase Timeout & Memory**
- **Go to Lambda Configuration** → **General Configuration** → **Edit**:
  - **Timeout**: Set to **1-2 minutes** (e.g., 60 seconds).
  - **Memory**: Increase to **1024 MB** (improves CPU performance).

---

### **2. Optimize Code for Speed**
Here's the optimized code with:
- **Concurrent IAM policy fetching** (using threads)
- **Redundant API call removal**

```python
import boto3
import json
from botocore.exceptions import ClientError
from concurrent.futures import ThreadPoolExecutor

lambda_client = boto3.client('lambda')
iam_client = boto3.client('iam')
ec2_client = boto3.client('ec2')

def lambda_handler(event, context):
    function_names = event.get("function_names", [])
    vpc_id = event.get("vpc_id")
    
    if not vpc_id:
        return {"statusCode": 400, "body": "Error: Missing 'vpc_id'"}

    # Process functions in parallel (controlled concurrency)
    with ThreadPoolExecutor(max_workers=5) as executor:
        results = list(executor.map(lambda name: analyze_lambda(name, vpc_id), function_names)

    return {"statusCode": 200, "body": results}

def analyze_lambda(lambda_name, vpc_id):
    try:
        # Get Lambda config (single API call)
        config = lambda_client.get_function_configuration(FunctionName=lambda_name)
        
        # Parallelize slow operations
        with ThreadPoolExecutor() as executor:
            event_sources_future = executor.submit(get_event_sources, lambda_name)
            role_actions_future = executor.submit(get_role_permissions, config['Role'])
            
            services_used = set()
            event_sources = event_sources_future.result()
            role_actions = role_actions_future.result()

            # Process results
            services_used.update(role_actions)
            services_used.update(event_sources)

        # Check VPC endpoints
        endpoint_checks = check_vpc_endpoints(services_used, vpc_id)

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

def get_event_sources(lambda_name):
    services = set()
    paginator = lambda_client.get_paginator('list_event_source_mappings')
    for page in paginator.paginate(FunctionName=lambda_name):
        for mapping in page.get('EventSourceMappings', []):
            arn = mapping.get('EventSourceArn')
            if arn: services.add(arn.split(':')[2])
    return services

def get_role_permissions(role_arn):
    role_name = role_arn.split('/')[-1]
    actions = set()
    try:
        # Fetch policies in parallel
        with ThreadPoolExecutor() as executor:
            # Managed policies
            attached_policies = []
            paginator = iam_client.get_paginator('list_attached_role_policies')
            for page in paginator.paginate(RoleName=role_name):
                attached_policies.extend(page['AttachedPolicies'])
            
            # Inline policies
            inline_policies = []
            paginator = iam_client.get_paginator('list_role_policies')
            for page in paginator.paginate(RoleName=role_name):
                inline_policies.extend(page['PolicyNames'])

            # Process policies concurrently
            managed_futures = [executor.submit(process_managed_policy, p['PolicyArn']) for p in attached_policies]
            inline_futures = [executor.submit(process_inline_policy, role_name, p) for p in inline_policies]
            
            for future in managed_futures + inline_futures:
                actions.update(future.result())

    except ClientError as e:
        print(f"Error processing role {role_name}: {str(e)}")
    return actions

def process_managed_policy(policy_arn):
    actions = set()
    try:
        policy_doc = get_policy_document(policy_arn)
        for stmt in policy_doc.get('Statement', []):
            if stmt.get('Effect') == 'Allow':
                for action in ensure_list(stmt.get('Action', [])):
                    if ':' in action: actions.add(action.split(':')[0])
    except ClientError:
        pass
    return actions

def process_inline_policy(role_name, policy_name):
    actions = set()
    try:
        policy = iam_client.get_role_policy(RoleName=role_name, PolicyName=policy_name)
        for stmt in policy['PolicyDocument'].get('Statement', []):
            if stmt.get('Effect') == 'Allow':
                for action in ensure_list(stmt.get('Action', [])):
                    if ':' in action: actions.add(action.split(':')[0])
    except ClientError:
        pass
    return actions

# [Keep existing helper functions: check_vpc_endpoints, get_policy_document, etc.]
```

---

### **3. Critical IAM Permission Additions**
Add these permissions to your Lambda role to prevent timeouts caused by access denied errors:
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
        "ec2:DescribeVpcEndpoints",
        "sts:GetCallerIdentity"  # Needed for SDK region detection
      ],
      "Resource": "*"
    }
  ]
}
```

---

### **Why This Works**
1. **Concurrency**: Uses `ThreadPoolExecutor` to parallelize slow IAM and event source operations.
2. **Reduced API Calls**: 
   - Fetches all event source mappings in one paginated call
   - Processes inline/managed policies concurrently
3. **Timeout Buffer**: Increased timeout accommodates larger workloads.

---

### **Testing**
Invoke with a **small batch first** to verify:
```json
{
  "function_names": ["function-1", "function-2"],
  "vpc_id": "vpc-123456"
}
```

If you still get timeouts:
1. Reduce `max_workers` in `ThreadPoolExecutor`
2. Process fewer functions per invocation
3. Add CloudWatch logging to identify bottlenecks
