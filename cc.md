**Subject:** Request to Update Orca Policies for AWS Lambda Encryption  

Hi [Security Team],  

As discussed with Mark (Architect), we have reviewed the recent **CBC alerts in Orca** related to **"AWS Lambda function must be encrypted at rest."**  

Currently, AWS Lambda **encrypts function artifacts and environment variables at rest by default** using an AWS-managed KMS key (`aws/lambda`). While it is **recommended** to use a **customer-managed KMS key (CMK)**, it is **not mandatory** as long as encryption is in place.  

Since our compliance policy does not **strictly require** a customer-managed key, we request an update to the **Orca policy** to reflect this:  

- ✅ Allow AWS-managed KMS encryption (`aws/lambda`) to be considered **compliant**.  
- ✅ Retain alerts **only** for Lambda functions that have **no encryption at all** (if applicable).  
- ✅ Continue flagging cases where **CMK is required but missing** for specific high-security workloads (if applicable).  

This will help reduce unnecessary alerts while still ensuring that our security standards are met.  

Let us know if you need further details or if there’s any discussion required before making this change.  

Thanks,  
[Your Name]
