Below is an **improved** outline for your playbook-style Confluence documentation, incorporating a dedicated section for **Service Control Policies (SCPs)**—particularly helpful when you want to **enforce** certain conditions (like encryption at rest or encryption in transit) across all accounts in your AWS Organization. By adding SCP checks, you can prevent the creation or modification of resources that do not comply with your encryption (or other security) requirements, *without* having to repeat the same policy logic separately for each service.

---

# 1. Overall Structure

Use the same base structure as before for each requirement, but add an **SCP Enforcement** section that addresses how to use SCPs to apply broad guardrails across all AWS accounts in your organization.

**Suggested Confluence Page Template** for each requirement:
1. **Title / Requirement Name**  
2. **Summary**  
3. **Requirement Details**  
4. **Terraform Implementation**  
5. **Manual Remediation Steps**  
6. **SCP Enforcement**  ← **(New Section)**  
7. **Verification**  
8. **References**  
9. **Last Updated / Contact**

---

# 2. Example Pages With SCP Section

Below are two illustrative examples: one for encryption in transit (SNS) and one for encryption at rest (EBS), including a sample SCP snippet.

## A. **CBC-AMS-SNS-2** – SNS Topic Must Have an Access Policy That Enforces Encryption in Transit

1. **Summary**  
   - Ensures that messages are encrypted (HTTPS) in transit, protecting data from interception.

2. **Requirement Details**  
   - SNS topics must reject unencrypted requests.  
   - Policy statement must enforce `aws:SecureTransport = true`.

3. **Terraform Implementation**  
   <details>
   <summary>Example Terraform Snippet</summary>

   ```hcl
   resource "aws_sns_topic" "secure_topic" {
     name             = "my-secure-topic"
     kms_master_key_id = var.kms_key_arn  # Optionally, also encrypt at rest
   }

   resource "aws_sns_topic_policy" "secure_topic_policy" {
     arn    = aws_sns_topic.secure_topic.arn
     policy = data.aws_iam_policy_document.sns_secure_policy.json
   }

   data "aws_iam_policy_document" "sns_secure_policy" {
     statement {
       sid       = "EnforceSecureTransport"
       actions   = ["SNS:Publish", "SNS:Subscribe", "SNS:Receive"]
       resources = [aws_sns_topic.secure_topic.arn]
       effect    = "Allow"

       condition {
         test     = "Bool"
         variable = "aws:SecureTransport"
         values   = ["true"]
       }

       principals {
         type        = "AWS"
         identifiers = ["*"]
       }
     }
   }
   ```
   </details>

4. **Manual Remediation Steps**  
   - Console: *SNS → Topic → Access Policy → Add Condition (`aws:SecureTransport = true`)*  
   - CLI: `aws sns set-topic-attributes --topic-arn <arn> --attribute-name Policy --attribute-value file://policy.json`

5. **SCP Enforcement**  
   - Add an SCP at the **AWS Organizations** level that **denies** any request to create or modify an SNS topic if the request does not include the `aws:SecureTransport` condition.  
   - **Sample SCP** (high-level):
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Sid": "DenyUnencryptedSNS",
           "Effect": "Deny",
           "Action": [
             "sns:CreateTopic",
             "sns:SetTopicAttributes"
           ],
           "Resource": "*",
           "Condition": {
             "Bool": {
               "aws:SecureTransport": "false"
             }
           }
         }
       ]
     }
     ```
   - This ensures no one in your org can create or update an SNS topic **without** enforcing secure transport.

6. **Verification**  
   - Terraform: run `terraform plan` and confirm your SNS topic includes the correct policy statement.  
   - CLI: `aws sns get-topic-attributes --topic-arn <arn>`  
   - Confirm no resource creation is possible if requests are unencrypted (SCP in effect).

7. **References**  
   - [AWS SNS Security Best Practices](https://docs.aws.amazon.com/sns/latest/dg/sns-security-best-practices.html)  
   - [AWS Organizations SCP Docs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)

8. **Last Updated / Contact**  
   - *Maintainer:* `<team_or_individual>`  
   - *Last Updated:* `MM/DD/YYYY`

---

## B. **CBC-AMS-EBS-2** – EBS Volume Encryption Must Be Enabled

1. **Summary**  
   - Ensures that data stored on EBS volumes is encrypted at rest with KMS.

2. **Requirement Details**  
   - EBS volumes must have `encrypted = true` and reference a valid KMS key.

3. **Terraform Implementation**  
   <details>
   <summary>Example Terraform Snippet</summary>

   ```hcl
   resource "aws_ebs_volume" "secure_volume" {
     availability_zone = var.default_az
     size             = 20
     encrypted        = true
     kms_key_id       = var.kms_key_arn
   }
   ```
   </details>

4. **Manual Remediation Steps**  
   - Ensure *Default Encryption* is enabled for EBS in your account. This automatically encrypts newly created volumes.  
   - For existing unencrypted volumes, create an encrypted snapshot from the volume or snapshot, then restore a new encrypted volume from that snapshot.

5. **SCP Enforcement**  
   - Create an SCP that **denies** creation of any EBS volume that does not specify encryption.  
   - **Example**:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Sid": "DenyEBSWithoutEncryption",
           "Effect": "Deny",
           "Action": [
             "ec2:CreateVolume",
             "ec2:ModifyVolume"
           ],
           "Resource": "*",
           "Condition": {
             "BoolIfExists": {
               "ec2:Encrypted": "false"
             }
           }
         }
       ]
     }
     ```
   - This effectively blocks any attempt to create or modify an EBS volume to “unencrypted = true.”

