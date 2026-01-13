# 🏗️ Network Architecture & Security

## Overview

This document describes the enterprise-grade network infrastructure provisioning for multi-cloud GPU deployments across AWS, Azure, and GCP. The architecture emphasizes security, scalability, and compliance through network segmentation, comprehensive monitoring, and defense-in-depth principles.

## Table of Contents

- [Network Architecture](#network-architecture)
- [Security Model](#security-model)
- [Network Components](#network-components)
- [VPC Configuration](#vpc-configuration)
- [Subnet Design](#subnet-design)
- [Routing Strategy](#routing-strategy)
- [Security Groups & NACLs](#security-groups--nacls)
- [Network Flow Logs](#network-flow-logs)
- [DNS Configuration](#dns-configuration)
- [Remote State Management](#remote-state-management)
- [Multi-Region Networking](#multi-region-networking)
- [Compliance & Monitoring](#compliance--monitoring)

## Network Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Internet                                        │
│                          (0.0.0.0/0)                                     │
└────────────┬────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS Internet Gateway                                  │
│                    (Regional entry point)                               │
└────────────┬────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                               │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                   PUBLIC TIER (10.0.1.0-2.0/24)                  │  │
│  │  ┌─────────────┐                       ┌─────────────┐          │  │
│  │  │ Subnet A    │   Application LB      │ Subnet B    │          │  │
│  │  │ 10.0.1.0/24 │   (Health Checks)     │ 10.0.2.0/24 │          │  │
│  │  │ AZ-a        │   (Port 80, 443)      │ AZ-b        │          │  │
│  │  └──────┬──────┘                       └──────┬──────┘          │  │
│  │         │                                     │                 │  │
│  │         └─────────┬───────────────────────────┘                 │  │
│  │                   │                                             │  │
│  │              Route Table: Public RT                             │  │
│  │              Destination: 0.0.0.0/0 → IGW                      │  │
│  │              Destination: 10.0.0.0/16 → Local                  │  │
│  │                                                                 │  │
│  │         ┌─────────────────────────────────────┐                │  │
│  │         │  NACL: Public Tier                  │                │  │
│  │         │  - Allow HTTP (80), HTTPS (443)     │                │  │
│  │         │  - Allow SSH (22) restricted        │                │  │
│  │         │  - Allow ephemeral (1024-65535)     │                │  │
│  │         └─────────────────────────────────────┘                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │            PRIVATE TIER (10.0.10.0-11.0/24)                      │  │
│  │  ┌─────────────┐                       ┌─────────────┐          │  │
│  │  │ Subnet A    │     GPU Compute       │ Subnet B    │          │  │
│  │  │ 10.0.10.0/24│   (Instance)          │ 10.0.11.0/24│          │  │
│  │  │ AZ-a        │   (Workloads)         │ AZ-b        │          │  │
│  │  └──────┬──────┘                       └──────┬──────┘          │  │
│  │         │                                     │                 │  │
│  │         └─────────┬───────────────────────────┘                 │  │
│  │                   │                                             │  │
│  │     ┌─────────────▼──────────────┬──────────────┐              │  │
│  │     │    NAT Gateway AZ-a        │  NAT Gateway │              │  │
│  │     │    (Elastic IP)            │  AZ-b        │              │  │
│  │     └─────────────┬──────────────┴──────────────┘              │  │
│  │                   │                                             │  │
│  │         Route Table: Private RT-AZ-a                            │  │
│  │         Destination: 0.0.0.0/0 → NAT-GW-a                      │  │
│  │         Destination: 10.0.0.0/16 → Local                       │  │
│  │                                                                 │  │
│  │         ┌─────────────────────────────────────┐                │  │
│  │         │  NACL: Private Tier                 │                │  │
│  │         │  - Allow VPC CIDR (10.0.0.0/16)     │                │  │
│  │         │  - Allow ephemeral (1024-65535)     │                │  │
│  │         │  - Restrict external access         │                │  │
│  │         └─────────────────────────────────────┘                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │          DATABASE TIER (10.0.20.0-21.0/24)                       │  │
│  │  ┌─────────────┐                       ┌─────────────┐          │  │
│  │  │ Subnet A    │     PostgreSQL        │ Subnet B    │          │  │
│  │  │ 10.0.20.0/24│     Redis             │ 10.0.21.0/24│          │  │
│  │  │ AZ-a        │     Qdrant            │ AZ-b        │          │  │
│  │  └──────┬──────┘                       └──────┬──────┘          │  │
│  │         │                                     │                 │  │
│  │         └─────────────┬───────────────────────┘                 │  │
│  │                       │                                         │  │
│  │        Route Table: Database RT                                 │  │
│  │        Destination: 10.0.0.0/16 → Local (no internet)          │  │
│  │                                                                 │  │
│  │         ┌─────────────────────────────────────┐                │  │
│  │         │  NACL: Database Tier                │                │  │
│  │         │  - Allow MySQL (3306) from VPC      │                │  │
│  │         │  - Allow PostgreSQL (5432) from VPC │                │  │
│  │         │  - No inbound from internet         │                │  │
│  │         └─────────────────────────────────────┘                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │               VPC ENDPOINTS (Optional)                           │  │
│  │  ┌──────────────────┐  ┌──────────────────┐                   │  │
│  │  │ S3 Gateway       │  │ DynamoDB Gateway │                   │  │
│  │  │ Endpoint         │  │ Endpoint         │                   │  │
│  │  │ (Private access  │  │ (Private access  │                   │  │
│  │  │  to AWS services)│  │  to AWS services)│                   │  │
│  │  └──────────────────┘  └──────────────────┘                   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │           VPC FLOW LOGS (CloudWatch Logs)                        │  │
│  │  - Monitor network traffic (ACCEPT, REJECT, ALL)                 │  │
│  │  - 7-day retention for analysis                                  │  │
│  │  - Compliance and security audit trail                          │  │
│  │  - Metrics dashboard for real-time visibility                   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │        ROUTE 53 PRIVATE HOSTED ZONE (internal.local)             │  │
│  │  - Private DNS resolution within VPC                             │  │
│  │  - Records: db.internal.local → Database subnet IP              │  │
│  │  - Records: cache.internal.local → Redis subnet IP              │  │
│  │  - Records: api.internal.local → Application subnet IP          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Security Model

### Defense-in-Depth Strategy

The network implements multiple layers of security:

```
Layer 1: Internet Gateway (Regional boundary)
  ↓
Layer 2: Network ACLs (Subnet-level, stateless)
  ↓
Layer 3: Security Groups (Instance-level, stateful)
  ↓
Layer 4: Application firewall (WAF on ALB)
  ↓
Layer 5: Host-based firewalls (iptables/firewalld)
  ↓
Layer 6: Application-level access controls
```

### Principle of Least Privilege

- **Public Tier**: Only HTTP (80), HTTPS (443), SSH (22) from restricted sources
- **Private Tier**: Only traffic from VPC CIDR, ephemeral ports for outbound
- **Database Tier**: Only database ports (3306, 5432) from application tier
- **No traffic crossing tier boundaries** unless explicitly required

## Network Components

### 1. Virtual Private Cloud (VPC)

| Attribute | Value | Purpose |
|-----------|-------|---------|
| **CIDR Block** | `10.0.0.0/16` | Entire network address space (65,536 IPs) |
| **DNS Hostnames** | Enabled | Support for DNS names within VPC |
| **DNS Resolution** | Enabled | Route 53 private hosted zone support |
| **Flow Logs** | Enabled | Compliance and security monitoring |
| **Tenancy** | Default | Shared hardware (cost-effective) |

### 2. Internet Gateway (IGW)

- **Purpose**: Gateway between VPC and internet
- **Attachment**: Attached to main VPC
- **Stateless**: Does not maintain state
- **Scaling**: Automatically scales to handle traffic
- **High Availability**: Redundant in AWS infrastructure

### 3. NAT Gateway

- **Purpose**: Enable private instances to initiate outbound connections
- **Placement**: In public subnets (requires internet connectivity)
- **One per AZ**: Separate NAT-GW for each availability zone
- **Elastic IP**: Dedicated public IP address
- **Bandwidth**: Up to 100 Gbps
- **Data Processing**: ~$0.045 per GB (regional pricing)

## Subnet Design

### Subnet Allocation Strategy

```
VPC CIDR: 10.0.0.0/16 (256 subnets of /24 available)

Public Tier (Tier 1):
├── Public-A (AZ-a): 10.0.1.0/24   (252 usable IPs)
├── Public-B (AZ-b): 10.0.2.0/24   (252 usable IPs)
└── Public-C (AZ-c): 10.0.3.0/24   (252 usable IPs) [optional]

Private Tier (Tier 2):
├── Private-A (AZ-a): 10.0.10.0/24 (252 usable IPs)
├── Private-B (AZ-b): 10.0.11.0/24 (252 usable IPs)
└── Private-C (AZ-c): 10.0.12.0/24 (252 usable IPs) [optional]

Database Tier (Tier 3):
├── Database-A (AZ-a): 10.0.20.0/24 (252 usable IPs)
├── Database-B (AZ-b): 10.0.21.0/24 (252 usable IPs)
└── Database-C (AZ-c): 10.0.22.0/24 (252 usable IPs) [optional]

Reserved:
├── 10.0.100.0/24 - 10.0.199.0/24: Future expansion
└── 10.0.200.0/24 - 10.0.255.0/24: VPN/Transit Gateway
```

### Multi-Availability Zone Design

Each tier is distributed across **minimum 2 AZs** for:

- **High Availability**: If one AZ fails, services continue in other AZ
- **Load Balancing**: Distribute traffic across AZs
- **Compliance**: Some regulations require multi-AZ deployment
- **Cost**: NAT Gateway per AZ ensures optimal data transfer costs

**Availability Zone Selection:**
```bash
AWS Region: ap-south-1 (Mumbai)
├── AZ-a: ap-south-1a
├── AZ-b: ap-south-1b
└── AZ-c: ap-south-1c (optional)
```

## Routing Strategy

### Public Route Table (Tier 1)

```
Destination        Gateway/Target      Use Case
──────────────────────────────────────────────────
10.0.0.0/16        Local              VPC-internal traffic
0.0.0.0/0          Internet Gateway   Internet-bound traffic
```

**Traffic Flow:**
```
Instance in Public Subnet
  ↓
Local traffic to VPC? → Use Local gateway
  ↓
Internet traffic? → Use IGW
  ↓
Public IP → Internet
```

### Private Route Table (Tier 2)

```
Destination        Gateway/Target      Use Case
──────────────────────────────────────────────────
10.0.0.0/16        Local              VPC-internal traffic
0.0.0.0/0          NAT Gateway        Internet-bound traffic
```

**Traffic Flow:**
```
Private Instance
  ↓
Initiate outbound connection to internet
  ↓
Route to NAT Gateway in same AZ
  ↓
NAT Gateway translates private IP → Elastic IP
  ↓
Returns response via NAT Gateway
  ↓
Private instance receives response
```

**Key Insight**: Private instances can **initiate** outbound connections but **cannot receive** inbound connections from internet.

### Database Route Table (Tier 3)

```
Destination        Gateway/Target      Use Case
──────────────────────────────────────────────────
10.0.0.0/16        Local              VPC-internal traffic
```

**Traffic Flow:**
```
Database Instance
  ↓
Only local VPC traffic allowed
  ↓
No internet connectivity
  ↓
No outbound NAT Gateway
```

**Benefit**: Database tier is completely isolated from internet, reducing attack surface.

## Security Groups & NACLs

### Security Groups (Stateful)

Security Groups act as **stateful firewalls** at the instance level.

#### 1. Application Load Balancer Security Group

```
Direction    Protocol    Port Range    Source          Purpose
─────────────────────────────────────────────────────────────────
INBOUND
HTTP         TCP         80            0.0.0.0/0       HTTP traffic
HTTPS        TCP         443           0.0.0.0/0       Encrypted traffic
SSH          TCP         22            203.0.113.0/24  Admin access

OUTBOUND
All          All         All           0.0.0.0/0       All traffic allowed
```

#### 2. GPU Instance Security Group

```
Direction    Protocol    Port Range    Source          Purpose
──────────────────────────────────────────────────────────────────
INBOUND
SSH          TCP         22            ALB SG          SSH from load balancer
HTTP         TCP         5000          ALB SG          App from load balancer
HTTPS        TCP         443           ALB SG          Secure app traffic
JDBC         TCP         3306          Private SG      DB queries
PostgreSQL   TCP         5432          Private SG      DB queries

OUTBOUND
All          All         All           0.0.0.0/0       All traffic allowed
```

#### 3. Private Instance Security Group

```
Direction    Protocol    Port Range    Source          Purpose
──────────────────────────────────────────────────────────────────
INBOUND
SSH          TCP         22            Public SG       SSH from bastion
Custom       TCP         Various       VPC CIDR        Inter-service communication

OUTBOUND
All          All         All           0.0.0.0/0       All traffic allowed
```

#### 4. Database Security Group

```
Direction    Protocol    Port Range    Source          Purpose
──────────────────────────────────────────────────────────────────
INBOUND
MySQL        TCP         3306          App SG          From application tier
PostgreSQL   TCP         5432          App SG          From application tier
Redis        TCP         6379          App SG          Cache queries

OUTBOUND
All          All         All           0.0.0.0/0       All traffic allowed
```

### Network ACLs (Stateless)

Network ACLs provide an additional layer of subnet-level security.

#### 1. Public Subnet NACL

```
Rule #    Type          Protocol    Port Range    Source          Action
────────────────────────────────────────────────────────────────────────
INBOUND
100       HTTP          TCP         80            0.0.0.0/0       ALLOW
110       HTTPS         TCP         443           0.0.0.0/0       ALLOW
120       SSH           TCP         22            203.0.113.0/24  ALLOW
130       Ephemeral     TCP         1024-65535    0.0.0.0/0       ALLOW
*         All           All         All           All             DENY

OUTBOUND
100       All Traffic   All         All           0.0.0.0/0       ALLOW
```

#### 2. Private Subnet NACL

```
Rule #    Type          Protocol    Port Range    Source          Action
────────────────────────────────────────────────────────────────────────
INBOUND
100       VPC CIDR      TCP         All           10.0.0.0/16     ALLOW
110       Ephemeral     TCP         1024-65535    0.0.0.0/0       ALLOW
*         All           All         All           All             DENY

OUTBOUND
100       All Traffic   All         All           0.0.0.0/0       ALLOW
```

#### 3. Database Subnet NACL

```
Rule #    Type          Protocol    Port Range    Source          Action
────────────────────────────────────────────────────────────────────────
INBOUND
100       MySQL         TCP         3306          10.0.0.0/16     ALLOW
110       PostgreSQL    TCP         5432          10.0.0.0/16     ALLOW
120       Redis         TCP         6379          10.0.0.0/16     ALLOW
*         All           All         All           All             DENY

OUTBOUND
100       All Traffic   All         All           0.0.0.0/0       ALLOW
```

### Security Group vs NACL Comparison

| Feature | Security Group | NACL |
|---------|---|---|
| **Level** | Instance | Subnet |
| **State** | Stateful | Stateless |
| **Default** | Deny all inbound | Allow all inbound/outbound |
| **Rule Evaluation** | All rules evaluated | First matching rule wins |
| **Performance** | Higher (instance-level) | Lower (subnet-level) |
| **Use Case** | Primary defense | Backup/compliance |

## Network Flow Logs

### Overview

VPC Flow Logs capture metadata about network traffic for:
- **Security Analysis**: Detect unusual traffic patterns
- **Compliance**: Audit trail for regulatory requirements
- **Troubleshooting**: Debug network connectivity issues
- **Performance**: Identify bandwidth bottlenecks

### Configuration

```hcl
variable "enable_flow_logs" {
  default = true
  description = "Enable VPC Flow Logs"
}

variable "flow_logs_traffic_type" {
  default = "ALL"
  description = "Traffic to log: ACCEPT, REJECT, or ALL"
  # Options: ACCEPT (successful), REJECT (failed), ALL (both)
}

variable "flow_logs_retention_days" {
  default = 7
  description = "CloudWatch Logs retention (days)"
  # Options: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
}
```

### Flow Log Format

```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes 
start end action tcp-flags type pkt-srcaddr pkt-dstaddr region vpc-id flow-logs-id 
traffic-type subnet-id instance-id interface-type arn http-request http-response http-code
```

### Example Log Entry

```
2 123456789012 eni-1234abcd 10.0.1.10 10.0.20.10 35678 5432 6 14 2030 
1556423631 1556423650 ACCEPT 18 IPv4 10.0.1.10 10.0.20.10 
ap-south-1 vpc-12345678 eni-12345678-flows INTRA-VPC subnet-1234567 
i-1234567890abcdef network-interface arn:aws:ec2:ap-south-1:123456789012:network-interface/eni-1234abcd
- - -
```

**Interpretation:**
```
- Source IP: 10.0.1.10 (private instance in AZ-a)
- Destination IP: 10.0.20.10 (database in database tier)
- Source Port: 35678 (ephemeral client port)
- Destination Port: 5432 (PostgreSQL)
- Protocol: 6 (TCP)
- Packets: 14 (data transfer)
- Bytes: 2030 (2 KB transferred)
- Status: ACCEPT (connection allowed)
- Type: IPv4 (IPv4 traffic)
```

### CloudWatch Analysis

**Query to find rejected connections:**
```sql
fields @timestamp, srcaddr, dstaddr, dstport, action
| filter action = "REJECT"
| stats count() as rejected_connections by dstport
```

**Query to identify top traffic sources:**
```sql
fields srcaddr, bytes
| filter action = "ACCEPT"
| stats sum(bytes) as total_bytes by srcaddr
| sort total_bytes desc
| limit 10
```

## DNS Configuration

### Route 53 Private Hosted Zone

Private hosted zones enable DNS resolution within VPC without exposing records to internet.

**Benefits:**
- Service discovery (internal.example.com)
- Load balancer DNS names
- Database connection strings
- VPC-internal service communication

**Example Records:**

```
Record Name            Type    Value               Purpose
──────────────────────────────────────────────────────────────────
db.internal.local      A       10.0.20.10          Database endpoint
cache.internal.local   A       10.0.20.11          Redis/cache endpoint
api.internal.local     A       10.0.10.5           API endpoint
app.internal.local     CNAME   api.internal.local  Application alias
```

**Configuration in Terraform:**

```hcl
variable "enable_private_hosted_zone" {
  default = true
}

variable "private_hosted_zone_name" {
  default = "internal.local"
  description = "Domain name for private zone"
}
```

### DNS Query Flow

```
Application in private subnet
  ↓
Query: db.internal.local
  ↓
Route 53 (Private Hosted Zone)
  ↓
Returns: 10.0.20.10
  ↓
Connection established to database
```

## Remote State Management

### Why Remote State?

Local `terraform.tfstate` files pose security risks:
- Sensitive data (passwords, keys) stored in plain text
- No version history or rollback capability
- Not suitable for team collaboration
- No automatic locking (concurrent modifications)

### AWS S3 + DynamoDB Backend

**Architecture:**
```
Developer Machine
  ↓
terraform apply/destroy
  ↓
AWS Credentials
  ↓
S3 Bucket: terraform-state
  ├── Object: multi-cloud-gpu/terraform.tfstate
  ├── Versioning: Enabled (state history)
  ├── Encryption: AES-256
  ├── Public Access: Blocked
  └── Lifecycle: Archive old versions
  ↓
DynamoDB Table: terraform-state-lock
  ├── Key: LockID
  ├── Purpose: State locking during apply
  └── Prevents concurrent modifications
```

**Setup Instructions:**

See [backends/aws-backend.tf](../backends/aws-backend.tf) for complete setup.

**Key Features:**
- **Encryption**: AES-256 at rest
- **Versioning**: Automatic state history
- **Locking**: DynamoDB prevents concurrent modifications
- **Backup**: Point-in-time recovery
- **Access Control**: IAM policies restrict access

## Multi-Region Networking

### Cross-Region Connectivity

For multi-region deployments:

#### Option 1: AWS Transit Gateway

```
Region 1 (ap-south-1)                Region 2 (us-east-1)
     │                                     │
     VPC                                  VPC
    10.0.0.0/16                        10.1.0.0/16
     │                                     │
     └─── Transit Gateway ───────────────┘
          (Central hub)
          Route traffic between regions
          High availability
          Easy to scale
```

#### Option 2: VPC Peering

Direct connection between two VPCs (single region or cross-region):

```
VPC A (10.0.0.0/16) ←→ Peering Connection ←→ VPC B (10.1.0.0/16)
```

**Limitations:**
- Maximum 125 peering connections per VPC
- Cannot create transitive connections
- Better for 1-to-1 connections

#### Option 3: AWS VPN

For hybrid connectivity (on-premises to AWS):

```
On-Premises Network        Customer Gateway
      │                           │
      └─── VPN Connection ────────┘
                  ↓
           Virtual Private Gateway
                  ↓
              AWS VPC
```

## Compliance & Monitoring

### Compliance Requirements

The network architecture satisfies:

| Requirement | Implementation | Component |
|---|---|---|
| **PCI DSS** | Encrypted VPC, NSGs, Flow Logs | NACL, Security Groups |
| **HIPAA** | Private subnets, Encryption, Audit logs | Database tier, Flow Logs |
| **SOC 2** | Network monitoring, Access logs, Encryption | Flow Logs, CloudWatch |
| **GDPR** | Data residency, Audit trails | VPC region, Flow Logs |
| **ISO 27001** | Access control, Monitoring | Security Groups, NACLs |

### Monitoring & Alerting

**CloudWatch Metrics:**
```bash
# Monitor rejected connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/VPC \
  --metric-name NetworkPacketsRejected \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Sum
```

**CloudWatch Alarms:**
```hcl
resource "aws_cloudwatch_metric_alarm" "high_rejected_packets" {
  alarm_name          = "vpc-high-rejected-packets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkPacketsRejected"
  namespace           = "AWS/VPC"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### Security Scanning

**Using AWS Security Hub:**
```bash
# Enable Security Hub
aws securityhub batch-enable-standards \
  --standards-subscription-requests StandardsSubscriptionRequest={StandardsArn=arn:aws:securityhub:region:account:standards/aws-foundational-security-best-practices/v/1.0.0}

# Find network misconfigurations
aws securityhub get-findings \
  --filters '{"Type":[{"Value":"TTPs/Defense Evasion/NetworkReconnaissance","Comparison":"EQUALS"}]}'
```

## Best Practices

### ✅ Do's

1. ✅ **Use NAT Gateways** for private instances needing internet access
2. ✅ **Enable VPC Flow Logs** for security monitoring and compliance
3. ✅ **Implement Network ACLs** as additional security layer
4. ✅ **Use Security Groups** with least privilege rules
5. ✅ **Segment by tier** (public/private/database)
6. ✅ **Multi-AZ deployment** for high availability
7. ✅ **Remote state storage** for team collaboration
8. ✅ **Enable VPC Endpoints** to avoid internet routing
9. ✅ **Use Route 53 private zones** for service discovery
10. ✅ **Monitor with CloudWatch** and set up alarms

### ❌ Don'ts

1. ❌ **Don't store state locally** for production
2. ❌ **Don't ignore NACLs** - they catch mistakes
3. ❌ **Don't use /16 CIDR** if planning multi-region
4. ❌ **Don't allow all inbound** in security groups (0.0.0.0/0)
5. ❌ **Don't skip encryption** for state files
6. ❌ **Don't disable Flow Logs** in production
7. ❌ **Don't route database traffic via internet** gateway
8. ❌ **Don't forget to tag resources** for cost allocation
9. ❌ **Don't use single AZ** for production workloads
10. ❌ **Don't hardcode CIDR blocks** - use variables

## Troubleshooting

### Connectivity Issues

**Problem:** Instance in private subnet cannot reach internet
```bash
# Check:
1. Is NAT Gateway in running state?
   aws ec2 describe-nat-gateways

2. Does private route table have 0.0.0.0/0 → NAT-GW route?
   aws ec2 describe-route-tables

3. Is security group allowing outbound traffic?
   aws ec2 describe-security-groups

4. Are NACLs allowing ephemeral ports (1024-65535)?
   aws ec2 describe-network-acls
```

**Problem:** Cannot SSH to instance in public subnet
```bash
# Check:
1. Is instance in public subnet?
2. Does route table have IGW route?
3. Does Security Group allow port 22?
4. Is NACL allowing SSH (port 22)?
5. Is Security Group source restricted properly?
```

## References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)
- [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [Terraform AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/)

---

**Last Updated:** January 2026  
**Version:** 2.0  
**Status:** Production Ready
