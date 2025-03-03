Below is a **Confluence playbook** for **CBC-AWS-Lambda-1**, requiring that **AWS Lambda functions** be attached to a **VPC**. This ensures network isolation, controlled access to internal services, and compliance with security frameworks that mandate resources remain within an approved subnet/security group context.

---

## **Page Title**  
**CBC-AWS-Lambda-1: AWS Lambda Function Must Be Attached to a VPC**

---

## 1. **Summary**

This requirement states that each **AWS Lambda function** must be **associated** with a **VPC** (including at least one subnet and one security group). Running in a VPC provides:

- **Network Isolation**: The Lambda cannot communicate directly to the public internet unless it goes through NAT gateways or configured routes.  
- **Access to Private Resources**: The Lambda can securely connect to private RDS instances, ElastiCache clusters, or other resources that aren’t publicly accessible.

---

## 2. **Requirement Details**

- **Requirement**: All Lambda functions must have a **VPC configuration** specifying subnet(s) and security group(s).  
- **Why**:  
  - **Security**: Constrains traffic to controlled environments.  
  - **Compliance**: Many frameworks require internal resources be accessible only through private subnets, preventing public exposure.  
- **Implications**: If a Lambda is found **not** attached to a VPC, it must be updated to **include** the correct VPC configuration.  

---

## 3. **Terraform Implementation**

If you are deploying Lambdas with Terraform, add a `vpc_config` block to specify **subnets** (in private subnets) and a **security group** that enforces the correct ingress/egress rules.

```hcl
resource "aws_lambda_function" "vpc_lambda" {
  function_name = "my-vpc-lambda"
  runtime       = "python3.9"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_exec.arn
  
  # Reference your Lambda code via local file or S3
  filename      = "lambda_code.zip"
  source_code_hash = filebase64sha256("lambda_code.zip")

  # VPC configuration
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Environment variables, memory, timeout, etc.
  environment {
    variables = {
      EXAMPLE = "vpc-lambda"
    }
  }
}
```

> **Note**: Ensure the **Lambda execution role** has permissions to manage network interfaces (ENIs). Typically, this includes the `ec2:CreateNetworkInterface`, `ec2:DescribeNetworkInterfaces`, `ec2:DeleteNetworkInterface` actions if you rely on AWS-managed roles or custom roles.

---

## 4. **Manual Remediation Steps**

If you have an **existing** Lambda function **not** attached to a VPC:

1. **Identify Non-Compliant Lambdas**  
   - AWS Console: Go to **Lambda → Functions**. Look under “Network” for each function. If it says “No VPC,” it’s non-compliant.  
   - AWS CLI:
     ```bash
     aws lambda list-functions --query "Functions[?VpcConfig==null].FunctionName"
     ```
     or check `VpcConfig` for each function.

2. **Modify the Lambda to Add VPC Configuration**  
   - **AWS Console**:  
     1. Select the function → “Configuration” tab → “Network” → Edit.  
     2. Choose the **VPC** you want, select **private subnets**, and **security groups**.  
     3. Save. This may cause a brief update or redeployment of your Lambda.  
   - **AWS CLI**:
     ```bash
     aws lambda update-function-configuration \
       --function-name my-function \
       --vpc-config SubnetIds=subnet-abc123,SecurityGroupIds=sg-xyz789
     ```

3. **ServiceNow Change Control** (If Required)  
   - If the Lambda is in production, you might need to open a **Change Request** (ServiceNow or your org’s system) to schedule the update.  
   - Communicate the change to the application owner to confirm no disruption.

4. **Test Connectivity**  
   - After attaching the Lambda to a VPC, confirm it can still reach any external services needed (possibly via NAT Gateway) and that it can access private resources as intended.

---

## 5. **Required IAM Role or Permissions**

To attach or modify a Lambda’s VPC configuration, the **POD Team** or whoever is remediating needs:

1. **Lambda Permissions**  
   - `lambda:GetFunctionConfiguration`, `lambda:UpdateFunctionConfiguration`, `lambda:ListFunctions`, etc.  
2. **EC2 VPC Permissions**  
   - Typically included in the AWS-managed `AWSLambdaVPCAccessExecutionRole`, but if customizing, you might need `ec2:DescribeVpcs`, `ec2:DescribeSubnets`, `ec2:DescribeSecurityGroups`, `ec2:CreateNetworkInterface`, etc.  
3. **Network & Security Group Access**  
   - The user must have knowledge of which private subnets and security groups are valid for the function.  

---

## 6. **SCP Enforcement** (Optional)

An **SCP** could, in theory, **deny** creating or updating a Lambda if it doesn’t include `vpc_config`. However, AWS does not offer a direct condition key (like `lambda:VpcConfig`) to reliably enforce it at the org level. This is typically better handled by:

- **Preventive**: Mandate that all Lambdas are deployed via Terraform with `vpc_config`.  
- **Detective**: Use a tool like AWS Config or Orca to scan for Lambda functions that lack a VPC.  

Still, if you wanted to attempt an SCP, you’d need to block certain API calls (`lambda:CreateFunction`, `lambda:UpdateFunctionConfiguration`) unless they meet specific tag conditions or naming conventions that imply a VPC. This can be cumbersome and is less straightforward.

---

## 7. **Verification**

1. **AWS Console** → **Lambda → Functions**  
   - Check each function’s “Configuration” → “Network” section. Confirm it shows the correct VPC, subnets, and security groups.

2. **AWS CLI**  
   ```bash
   aws lambda list-functions --query "Functions[].{Name:FunctionName, VPC:VpcConfig}"
   ```
   - Verify that `VpcConfig` is **not null** and references valid `SubnetIds` and `SecurityGroupIds`.

3. **Orca / CBC Rescan**  
   - Validate that **CBC-AWS-Lambda-1** alerts clear or reduce after you attach each function to a VPC.

---

## 8. **References**

- [AWS Lambda VPC Configuration Docs](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html)  
- [AWSLambdaVPCAccessExecutionRole Policy](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html#permissions-lambda-vpc)  
- [AWS Config – Managed Rules for Lambda](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)

---

## 9. **Last Updated / Contact**

- **Maintainer**: POD Team  
- **Last Updated**: [MM/DD/YYYY]  
- **Contact**: [Slack Channel / Email / Jira Board / ServiceNow Assignment Group]

---

### End of Document

With this **CBC-AWS-Lambda-1** playbook, you can identify Lambdas **not attached** to a VPC, remediate them by updating their **network configuration**, and verify the changes to maintain compliance.
