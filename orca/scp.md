Below is a **sample email** you could send to your architect, politely requesting that an SCP be created to enforce secure transport for SNS and SQS. Feel free to tweak the tone or details to match your internal processes and naming conventions.

---

**Subject:** Request to Implement SCP for Enforcing HTTPS in SNS & SQS

**Hello \<Architect Name\>,**

I hope you’re doing well. Following our recent discussions on ensuring encryption in transit for AWS services, I’d like to propose a more streamlined approach for **SNS** and **SQS** security. Currently, we have to rely on each application team to manually configure or enforce `aws:SecureTransport = true` at the resource level. This is both repetitive and prone to human error.

Instead, **would it be possible to create an SCP** (Service Control Policy) at the Organizational Unit level that **denies** the creation or modification of SNS and SQS resources **unless** `aws:SecureTransport = true` is enforced? This would remove the burden from individual application teams and ensure consistent, org-wide compliance without repeated manual steps. 

**Key points:**
- **SQS and SNS can technically accept HTTP** traffic, even though HTTPS is default. The SCP ensures absolutely no unencrypted traffic is allowed.
- It simplifies compliance with frameworks requiring explicit encryption in transit (e.g., PCI DSS, HIPAA).
- It provides a single guardrail rather than repeating policies for each resource or team.
- We can initially test the SCP in a non-production OU/account to confirm there are no unexpected impacts.

If this approach aligns with our security roadmap, **please let me know your thoughts** on next steps. I’m happy to provide sample SCP JSON or help with testing to ensure a smooth rollout.

Thank you for considering this, and please let me know if you have any concerns or questions.

  
**Best regards,**  
_\<Your Name\>_  
_\<Your Title / Team\>_
