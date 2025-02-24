Here’s a refined version of your Confluence playbook with improvements for clarity, accuracy, and completeness:

---

## **Page Title**  
**CBC-AWS-RDS-9: RDS Clusters & Instances Must Have Logging Enabled and Exported to CloudWatch Logs**

---

## 1. **Summary**

This requirement ensures **Amazon RDS clusters and instances** export **database logs** (e.g., error, audit, slow query) to **CloudWatch Logs** for enhanced visibility into security events, compliance auditing, and operational troubleshooting. Centralized logging is mandated by frameworks like **PCI DSS, HIPAA, and SOX**.

---

## 2. **Requirement Details**

- **Requirement**: Enable logging and export logs to CloudWatch for all RDS clusters/instances.  
- **Why**:
  - **Compliance**: Required for frameworks like PCI DSS, HIPAA, and SOX.  
  - **Security**: Detect anomalies or unauthorized access.  
  - **Operational Health**: Accelerate troubleshooting of performance issues.  

- **Affected Resources**:
  - **`AwsRdsDbInstance`** (MySQL, PostgreSQL, SQL Server)  
  - **`AwsRdsDbCluster`** (Aurora clusters)  

- **Log Types by Engine**:
  | **Engine**       | **Supported Log Types**                                  |
  |-------------------|----------------------------------------------------------|
  | MySQL/Aurora      | `error`, `general`, `slowquery`, `audit`                 |
  | PostgreSQL        | `postgresql`, `upgrade`                                  |
  | SQL Server        | `error`, `agent`                                         |

---

## 3. **Terraform Implementation**

### 3.1 Key Considerations
- **Parameter Groups**: Ensure parameters like `slow_query_log` (MySQL) or `log_statement` (PostgreSQL) are enabled in the DB parameter group to generate logs.  
- **CloudWatch Exports**: Use `enabled_cloudwatch_logs_exports` to forward logs.  

### 3.2 RDS Cluster Example (Aurora MySQL)
```hcl
resource "aws_rds_cluster" "secure_cluster" {
  cluster_identifier           = "my-secure-cluster"
  engine                       = "aurora-mysql"
  engine_version               = "5.7.mysql_aurora.2.x"
  master_username              = var.db_username
  master_password              = var.db_password
  database_name                = "mydb"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  storage_encrypted            = true
  kms_key_id                   = var.kms_key_arn

  # Associate parameter group to enable logs at the DB level
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_pg.name
}

resource "aws_rds_cluster_parameter_group" "cluster_pg" {
  name        = "custom-aurora-mysql-pg"
  family      = "aurora-mysql5.7"
  description = "Enables slow query and general logs"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }
}
```

### 3.3 RDS DB Instance Example (PostgreSQL)
```hcl
resource "aws_db_instance" "postgres_db" {
  identifier         = "my-postgres-db"
  engine            = "postgres"
  engine_version    = "13.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 20
  parameter_group_name = aws_db_parameter_group.postgres_pg.name
  enabled_cloudwatch_logs_exports = ["postgresql"] # Exports PostgreSQL logs
}

resource "aws_db_parameter_group" "postgres_pg" {
  name   = "custom-postgres-pg"
  family = "postgres13"

  parameter {
    name  = "log_statement"
    value = "all"
  }
}
```

> **Note**: Log types vary by engine. Always configure both the parameter group (to generate logs) and CloudWatch exports.

---

## 4. **Manual Remediation Steps**

### 4.1 Identify Non-Compliant Resources  
**AWS CLI**:  
```bash
# Check instances with no logs enabled
aws rds describe-db-instances --query "DBInstances[?length(EnabledCloudwatchLogsExports) == \`0\`].DBInstanceIdentifier"

# Check clusters with no logs enabled
aws rds describe-db-clusters --query "DBClusters[?length(EnabledCloudwatchLogsExports) == \`0\`].DBClusterIdentifier"
```

### 4.2 Enable Logging via Console  
1. **RDS Dashboard** → Select DB Instance/Cluster → **Modify**.  
2. Under **Log exports**, select applicable logs (e.g., `error`, `slowquery`).  
3. **Apply Immediately** or defer to the next maintenance window (may require reboot).  

### 4.3 Update Parameter Groups (If Needed)  
- **MySQL/Aurora**: Set `slow_query_log = 1`, `general_log = 1`.  
- **PostgreSQL**: Set `log_statement = 'all'`, `log_destination = 'csvlog'`.  
- **Apply parameter group** and reboot if required.  

### 4.4 Coordinate Changes  
- Use **ServiceNow** for production changes requiring downtime.  
- Notify application owners of potential performance impact during reboots.  

---

## 5. **Required IAM Permissions**

Ensure the executing IAM role has:  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:ModifyDBInstance",
        "rds:ModifyDBCluster",
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters",
        "rds:ModifyDBParameterGroup",
        "cloudwatch:PutMetricData" // For log exports
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 6. **Enforcement & Detection**

- **Preventive**: Use Terraform modules with `enabled_cloudwatch_logs_exports` enforced.  
- **Detective**:  
  - **AWS Config Rule**: Deploy a custom rule to check `EnabledCloudwatchLogsExports`.  
  - **Orca/CBC**: Leverage existing alerts for non-compliant resources.  

---

## 7. **Verification**

1. **AWS CLI**:  
   ```bash
   # Check instance exports
   aws rds describe-db-instances --query "DBInstances[].[DBInstanceIdentifier,EnabledCloudwatchLogsExports]"

   # Check CloudWatch Log Groups (replace with your DB identifier)
   aws logs describe-log-groups --query "logGroups[?starts_with(logGroupName, '/aws/rds/instance/my-db')]"
   ```

2. **Performance Impact**: Monitor CPU/utilization after enabling logs (some engines log to disk before exporting).  

---

## 8. **Troubleshooting**

- **Logs Not Appearing?**  
  1. Verify the DB parameter group enables logging (e.g., `slow_query_log=1`).  
  2. Check IAM permissions for `cloudwatch:CreateLogStream` and `cloudwatch:PutLogEvents`.  
  3. Reboot the instance if changes require it.  

- **Cost Considerations**: Set CloudWatch Logs retention policies (e.g., 30 days) to avoid excessive costs.  

---

## 9. **References**

- [AWS RDS Log Export Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.html)  
- [Engine-Specific Log Types](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.html)  

---

**Improvements Summary**:  
1. Added engine-specific log type table.  
2. Clarified dependency on DB parameter groups in Terraform.  
3. Fixed AWS CLI queries to accurately detect non-compliant resources.  
4. Included IAM policy snippet and troubleshooting section.  
5. Added cost and performance considerations.  

Let me know if further refinements are needed!
