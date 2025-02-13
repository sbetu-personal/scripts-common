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


Below is a **sample email** you can send to your architect, mentioning that you spoke to AWS Support about why the policy is still recommended, and requesting an SCP for SNS/SQS. Feel free to adjust any specifics (names, teams, etc.) to fit your environment.

---

**Subject:** SCP for Enforcing HTTPS in SNS & SQS – AWS Support Confirmation

**Hello \<Architect Name\>,**

I hope you’re doing well. I recently **raised a case with AWS Support** regarding encryption in transit for SNS and SQS. Even though these services leverage TLS (HTTPS) by default, AWS recommended we **explicitly enforce** secure transport via a condition (`aws:SecureTransport = true`). Their main points were:

- It provides **defense-in-depth** and ensures absolutely no unencrypted HTTP requests (even in rare edge cases).  
- It satisfies **compliance** frameworks that require explicit enforcement of encryption in transit.  
- It’s **best practice** to have an SCP at the AWS Organizations level that automatically denies any attempt to create or modify SNS/SQS if unencrypted connections are used.

To **streamline this** (rather than having every application team manually apply the policy), I propose we **create a single SCP** that covers all SNS/SQS resources across our AWS Organization or relevant OU. This will remove the burden from individual teams and ensure consistent, org-wide enforcement.

**Would you be open** to setting up an SCP for this? We can **test** it first in a non-production OU/account to verify no legacy application is using HTTP by mistake. I can provide the sample JSON for the SCP that denies non-HTTPS traffic.

Please let me know if you have any questions or prefer a different approach. I’m happy to discuss further or hop on a quick call.

  
**Best regards,**  
_\<Your Name\>_  
_\<Your Title / Team\>_


Below is a concise **email** that references your **AWS support request**, **CBC requirement**, and your **ask** for an SCP to deny `aws:SecureTransport = false`. Since they already know how to write the policy, you can keep it high-level:

---

**Subject:** Request to Implement CBC Deny Policy (aws:SecureTransport)

**Hello \<Architect / Team\>,**

I hope you’re doing well. Following our **AWS support request** and in line with our **CBC requirement**, we need to **deny any unencrypted traffic** for SNS and SQS using `aws:SecureTransport = false`. Although AWS defaults to TLS for these services, implementing an SCP will ensure strict compliance and prevent any inadvertent HTTP usage.

Could we please **add an SCP** at the organizational level that denies requests where `aws:SecureTransport = false`? This will fully align us with our CBC mandate and provide defense-in-depth for our security posture.

Let me know if you have any questions or need additional info. Thank you!

  
**Best Regards,**  
\<Your Name\>  
\<Your Title / Team\>


Below is a **compiled explanation** of how **AWS’s default in-transit encryption** works, why you might still need a **Service Control Policy (SCP)** to explicitly deny unencrypted traffic, and how these two concepts fit together.

---

## 1. AWS “Default” Encryption in Transit
1. **TLS by Default**  
   For many AWS services (such as SNS, SQS, etc.), the **public endpoints** provided by AWS **use TLS/HTTPS** by default. If you’re using something like `https://sqs.us-east-1.amazonaws.com`, your traffic is automatically encrypted in transit with TLS.  
   
2. **No Simple ‘Off Switch’**  
   AWS generally does **not** provide a straightforward setting to disable TLS on these public endpoints. So, you often can’t just “turn off” encryption in transit at the click of a button in the AWS console.

3. **Why This Might Not Be Enough**  
   - **Edge Cases**: Some services (including SNS and SQS) technically allow HTTP endpoints (e.g., for certain legacy or custom configurations), even if that’s rare or non-default.  
   - **Subscriptions and Integrations**: You can sometimes set up subscriptions or endpoints on SNS that use `http://` instead of `https://`.  
   - **Compliance**: Certain security frameworks (HIPAA, PCI, etc.) require **explicit** enforcement of TLS at the organizational or resource level (beyond just the AWS default).

---

## 2. Why You Still Might Need an SCP (Service Control Policy)
1. **Defense-in-Depth**  
   An SCP that denies `aws:SecureTransport = false` stops any non-TLS traffic *before* it even reaches the resource. Even if AWS defaults to TLS, this is a **belt-and-suspenders** approach ensuring that no one can bypass the default with a misconfiguration.

2. **Organizational Enforcement**  
   An SCP applies at the AWS Organizations or OU level, so **all** accounts (and all services within them) are covered automatically. You don’t need to rely on each team or developer to manually add “deny HTTP” statements to every resource policy.

3. **Auditing & Compliance**  
   Auditors often look for a **formal policy** that explicitly disallows unencrypted connections. An SCP or resource policy that says “deny `aws:SecureTransport = false`” is a clear, auditable guardrail showing you have zero tolerance for HTTP traffic.

4. **Future-Proofing**  
   If AWS introduces new features or if someone tries to create a custom (non-public) endpoint that might allow HTTP, an SCP ensures these attempts are denied by default.

---

## 3. How SCPs and Resource Policies Interact
1. **SCP Is Evaluated First**  
   When a request is made (e.g., to create, update, or use SNS or SQS), AWS Organizations evaluates the SCP **before** looking at the resource policy. If the SCP denies the action (because it’s not using TLS), the request is blocked outright.

2. **No Changes to Existing Resource Policies**  
   An SCP **does not overwrite** or edit the resource policy. It simply **allows or denies** actions at the organizational level. If the SCP denies an action, it never even gets down to the resource policy stage.

3. **Existing Unrestricted Resource Policies**  
   Even if an SNS or SQS policy *does not* explicitly deny unencrypted traffic, the SCP will still block any HTTP requests. So, the resource policy doesn’t need to be updated for the deny to take effect—**the SCP alone** will handle it.

---

## 4. Conclusion: Why an SCP Is Often Best
1. **Simplicity**: A single SCP at the org or OU level is generally **simpler** than relying on every application team to configure their own resource policies.  
2. **Wide Coverage**: It ensures **all** accounts and services enforce encryption in transit—no exceptions.  
3. **Compliance**: It’s easier to demonstrate to auditors that you have a top-level, mandatory policy denying any unencrypted traffic.  
4. **Minimal Disruption**: Because AWS endpoints default to TLS, most existing workloads are unaffected. The SCP simply blocks any accidental or edge-case HTTP attempts.

In short, **AWS’s default encryption in transit** covers most normal use cases, but a **deny SCP** for `aws:SecureTransport = false` delivers organization-wide, explicit enforcement—closing any loopholes and satisfying strict compliance or security requirements.
