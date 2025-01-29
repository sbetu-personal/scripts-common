**Subject:** Security Concern: UDRs Allowing Direct Internet Access for SQL MI Subnets

Hello [Team],

I hope you’re doing well. I wanted to share a recent discovery regarding our Azure networking configuration that poses a potential security risk:

1. **Direct Internet Routes in SQL MI Subnets**  
   - I’ve identified several User-Defined Routes (UDRs) associated with our SQL Managed Instance subnets where the address prefix points to `Internet` as the next hop type.  
   - This effectively **bypasses** our on-premises BGP-based outbound controls and our external firewall, which means traffic from these subnets can go to the internet unfiltered.

2. **Lack of Azure Policy Enforcement**  
   - Currently, there’s no Azure Policy preventing route tables that specify `Internet` as the next hop. That allows anyone with sufficient permissions to create a UDR and circumvent our default outbound restrictions.

3. **KMS Activation Route**  
   - I’ve also found route tables that only contain a `KMS` IP address going directly to the internet. While we do need to allow KMS activation, it would be more secure to route that traffic through our hub and firewall, and then allow it outbound at the firewall layer. This approach ensures visibility and logging of KMS traffic rather than direct internet exposure.

I’ve discussed these findings with Mark (our architect), and he’s currently reviewing the configurations on his side. In the meantime, here are my initial recommendations:

- **Short-Term**:  
  - Identify and remove (or correct) any UDRs that point to `Internet` if not strictly required.  
  - For KMS traffic, consider re-routing through the hub firewall rather than allowing a direct path.
- **Long-Term**:  
  - Implement an **Azure Policy** to deny or audit route tables that set `0.0.0.0/0 → Internet` (or similar) unless there’s a justified exception.  
  - Adopt a more centralized firewall approach for all internet-bound traffic to align with our security strategy.

Please let me know if you have any questions or require more details. I’d be happy to set up a quick call or meeting to go through these issues in more depth.

Thank you,

**[Your Name]**  
[Your Title/Role]  
[Your Contact Information]


**Subject:** Security Concern: UDRs Allowing Direct Internet Access for SQL MI Subnets

Hello [Team],

I hope you’re doing well. I wanted to share a recent discovery regarding our Azure networking configuration that could pose a security risk:

---

### 1. **Direct Internet Routes in SQL MI Subnets**

- Several **User-Defined Routes (UDRs)** associated with our **SQL Managed Instance** subnets specify `Internet` as the **Next Hop** for `0.0.0.0/0` (or other prefixes).  
- **Impact**: Any traffic from those subnets is sent **directly to the internet**, **bypassing** both our on-premises BGP-based outbound controls and the external firewall.

---

### 2. **Azure Route Precedence & Firewall Bypass**

- In **Azure route precedence**:
  1. **User-Defined Routes** (UDR) override  
  2. **BGP routes**, which override  
  3. **Azure’s default system routes**.

- Because a UDR takes priority over BGP, **even if** our on-prem network advertises a default route (which is meant to block or control outbound internet), the presence of a UDR with **Next Hop: Internet** **overrides** that path. Essentially, we lose the inspection and governance typically provided by our external firewall.

---

### 3. **KMS Activation Route**

- I noticed route tables containing only a KMS IP address to the internet. While we do need KMS activation, **direct** internet egress from the subnet still bypasses our hub/firewall.  
- **Preferred Approach**: Route all outbound traffic (even for KMS) through our **hub** and **firewall**. Then allow KMS traffic **at the firewall level** for better visibility and logging.

---

### 4. **Azure Policy Gaps**

- We currently have no **Azure Policy** that audits or denies route tables specifying **Next Hop: Internet**.  
- As a result, anyone with sufficient permissions can create/modify these UDRs, inadvertently or intentionally bypassing our enterprise security posture.

---

### 5. **Next Steps & Recommendations**

1. **Short-Term Mitigation**  
   - **Identify & Remove** or modify any UDRs pointing to `Internet` unless there is a critical, documented exception.  
   - For KMS traffic, reconfigure the route to go through our **hub firewall**, then whitelist KMS endpoints on that firewall.

2. **Long-Term Governance**  
   - Implement an **Azure Policy** to:
     - Deny or alert on new routes that set `0.0.0.0/0 → Internet`.  
     - Enforce that all outbound traffic routes through our corporate or Azure Firewall for inspection.  
   - Ensure **RBAC** is in place so only the necessary teams can manage or apply route tables.

I’ve already discussed these findings with Mark (our architect), and he’s verifying our overall network design from his end. If you have questions or would like to discuss further, please feel free to let me know. I’m happy to schedule a brief session to walk through the details and coordinate any necessary changes.

Thank you,

**[Your Name]**  
[Your Title/Role]  
[Your Contact Information]


Your understanding of how these UDRs can circumvent your on-premises BGP routing and external firewall is correct. In Azure:

1. **Route Precedence**  
   - A user-defined route (UDR) will take precedence over both BGP-learned routes and Azure’s default system routes.  
   - If a route table associated with the subnet has **Next Hop: Internet** for `0.0.0.0/0` (or specific prefixes), traffic from those subnets will bypass your corporate firewall that’s normally enforced via BGP or ExpressRoute.

2. **Bypassing External Firewall**  
   - Because the UDR explicitly says “send traffic to the internet from here,” the packets do not go back on-prem or through your external firewall, effectively negating the forced tunneling or BGP-based outbound block your organization has in place.

3. **KMS Exception**  
   - Even if you need KMS traffic to reach a Microsoft endpoint, routing it **directly** to the internet—rather than through a hub or firewall—is a potential security blind spot.  
   - The recommended best practice is to route all outbound traffic (including KMS activation) through a central firewall or NVA for consistent monitoring, logging, and policy enforcement.

4. **Azure Policy Gaps**  
   - Without an Azure Policy or RBAC constraints that forbid or audit “Next hop: Internet” for UDRs, anyone with contributor-level access in that subscription can create or modify a route table to allow direct internet egress.

So, yes—your assessment that these UDRs effectively bypass your external firewall and BGP controls is accurate. The next step is typically to remove or restrict those routes unless there is a strong justification, and to introduce an Azure Policy (or a custom governance rule) to ensure routes to “Internet” are properly controlled.
