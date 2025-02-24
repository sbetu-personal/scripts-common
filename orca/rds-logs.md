Here’s a **revised playbook** incorporating your clarifications:

---

## **Page Title**  
**CBC-AWS-IAM-20: IAM User Access Keys Must Be Rotated Every 90 Days**  

---

## 1. **Summary**  
**IAM user access keys** must be rotated every **90 days** to mitigate security risks. **Orca** detects non-compliant keys. The **POD Team** validates alerts with application teams, rotates keys, or raises exceptions for **Disaster Recovery (DR)** use cases. **ServiceNow Changes** are required for **all environments** (Prod/Non-Prod).  

---

## 2. **Process Overview**  
1. **Orca Alert**: Flags IAM user access keys >90 days old (**CBC-AWS-IAM-20**).  
2. **POD Team Action**:  
   - **Validate with App Team**: Confirm if the key is used for **DR**.  
   - **Rotate** (if non-DR) or **Request Exception** (if DR).  
3. **Change Management**: Raise a **ServiceNow Change** for key rotation in **any environment**.  

---

## 3. **Steps for POD Team**  

### 3.1 **Review Orca Alert**  
- **Alert Details**:  
  - **Key ID**: `AKIAXXXXXXXXXXXXXX`  
  - **IAM User**: `user-name`  
  - **Creation Date**: `YYYY-MM-DD`  

### 3.2 **Investigate DR Usage**  
**Contact Application Team** with this template:  
> *“Orca Alert CBC-AWS-IAM-20 flags key [Key ID] for IAM user [User Name] as older than 90 days. Is this key used for Disaster Recovery (DR)? If yes, provide justification. If no, coordinate rotation.”*  

#### **Decision Flow**:  
- **Not DR → Rotate Key** (Proceed to [3.3](#33-rotate-key)).  
- **DR → Submit Exception** (Proceed to [3.4](#34-exception-process-for-dr-keys)).  

---

### 3.3 **Rotate Key**  
#### **Steps**:  
1. **Create New Key**:  
   ```bash  
   aws iam create-access-key --user-name <USERNAME>  
   ```  
   - Save the new `AccessKeyId` and `SecretAccessKey`.  

2. **Update Application/Service**:  
   - Update secrets in **AWS Secrets Manager**, **Parameter Store**, or app configs.  

3. **Disable Old Key**:  
   ```bash  
   aws iam update-access-key --user-name <USERNAME> --access-key-id <OLD_KEY_ID> --status Inactive  
   ```  

4. **Delete Old Key** (After 24-48h validation):  
   ```bash  
   aws iam delete-access-key --user-name <USERNAME> --access-key-id <OLD_KEY_ID>  
   ```  

#### **Raise ServiceNow Change**:  
- **Title**: “Rotation of IAM Key [Key ID] for Compliance (CBC-AWS-IAM-20)”.  
- **Details**:  
  - **Environment**: Specify Prod/Non-Prod (changes required for all).  
  - **Validation Steps**: E.g., “Verify DR backups post-rotation”.  

---

### 3.4 **Exception Process for DR Keys**  
If the key is **DR-critical** and rotation is not feasible:  
1. **Submit Orca Exception**:  
   - **Reason**: E.g., “Key used for legacy DR backups; rotation breaks automation”.  
   - **Compensating Controls**:  
     - Key usage restricted to specific IPs.  
     - Key activity monitored via CloudTrail.  
   - **Expiration**: Max 1 year (revalidate annually).  

---

## 4. **Verification**  
1. **Orca**: Confirm alert is resolved (rotated) or marked as exception.  
2. **Spot Check**:  
   ```bash  
   # List active keys older than 90 days  
   aws iam list-access-keys --query 'AccessKeyMetadata[?Status==`Active` && CreateDate<=`2023-10-01`]'  
   ```  

---

## 5. **IAM Permissions for POD Team**  
```json  
{  
  "Version": "2012-10-17",  
  "Statement": [  
    {  
      "Effect": "Allow",  
      "Action": [  
        "iam:ListAccessKeys",  
        "iam:CreateAccessKey",  
        "iam:UpdateAccessKey",  
        "iam:DeleteAccessKey"  
      ],  
      "Resource": "*"  
    }  
  ]  
}  
```  

---

## 6. **FAQ**  
**Q: What if the application team doesn’t respond?**  
- **Action**: Escalate to the POD Team Lead after **3 business days**.  

**Q: The key is already deleted, but Orca still shows an alert.**  
- **Action**: Trigger an Orca rescan or wait for the next scan cycle.  

---

## 7. **Contact**  
- **POD Team**: [#slack-channel] | [Email]  
- **Orca Exceptions**: [Link to internal process].  

---

### **Key Adjustments**:  
1. **Removed Certificates**: Focused only on IAM user keys (since the alert doesn’t cover certs).  
2. **All Environments**: Explicitly stated that ServiceNow changes apply to **all** environments.  
3. **Simplified Flow**: No Terraform/SCP sections; only actionable steps for the POD Team.  
Let me know if you need further tweaks!
