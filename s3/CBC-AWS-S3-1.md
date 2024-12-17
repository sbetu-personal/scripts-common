

---

# Achieving Compliance with CBC-AWS-S3-1: Encrypting Existing S3 Buckets and Objects

## Objective
To ensure compliance with the CBC-AWS-S3-1 security policy, which mandates that all objects stored in Amazon S3 buckets are encrypted using server-side encryption (SSE) methods such as AES-256 (SSE-S3) or AWS KMS (SSE-KMS).

This document provides a step-by-step process for enabling and enforcing encryption on existing S3 buckets and objects. It also discusses the operational impact, potential risks, and guidance for ongoing compliance monitoring.

---

## Step-by-Step Process

### Step 1: **Audit Existing S3 Buckets and Objects**
1. **List All Buckets**:  
   Use the AWS CLI or Management Console to list all S3 buckets.
   ```bash
   aws s3 ls
   ```

2. **Identify Unencrypted Buckets**:  
   Check if default bucket-level encryption is enabled.
   ```bash
   aws s3api get-bucket-encryption --bucket <bucket-name>
   ```
   If this command returns an error or shows no encryption configuration, the bucket does not enforce default encryption for newly uploaded objects.

3. **Identify Unencrypted Objects**:  
   Objects can be individually encrypted or unencrypted, regardless of the bucket’s default settings. To identify which objects are currently unencrypted, consider the following approaches:
   
   - **S3 Inventory**:  
     Configure an S3 Inventory report for each bucket. The inventory report can include encryption status for each object. Once generated, the report (usually in CSV or Parquet format) will indicate whether objects are encrypted. Refer to [AWS documentation on S3 Inventory](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory.html) for instructions.
   
   - **Scripted Checks with AWS CLI**:  
     For smaller buckets, you can list all objects and programmatically check each one using `head-object`:
     ```bash
     aws s3api list-objects --bucket <bucket-name> --query "Contents[].Key" --output text | \
     while read key; do
       encryption=$(aws s3api head-object --bucket <bucket-name> --key "$key" --query "ServerSideEncryption" --output text 2>/dev/null)
       if [ "$encryption" == "None" -o "$encryption" == "NoneType" ]; then
         echo "Unencrypted object: $key"
       fi
     done
     ```
     This approach may be slow for large buckets but is effective for quickly identifying unencrypted objects without setting up S3 Inventory.

---

### Step 2: **Enable Default Encryption on S3 Buckets**
1. **Set Default Bucket Encryption**:
   Configure the bucket to use AES-256 (SSE-S3) or AWS KMS (SSE-KMS) encryption for all new uploads.
   
   - **AES-256 (SSE-S3)**:
     ```bash
     aws s3api put-bucket-encryption \
       --bucket <bucket-name> \
       --server-side-encryption-configuration '{
         "Rules": [
           {
             "ApplyServerSideEncryptionByDefault": {
               "SSEAlgorithm": "AES256"
             }
           }
         ]
       }'
     ```
   
   - **AWS KMS (SSE-KMS)**:
     ```bash
     aws s3api put-bucket-encryption \
       --bucket <bucket-name> \
       --server-side-encryption-configuration '{
         "Rules": [
           {
             "ApplyServerSideEncryptionByDefault": {
               "SSEAlgorithm": "aws:kms",
               "KMSMasterKeyID": "<kms-key-id>"
             }
           }
         ]
       }'
     ```
   
2. **Verify Encryption Settings**:
   ```bash
   aws s3api get-bucket-encryption --bucket <bucket-name>
   ```
   Confirm that the returned configuration matches the intended encryption method.

---

### Step 3: **Re-Encrypt Existing Unencrypted Objects**
Existing unencrypted objects must be re-uploaded or copied with encryption enabled. There is no in-place encryption toggle; you must rewrite the objects.

1. **Manual Re-Encryption with aws s3 cp**:  
   For smaller buckets, you can run:
   ```bash
   aws s3 cp s3://<bucket-name>/ s3://<bucket-name>/ --recursive --sse AES256
   ```
   Or for KMS:
   ```bash
   aws s3 cp s3://<bucket-name>/ s3://<bucket-name>/ --recursive --sse aws:kms --sse-kms-key-id <kms-key-id>
   ```
   This command copies each object onto itself, applying the specified encryption. It will skip already encrypted objects if they are identical, but verify the output and logs carefully.

2. **S3 Batch Operations for Large-Scale Re-Encryption**:
   For buckets with millions of objects, consider using [S3 Batch Operations](https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html):
   - Create a manifest (CSV) using an S3 Inventory that lists only unencrypted objects.
   - Use S3 Batch Operations with a Copy job to re-upload objects with the desired server-side encryption.
   This approach is scalable and can be monitored and retried as needed.

3. **Verify Re-Encryption**:
   After the operation, verify that objects are now encrypted:
   ```bash
   aws s3api head-object --bucket <bucket-name> --key <object-key>
   ```
   Check the `ServerSideEncryption` field. It should return `AES256` or `aws:kms` depending on your chosen method.

---

### Step 4: **Monitor and Enforce Compliance**
1. **Enable AWS Config Rules**:
   - Use the `s3-bucket-server-side-encryption-enabled` AWS Config rule to continuously monitor and report non-compliant S3 buckets.
   - Enable automatic remediation to enforce encryption for newly created buckets if desired.

2. **Use Service Control Policies (SCPs)**:
   - Implement an SCP to ensure that future S3 buckets cannot be created without server-side encryption.
   - Test the SCP to confirm that attempts to create unencrypted buckets fail, helping ensure ongoing compliance.

---

## Impact of the Process

### Positive Impacts
1. **Data Security**:  
   All objects are encrypted, protecting sensitive data from unauthorized access.
   
2. **Compliance**:  
   Aligns your environment with CBC-AWS-S3-1 and supports other regulatory or internal audit requirements.
   
3. **Simplified Auditing and Monitoring**:  
   AWS Config, S3 Inventory, and S3 Batch Operations facilitate easier compliance checks and ongoing governance.

### Potential Risks and Challenges
1. **Downtime/Performance Impact**:  
   Re-encryption operations can be time-consuming and may affect data availability, especially with large-scale migrations.
   
2. **Costs**:  
   Re-writing objects may incur additional data transfer and storage costs.
   
3. **Operational Overhead**:  
   Large environments require careful planning and automation, particularly when dealing with millions of objects.
   
4. **IAM and KMS Permissions**:  
   Ensure the correct IAM permissions for both the S3 and KMS services. If using SSE-KMS, verify that principals have appropriate access to the KMS key.

---

## Summary
By following these steps, you can bring all existing unencrypted S3 buckets and objects into compliance with the CBC-AWS-S3-1 security policy. Ongoing monitoring using AWS Config, preventive measures like SCPs, and proper IAM/KMS configuration will ensure sustained compliance and robust data protection.
