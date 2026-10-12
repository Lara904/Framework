# Architecture Context — SFS NG Landing Zone

The SFS-AWS NG Landing Zone architecture is structured around multiple AWS accounts within Stellantis's cloud environment.

## Account Structure
| Account | Role |
|---------|------|
| **Application Account** | Hosts VPC, subnets, ECS clusters, databases, S3 buckets, batch processing |
| **AWS LZB Log Account** | Centralized logging (S3, CloudWatch forwarding) + **AWS Shield Advanced** (per template) |
| **Shared Endpoint Account** | Transit Gateway, VPC endpoints (APIC, MTS2, SMTPS, LDAPS) |
| **Network Account** | Network Firewall, Transit Gateway |
| **Shared Kafka Account** | MSK (Managed Streaming for Kafka) |
| **Egress Account** | Palo Alto firewall for internet-bound traffic |
| **SFS AWS Shared Services** | Transfer Family (SFTP) |
| **AWS TEIC LZ / Endpoint Account** | APIC Private Link, MTS2 Private Link, SMTPS/LDAPS Private Link |
| **On-Premise Corporate Data Center** | Ping Federate, APIC Private (deprecated), MTS2, SMTP server, LDAP server, Secur-IT |

## Network Topology
- **Region**: eu-west-3 (Paris)
- **Availability Zones**: eu-west-3a, eu-west-3b, eu-west-3c
- **Connectivity**: Direct Connect to On-Premise, Transit Gateway for inter-account routing
- **Ingress**: GWLB inspection layer
- **Egress**: Via Transit Gateway -> Palo Alto (internet), or directly via VPC endpoints (corporate)

## VPC Subnet Layout (Application Account)
| Subnet Type | Purpose |
|-------------|---------|
| **Protected subnet** | ALB (public IP), Internet-facing load balancers |
| **Private subnet** | Application ECS Cluster, Batch ECS Cluster, ECS services |
| **Isolated subnet** | RDS Postgres/MySQL, databases |

## Template Component Inventory

When generating a diagram from the template, select components based on the application needs.

### Global Region Services

> **Important — this is a "Global" REGION, not a generic box**:
> - The Global services group represents the AWS **Global region** (edge/global services that are not bound to a specific region such as eu-west-3).
> - It MUST use the AWS region group style: `shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;dashed=1` with label `Global Region` (or `Global`). Never a generic `rounded=1` box.
> - It is a **child** of the Application Account group (its `parent` references the Application Account cell ID) but it is a **sibling** of the `Region eu-west-3 (Paris)` group — the Global region must NOT be nested inside the eu-west-3 region.
> - Services that belong here (global, region-agnostic): Route 53, CloudFront, WAF (the WebACL attached to CloudFront), and the ACM certificate used by CloudFront (issued in us-east-1 / global scope).
> - Regional services (ALB, regional WAF, regional ACM, ECS, S3, RDS, etc.) stay inside `Region eu-west-3 (Paris)`, NOT in the Global region.
> - **AWS Shield Advanced**: follow the template — it is placed **inside the AWS LZB Log Account** group, NOT in the Global Region. Do not relocate it based on your own reasoning; the template is the source of truth for placement.

- Route 53 (Public + Private)
- CloudFront
- WAF (attached to CloudFront)
- ACM (Certificate Manager — CloudFront cert, global scope)

> Note: AWS Shield Advanced is documented under the LZB Log Account (per template placement), not the Global Region.

### Application Account Services

The **Global Region** group (containing Route 53, CloudFront, WAF, ACM) must be placed **inside** the Application Account boundary — it is not a sibling but a child of the Application Account group. (AWS Shield Advanced belongs to the LZB Log Account per the template, not the Global Region.)

- **Compute**: ECS Cluster (Application + Batch), ECS Services, AWS Batch, Step Functions, Lambda (authorizer)
- **API**: AWS API Gateway (REST/Regional) with WAF
- **Networking**: VPC, ALB (public IP), ALB (no public IP), NLB (no public IP), VPC Link, Internet Gateway, VPC Egress peering
- **Storage**: S3 (Webapp static hosting, Access logs, App Inbox/Outbox)
- **Database**: RDS Postgres/MySQL, MongoDB Atlas (external)
- **Security**: Secret Manager, KMS, ACM, WAF (regional), Inspector, ECR
- **Observability**: CloudWatch
- **Integration**: EventBridge (schedules/events)
- **File Handling Pattern**: S3 Inbox (decrypted) + S3 Outbox -> Transfer Family (SFTP)

### Shared Services
- Transfer Family (SFTP endpoint for file exchange with MTS2)

### Connectivity to On-Premise
- APIC Private (deprecated) -> Service Provider
- Ping Federate (OIDC authentication)
- MTS2 (file transfer, PGP encrypted)
- Secur-IT (file transfer without PGP, via MTS2)
- SMTP server
- LDAP server
