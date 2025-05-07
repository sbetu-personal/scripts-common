Here's a draft email and ServiceNow CHG template:

---

### **Email Draft**

**Subject:** VPC Connectivity Validation - Lambda to Apigee Test Successfully Completed  

**Body:**  
Hi Team,  

I've created and validated a Lambda function (test-apigee-vpc-connectivity) in our AWS sandbox to verify VPC connectivity to our private Apigee endpoint.  

**Key Details:**  
- Successfully tested HTTPS connectivity through VPC subnets  
- Confirmed traffic path: Lambda → VPC → DC → GCP Apigee  
- Temporary security group rules used (will be restricted post-validation)  

Next step: Submit CHG ticket to deploy this test function to non-prod environments for final validation.  

Attachments:  
1. Lambda code  
2. Test results (CloudWatch logs)  

Let me know if you'd like a demo or have questions.  

Best regards,  
[Your Name]  

---

### **ServiceNow CHG Template**

**Change Request Title:** AWS Lambda Deployment for Apigee VPC Connectivity Testing  

**Category:** Standard  
**Risk:** Medium  
**Implementation Window:** [Specify maintenance window]  

**Purpose:**  
Validate Lambda VPC connectivity to private Apigee endpoints before enforcing VPC requirement for all Lambdas  

**Implementation Steps:**  

1. **Pre-Change (15 mins):**  
   - Confirm target AWS account: [Account ID]  
   - Verify VPC (vpc-xxxxxx) has route to on-prem DC  
   - Confirm test security group (sg-xxxxxx) exists  

2. **Change Execution (20 mins):**  
   - Create Lambda function:  
     - Name: test-apigee-vpc-connectivity  
     - Runtime: Python 3.12  
     - Memory: 512MB  
     - Timeout: 1 min  
   - Configure VPC Settings:  
     - VPC: [Target VPC]  
     - Subnets: [Private Subnet 1], [Private Subnet 2]  
     - Security Group: sg-xxxxxx (allow outbound HTTPS)  
   - Attach IAM role: AWSLambdaVPCAccessExecutionRole  
   - Deploy test code (attached Python script)  

3. **Validation (15 mins):**  
   - Execute test event with Apigee URL  
   - Confirm HTTP 200 response in CloudWatch logs  
   - Verify VPC Flow Logs show successful egress  

4. **Post-Change (10 mins):**  
   - Document results in [Shared Drive Link]  
   - Notify security team for review  

**Backout Plan:**  
1. Delete Lambda function  
2. Remove temporary security group rules  
3. Revert IAM role permissions  

**Communication Plan:**  
- Email team upon successful validation  
- Immediate notification via Teams if issues occur  

---

Let me know if you need adjustments to either template!
