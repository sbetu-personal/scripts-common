Below is a **finalised email template + POD‑team checklist** that matches your environment:

* The account contains **exactly two VPCs**, each representing an organisational **domain** (e.g., *App‑Domain* and *Shared‑Services*).  
* Both VPCs have subnets in **two regions** (Region‑A and Region‑B).  
* Outbound traffic leaves through **Direct Connect → on‑prem firewall** (no NAT).  

---

## 1 · Email Template (Two‑Domain VPC Model)

**Subject**  
`Action Required: Attach <Lambda‑Function‑Name> to Domain VPC (CBC‑AWS‑Lambda‑1) – Dependency Info Needed`

---

Hi **<App Owner Name / Team>**,  

To meet security control **CBC‑AWS‑Lambda‑1**, every Lambda in **Account <123456789012>** must run inside one of our two **Domain VPCs**:

| Domain | VPC ID | Regions with Subnets |
|--------|--------|----------------------|
| **App‑Domain** | `vpc‑aaaa1111` | Region‑A & Region‑B |
| **Shared‑Services** | `vpc‑bbbb2222` | Region‑A & Region‑B |

Our scan shows **<Lambda‑Function‑Name>** (currently in **<us‑east‑1 / us‑west‑2>**) is **not** attached to a VPC.

Because these VPCs route outbound traffic via **Direct Connect** and the on‑prem firewall (no NAT), we need the details below before scheduling the change:

| Item we need | Your Input |
|--------------|-----------|
| **Target Domain VPC** | App‑Domain `vpc‑aaaa1111` / Shared‑Services `vpc‑bbbb2222` |
| **Subnets (region‑specific)** | e.g., Region‑A `subnet‑01…`, `subnet‑02…` |
| **Security Group** | `sg‑…` (outbound 443 to DX path) |
| **AWS services the Lambda calls** | SQS, SNS, DynamoDB, S3, Secrets Manager, etc. |
| **External URLs (if any)** | hostname(s) → so we can confirm firewall allow‑list |
| **Preferred change window** | <date / time> |

> **Heads‑up**  
> * After we attach the Lambda to a VPC, it will reach AWS services through **Interface VPC Endpoints** or the **DX route**.  
> * External calls succeed only if the on‑prem firewall already permits the destination.

**Next Steps**

1. POD Team opens a **ServiceNow Change** once we receive your inputs.  
2. We attach the VPC config, run a test invoke, and verify connectivity.  
3. We notify you and close the change.

Please reply by **<DD MMM YYYY>** to keep us on track for the CBC audit.  
Questions? Ping **#pod‑team‑support** Slack or reply here.

Thanks!

Best regards,  
**<Your Name>**  
POD Team – Cloud Security & Compliance  
<email> | <Slack>

---

## 2 · POD Team Checklist (Two‑Domain / DX Path)

| ✔︎ | Task |
|----|------|
| □ | Identify Lambda’s **region**; choose matching subnets in the selected **Domain VPC**. |
| □ | Confirm SG allows outbound **443** to DX route; inbound as required (rare). |
| □ | Collect list of AWS services + external URLs from owner. |
| □ | **Interface VPC Endpoints** present for SQS, SNS, DynamoDB, S3, Secrets Manager, etc.; create if missing. |
| □ | Verify subnet route table: 0.0.0.0/0 → DX TGW/VGW → on‑prem firewall. |
| □ | Check on‑prem firewall allow‑list for any external hostnames. |
| □ | Ensure Lambda execution role includes `AWSLambdaVPCAccessExecutionRole` (ENI permissions). |
| □ | Raise **ServiceNow Change** with rollback & test steps. |
| □ | `update-function-configuration` (or Console) → add `VpcConfig`. |
| □ | **Smoke‑test**: invoke Lambda; watch CloudWatch Logs for connectivity success. |
| □ | Troubleshoot SG, endpoint DNS, DX route, FW rules if needed. |
| □ | Close change, notify owner, re‑scan to clear CBC‑AWS‑Lambda‑1 alert. |

---

Feel free to add internal ticket numbers, escalation contacts, or domain‑specific terminology as needed.