6. **Verification**  
   - Check the EBS encryption status in the AWS console or via:  
     ```bash
     aws ec2 describe-volumes --volume-id vol-xxxxxx
     ```
   - Attempt to create an unencrypted volume from the console or CLI—verify it fails due to the SCP.

7. **References**  
   - [AWS EBS Encryption Docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)  
   - [SCP Condition Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html)

8. **Last Updated / Contact**  
   - *Maintainer:* `<team_or_individual>`  
   - *Last Updated:* `MM/DD/YYYY`

---

# 3. Notes on Consolidating SCPs

- **Single SCP vs. Multiple**  
  - You can combine multiple conditions (e.g., for EBS, RDS, S3, SNS, SQS) into a single, more complex SCP if you want global enforcement. Alternatively, maintain separate SCPs for each resource type, which may be clearer to manage and debug.
  
- **Avoid Over-Restrictive Policies**  
  - Be careful with universal denies. If you need an exception, create an OU or a specific account that is exempt or define conditions to allow certain test or development scenarios.
  
- **Testing**  
  - Always test new SCPs in a non-production OU or account to avoid accidental lockouts.

---

# 4. Confluence Organization

- **Parent Page**: *CBC/Orca Security Requirements*  
  - Child Pages for Each Requirement  
    - *CBC-AMS-SNS-2 (Encryption in Transit for SNS)*  
    - *CBC-AMS-SQS-3 (Encryption in Transit for SQS)*  
    - *CBC-AMS-EBS-2 (EBS Encryption)*  
    - *CBC-AMS-RDS-1 (RDS Encryption)*  
    - *CBC-AMS-RDS-5 (RDS Logging/Monitoring)*  
    - *CBC-AMS-IAM-19 (Remove Unused IAM Credentials)*  
    - *CBC-AMS-Lambda-S3 (Lambda Encrypted at Rest)*  
    - *CBC-AMS-ECR-3 (ECR Encryption)*  
    - **Add an extra page for any global SCP references** (e.g., “Global SCPs for CBC/Orca Requirements”).

Each child page follows the same **playbook** format, with the new **SCP Enforcement** section added wherever relevant.

---

# 5. Final Tips

1. **Minimize Duplication:**  
   - If the same encryption condition is used for multiple services (e.g., `aws:SecureTransport = true` for SNS *and* SQS), you can store a single snippet in Confluence and link to it from each child page.  

2. **Leverage Default Encryption:**  
   - For EBS, S3, RDS, etc., configure default encryption wherever possible. This covers many encryption requirements without custom code.  

3. **Stay Up-to-Date:**  
   - Confluence is only useful if it’s current. Encourage your team to update the pages whenever new best practices or AWS features are released.

4. **Tie in Monitoring Tools:**  
   - For each requirement, mention how AWS Config or third-party scanners (like Orca) can detect non-compliant resources. Link those rules or dashboards in your Confluence pages.

---

### Wrapping Up
By incorporating **SCP checks** into each **CBC/Orca** security requirement page, you ensure consistent, *enforceable* guardrails across your organization—no repeated policy logic needed for each service or resource. This approach pairs well with your existing Terraform code and manual remediation steps, creating a holistic **playbook** that’s easy to reference and maintain.
