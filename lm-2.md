**Providing IAM policy JSON**

Since the user lacks command line access, I’ll give them the necessary JSON for the IAM role. I'll start with the trust policy for Lambda execution and the permissions for logging. The minimal trust policy will allow Lambda to assume the role, and I'll suggest adding the `AWSLambdaVPCAccessExecutionRole` managed policy for VPC access and logging. I can also show an example of an inline policy for CloudWatch logs and VPC ENI if needed. It seems the managed policy already covers essential permissions like AmazonSSMReadOnly.


Thought for 19 seconds


Below are the two JSON documents you can copy‑paste in the **IAM console** so you can create the execution role completely from the web UI—no CLI needed.

---

## 1. Trust relationship ( *Assume‑role policy* )

1. In **IAM → Roles → Create role** choose **“AWS service” → “Lambda”**.
2. When you get to **“Edit trust policy”**, replace the default block with this JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

This simply says “Lambda functions may assume this role.”

---

## 2. Permissions policy (inline or customer‑managed)

If your account **allows attaching AWS‑managed policies**, just tick **AWSLambdaVPCAccessExecutionRole** on the “Add permissions” page and you’re done—the policy already contains everything below.

If you need to paste the JSON yourself (for example, you can only use customer‑managed or inline policies), use **this** as the policy document:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VPCAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Logging",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### What each block does

| Statement     | Why it’s needed                                                                                   |
| ------------- | ------------------------------------------------------------------------------------------------- |
| **VPCAccess** | Lets the Lambda service create, view and delete the ENIs it needs to sit inside your VPC subnets. |
| **Logging**   | Allows the function to write to CloudWatch Logs so you can see the connectivity test results.     |

*(If your function also has to read secrets, call other AWS services, etc., you can attach additional policies later.)*

---

### Quick recap of console clicks

1. **IAM → Roles → Create role**
2. **Trusted entity = Lambda** → **Next**
3. **Add permissions**

   * **Option A** – Tick **AWSLambdaVPCAccessExecutionRole** (simplest).
   * **Option B** – Click **Create policy** → *JSON tab* → paste the **Permissions policy** above → **Next** → **Create policy** → back in role wizard, tick the policy you just made.
4. **Next** → give it a name, e.g. `lambda-apigee-check-role` → **Create role**.
5. Open the role → **Trust relationships** → **Edit trust policy** → paste the **Trust relationship JSON** above → **Update policy**.

That’s it—the role is ready to assign to your test Lambda in the console.
