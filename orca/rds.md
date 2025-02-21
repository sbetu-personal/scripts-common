Below is an **updated Confluence playbook** for **CBC-AWS-RDS-1: RDS Must Be Encrypted at Rest**, specifically focusing on **unencrypted RDS snapshots**. This version:

- Mentions the **POD Team** as the responsible party.  
- Requires **ServiceNow Change Control** for any planned remediation actions.  
- Removes the previous “Additional Notes” section, integrating relevant details into the main instructions.

---

## **Page Title**  
**CBC-AWS-RDS-1: RDS Must Be Encrypted at Rest – Snapshot Remediation**

---

## 1. **Summary**

This requirement ensures that **Amazon RDS instances and snapshots** are **encrypted at rest** using KMS keys. While many RDS instances may be encrypted already, **unencrypted snapshots** can pose a risk because they contain data in plaintext. This playbook provides the **POD Team** with guidance on remediating unencrypted RDS snapshots, including the need to **raise ServiceNow changes** and communicate with application owners.

---

## 2. **Requirement Details**

- **Requirement**: All RDS data—both live instances **and** snapshots—must be **encrypted at rest**.  
- **Why**:  
  - **Compliance**: Frameworks such as PCI DSS, HIPAA, SOX, etc., mandate data encryption at rest.  
  - **Security**: Orphaned or test snapshots with plaintext data are a liability if accessed by unauthorized parties.  

- **Current Alerts**:  
  - We have **71 alerts** from **CBC-AWS-RDS-1**, specifically highlighting **unencrypted DB snapshots** (`AwsRdsDbInstanceSnapshots`).  
  - Some snapshots appear **old** or **orphaned**, some are for **test** environments, and many may not be needed anymore.

---

## 3. **Terraform Implementation** (For Future Snapshots)

To prevent new unencrypted snapshots, ensure the RDS Terraform configuration for DB instances has `storage_encrypted = true`. For example:

```hcl
resource "aws_db_instance" "secure_rds" {
  identifier        = "my-secure-db"
  engine            = "mysql"
  engine_version    = "8.0"
  allocated_storage = 20
  instance_class    = "db.t3.medium"
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn
  # ...
}
```

> **Note**: This only addresses future snapshots for **encrypted** RDS instances. Existing **unencrypted** snapshots require manual action (below).

---

## 4. **Manual Remediation Steps: Unencrypted Snapshots**

### 4.1 Identify All Unencrypted RDS Snapshots

1. **AWS Console**:  
   - Go to **RDS → Snapshots** and check the **“Encrypted”** column. Filter for unencrypted snapshots.

2. **AWS CLI**:  
   ```bash
   aws rds describe-db-snapshots --query 'DBSnapshots[?Encrypted==`false`]' --output table
   ```
   Lists all unencrypted snapshots.

3. **Cross-check**:  
   - Compare the list of unencrypted snapshots with the **71** Orca/CBC alerts to ensure full coverage.

### 4.2 Investigate & Classify Snapshots

1. **Determine Age & Compliance**  
   - Check the creation timestamp.  
   - Confirm whether the snapshot belongs to a **SOX** environment or not by looking at tags (e.g., `Compliance=SOX`) or referencing the **IMC tool** to see the application profile.

2. **Retention Guidelines**  
   - Typically, **SOX** environments require snapshots up to **14 months**.  
   - **Non-SOX** systems might only need snapshots for 7 days.  
   - Validate these timelines with the **Storage Team** before proceeding.

3. **Raise a ServiceNow Change**  
   - For each snapshot (or batch of snapshots) you plan to remediate, open a **ServiceNow Change Request**.  
   - This ensures proper **communication** and **approval** with the relevant application teams.  
   - In the Change record, include details like snapshot ID, application name (if known), and the planned action (delete or encrypt).

### 4.3 Decide on Encryption vs. Deletion

After analyzing age, compliance needs, and potential ongoing usage:

