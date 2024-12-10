### Subject: Clarification on NSG Collector and Destination Prefix in Azure Setup Script

Hi [Vendor's Name],

I hope this email finds you well. I was reviewing the setup script you provided for the Orca implementation, and I have a couple of questions that I would appreciate your guidance on:

1. **NSG Collector Attachment**  
   In the script, the `nsg_collector` is created with its associated rules. However, I noticed that it is not explicitly attached to any subnet, network interface, or resource. Could you clarify where this NSG is intended to be applied? Should it be attached to a specific subnet, VM network interface, or another resource in our setup?

2. **Destination Prefix Concerns**  
   My Azure architect raised some concerns regarding the `destination-address-prefix` being set to `"*"`. As per his understanding, these NSGs should be targeting predefined private endpoints in the AWS 2.0 account. If that is the case, we should restrict the destination to those specific IP(s) rather than allowing all destinations (`*`). Could you confirm if this is the intended configuration? If there are specific IP(s) or ranges that should be used, please provide those details so we can tighten the rules accordingly.

Your clarification on these points will help ensure that our configuration aligns with best practices and remains secure.

Thank you for your assistance, and please let me know if additional details are required.

Best regards,  
[Your Full Name]  
[Your Job Title]  
[Your Contact Information]  

---

Let me know if you'd like further adjustments!
