Your Lambda deployment package is ready. You can download it using the link below:

📦 [Download lambda_lambda_audit.zip](sandbox:/mnt/data/lambda_lambda_audit.zip)

---

### 📋 IAM Role Policy (attach to Lambda execution role)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:GetFunctionConfiguration",
        "lambda:GetPolicy",
        "lambda:ListEventSourceMappings",
        "iam:ListAttachedRolePolicies",
        "iam:GetPolicy",
        "iam:GetPolicyVersion"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 🚀 How to Deploy:

1. Go to **AWS Lambda > Create function**
2. Choose “Author from scratch”
3. Upload the ZIP under “Function code”
4. Assign the IAM role with the policy above
5. In the test event, use:
```json
{
  "function_names": ["your-lambda-1", "your-lambda-2"]
}
```

Let me know when you’ve got output, and I’ll help map required VPC endpoints!