1. **Delete the Snapshot**  
   - If the snapshot is **older** than the required retention period or confirmed **no longer needed**, simply delete it.  
   - This is ideal for **test** or **orphaned** snapshots with no valid reason to keep them.  
   - Execute the deletion once the ServiceNow change is approved, and communicate the action to the application owner (if applicable).

2. **Copy the Snapshot with Encryption**  
   - If the snapshot must be retained, create an **encrypted** copy and then **delete** the original unencrypted snapshot.  
   - Example CLI:
     ```bash
     aws rds copy-db-snapshot \
       --source-db-snapshot-identifier "arn:aws:rds:region:account-id:snapshot:old-unencrypted-snap" \
       --target-db-snapshot-identifier "my-secure-snapshot" \
       --kms-key-id "arn:aws:kms:region:account-id:key/key-id-or-alias" \
       --copy-tags
     ```
   - After verifying the new snapshot is encrypted, remove the old snapshot.  
   - Ensure you **update tags** (e.g., `Compliance=SOX`) if required and document the change in ServiceNow.

---

## 5. **Required IAM Role or Permissions**

The **POD Team** needs the following minimum IAM permissions:

1. **RDS Snapshot Management**  
   - `rds:DescribeDBSnapshots`, `rds:CopyDBSnapshot`, `rds:DeleteDBSnapshot`  
2. **Tagging**  
   - `rds:AddTagsToResource`, `rds:RemoveTagsFromResource`, `rds:ListTagsForResource`  
3. **KMS Key Access**  
   - `kms:Encrypt`, `kms:Decrypt`, `kms:DescribeKey`, `kms:CreateGrant` for the KMS keys in use.  
4. **ServiceNow Integration** (Outside AWS)  
   - The team must be able to **open** and **manage** change requests.  
   - This is organizational/process access rather than an AWS IAM permission, but still required operationally.

> **Optional**: If the team also needs to restore from snapshots or modify DB instances, they might need `rds:DescribeDBInstances`, `rds:RestoreDBInstanceFromDBSnapshot`, etc.

---

## 6. **SCP Enforcement** (Optional)

An **SCP** can be used to prevent creation of unencrypted DB snapshots if the RDS instance is already encrypted. For instance:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnencryptedRDSSnapshots",
      "Effect": "Deny",
      "Action": [
        "rds:CreateDBSnapshot",
        "rds:CopyDBSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "rds:StorageEncrypted": "false"
        }
      }
    }
  ]
}
```

Carefully test in **non-production** to avoid blocking critical snapshots if any RDS instance remains unencrypted.

---

## 7. **Verification**

1. **AWS Console** → **RDS → Snapshots**  
   - Ensure the “Encrypted” column reads “Yes” or that unnecessary snapshots are deleted.

2. **AWS CLI**  
   ```bash
   aws rds describe-db-snapshots --query 'DBSnapshots[?Encrypted==`false`]'
   ```
   - Confirm there are **no** unencrypted snapshots left (unless they are pending scheduled remediation).

3. **Orca / CBC Alerts**  
   - The **CBC-AWS-RDS-1** alerts for unencrypted snapshots should clear as each snapshot is either encrypted or removed.  
   - Validate with a **rescan** or ask the security team to confirm resolution in Orca.

4. **ServiceNow**  
   - Ensure each snapshot’s remediation is tracked under an approved **Change** record, with relevant communication and approvals documented.

---

## 8. **References**

- [AWS RDS Encryption Docs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html)  
- [AWS RDS Copying Snapshots](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CopySnapshot.html)  
- [KMS Integration with RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html#Overview.Encryption.Enabling)  
- [SCP Documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)

---

## 9. **Last Updated / Contact**

- **Maintainer:** POD Team  
- **Last Updated:** [MM/DD/YYYY]  
- **Contact:** [Slack Channel / Email / Jira Board / ServiceNow Assignment Group]

---

### End of Document

This Confluence playbook ensures the **POD Team** follows **ServiceNow Change Control** processes, investigates **SOX vs. non-SOX** requirements, and either deletes or encrypts RDS snapshots to meet **CBC-AWS-RDS-1**.
