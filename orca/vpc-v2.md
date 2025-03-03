Here’s a refined playbook for **CBC-AWS-Lambda-1** with improvements for clarity, compliance, and actionable guidance:

---

## **Page Title**  
**CBC-AWS-Lambda-1: AWS Lambda Functions Must Be Attached to a VPC**  

---

## 1. **Summary**  
All AWS Lambda functions must be deployed within a **VPC** to enforce network isolation and compliance with frameworks like **PCI DSS, HIPAA, and GDPR**. Exceptions require formal approval.  

---

## 2. **Requirement Details**  
- **Requirement**: Lambda functions must have a **VPC configuration** (subnets and security groups).  
- **Why**:  
  - **Security**: Restrict network traffic to private subnets.  
  - **Compliance**: Prevent exposure of internal resources.  
- **Exceptions**:  
  - Lambdas accessing **only public endpoints** (e.g., external APIs) may be exempt.  
  - Submit exceptions via **Orca** with justification and compensating controls (e.g., enhanced logging).  

---

## 3. **Terraform Implementation**  
### 3.1 **New Lambda Functions**  
```hcl
resource "aws_lambda_function" "vpc_lambda" {
  function_name = "my-lambda"
  role          = aws_iam_role.lambda_exec.arn
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]  # Use private subnets
    security_group_ids = [aws_security_group.lambda_sg.id]  # Restrict ingress/egress
  }
}

# Attach the AWS-managed policy for VPC access
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
```  

### 3.2 **Existing Lambdas**  
Update via manual steps below.  

---

## 4. **Manual Remediation Steps**  
### 4.1 **Identify Non-Compliant Lambdas**  
**AWS CLI**:  
```bash
aws lambda list-functions --query "Functions[?VpcConfig.VpcId==null].FunctionName"
```  

### 4.2 **Add VPC Configuration**  
1. **Stop Lambda** (if critical):  
   - Use **AWS Console** → Lambda → Function → Throttle to 0 concurrency.  
2. **Update Configuration**:  
   ```bash
   aws lambda update-function-configuration \
     --function-name <FUNCTION_NAME> \
     --vpc-config SubnetIds=<SUBNET_ID_1>,<SUBNET_ID_2>,SecurityGroupIds=<SG_ID>
   ```  
3. **Test Connectivity**:  
   - Invoke the Lambda and check **CloudWatch Logs** for network errors.  
   - Validate access to private resources (e.g., RDS, Elasticache).  

### 4.3 **ServiceNow Change Control**  
- **Change Template**:  
  - **Title**: “VPC Attachment for Lambda [FUNCTION_NAME] (CBC-AWS-Lambda-1)”.  
  - **Details**:  
    - **Risk**: Potential downtime during VPC attachment.  
    - **Validation**: “Confirm Lambda function accesses required resources post-update”.  

---

## 5. **IAM Permissions (POD Team)**  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionConfiguration",
        "lambda:GetFunction",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
```  

---

## 6. **Verification**  
1. **AWS CLI**:  
   ```bash
   aws lambda get-function-configuration --function-name <FUNCTION_NAME> \
     --query "VpcConfig.VpcId"
   ```  
   *(Should return a VPC ID, not `null`)*.  
2. **Orca**: Confirm resolved alerts.  

---

## 7. **Troubleshooting**  
- **ENI Limits**: Check AWS account limits for Elastic Network Interfaces (ENIs).  
- **Timeouts**: Increase Lambda timeout if VPC attachment increases cold starts.  
- **Internet Access**: Deploy a NAT Gateway in the VPC if Lambda requires external access.  

---

## 8. **References**  
- [AWS Lambda VPC Guide](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html)  
- [VPC Design Best Practices](https://docs.aws.amazon.com/whitepapers/latest/serverless-multi-tier-architectures-api-gateway-lambda/vpc-design.html)  

---

**Improvements Summary**:  
1. Added **exception process** for public Lambdas.  
2. Included **Terraform IAM role policy attachment** for VPC access.  
3. Simplified **IAM policy** with JSON snippet.  
4. Added **connectivity testing steps** and **ServiceNow template**.  
5. Clarified **compliance frameworks** and **troubleshooting**.  

Let me know if further adjustments are needed!
