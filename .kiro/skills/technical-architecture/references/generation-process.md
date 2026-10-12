# Diagram Generation Process

When asked to generate or modify an architecture diagram, follow these steps.

## Step 0 — Generation Strategy

> **CRITICAL**: There are TWO valid generation strategies. Choose based on context.

### Strategy A — Template Subtraction (PREFERRED for complex multi-pattern apps)
- Copy the full template file (`assets/templates/SFS-AWS_NG-Architecture_design_template.v0.3.drawio`) to the output location
- Remove ONLY the cells that are explicitly unnecessary (identify by `value=` attribute)
- Remove associated edges (cells with `edge="1"` referencing removed cell IDs)
- **Use when**: The application uses 2+ patterns, or the user explicitly asks for the "full LZ view"
- **Limitation**: This approach requires careful edge cleanup; always validate no orphaned edges remain

### Strategy B — Pattern Assembly (PREFERRED for single-pattern apps)
- Build the diagram from scratch using ONLY the components needed
- Include ALL Landing Zone integration points that the selected services connect to
- **Use when**: The application uses a single pattern (e.g., only static hosting)
- **Advantage**: Clean, focused, no orphaned references

### Landing Zone Integration Points (both strategies)
For each AWS service used, include its Landing Zone dependencies:

| Service Used | Must Also Include |
|-------------|-------------------|
| **CloudFront** | -> LZB Log Account (S3 logging bucket), WAF, Shield Advanced, Route 53, ACM |
| **WAF** | -> LZB Log Account (WAF logging) |
| **Route 53** | -> LZB Log Account (Route 53 logging) |
| **ALB** | -> LZB Log Account (ALB access logs), WAF (regional) |
| **S3** (any bucket) | -> KMS (encryption), CloudWatch (metrics) |
| **ECS** | -> ECR, Inspector, CloudWatch (container logs), Secret Manager |
| **Any compute** | -> VPC (with subnets), Internet Gateway, Network Firewall (ingress), Egress Account (outbound) |
| **Any on-premise call** | -> Transit Gateway, Direct Connect, On-Premise Data Center boundary |

For Pattern 3 (Static Web Hosting) with **no backend**, the complete LZ diagram includes:
- AWS Cloud boundary, Application Account boundary, Region eu-west-3
- Global Region: Route 53, CloudFront, WAF, ACM
- S3 bucket (widget), S3 bucket (access logs)
- CloudWatch (monitoring)
- KMS (S3 encryption)
- **LZB Log Account** with S3 logging bucket + **AWS Shield Advanced** + log flow edges from: CloudFront, WAF, Route 53
- CI/CD Pipeline (external Stellantis stack): **GitHub -> TeamCity -> Artifactory -> S3 deploy** (NOT AWS CodePipeline/CodeBuild)
- External: End User, Host Application (embedding the widget)
- **No VPC, no subnets, no Transit Gateway, no Egress Account, no On-Premise** (since there is no compute/backend tier)

## Step 1 — Requirements Gathering
Ask the user:
- What does the application do? (API, frontend, batch, file exchange?)
- What external systems does it integrate with? (APIC, MTS2, LDAP, Kafka?)
- What databases are needed? (RDS, MongoDB Atlas?)
- Does it need authentication? (OIDC via Ping Federate, mTLS?)
- Is there a frontend? (Static web hosting via CloudFront+S3?)

## Step 2 — Pattern Selection
- REST API consumers -> Pattern 1 (REST API Exposition)
- Containerized backend -> Pattern 2 (ECS Fargate)
- Static frontend -> Pattern 3 (Static Web Hosting)
- File exchange -> File Handling Pattern
- Multiple patterns can coexist in one diagram

See `patterns.md` for each pattern's required components.

## Step 3 — Component Selection
From the template inventory (`architecture-context.md`):
- **ALWAYS KEEP** mandatory Landing Zone infrastructure (see "Mandatory Components" below)
- **KEEP** all components required by selected patterns
- **KEEP** mandatory security services (WAF, KMS, ACM, Secret Manager, CloudWatch, Inspector)
- **REMOVE** only components explicitly not needed from optional patterns (e.g., remove Batch/Step Functions if no file processing)
- **REMOVE** unused optional connectivity (e.g., remove LDAPS endpoint if no LDAP integration)
- Mark optional items with "C?" (convention from template = "Confirm if needed")

> **CRITICAL RULE**:
> - **Strategy A** (multi-pattern): Copy the template and subtract. The template represents the validated Landing Zone architecture.
> - **Strategy B** (single-pattern): Build from scratch but include ALL Landing Zone integration points per the table above. The result must show LZ-level flows (logging, encryption, monitoring) — not just the application components.

### Mandatory Components — Conditional Rules
> "Mandatory" does not mean "always present in every diagram". It means "must be present IF the application uses a service that depends on it". Apply the Landing Zone Integration Points table above.

**Always present** (regardless of patterns):
- AWS Cloud boundary
- Application Account boundary
- Region eu-west-3 boundary
- CloudWatch (observability)
- KMS (encryption)
- LZB Log Account (with S3 logging bucket receiving logs from services in use)

**Present only if the application has compute/backend tier** (ECS, Lambda, Batch):
- VPC (with Protected, Private, Isolated subnets)
- Internet Gateway
- Ingress inspection (GWLB)
- Network Firewall
- Transit Gateway (in Network Account)
- Shared Endpoint Account
- VPC Egress peering
- Egress Account (Palo Alto)
- ECR, Inspector
- Secret Manager

**Present only if the application connects to on-premise systems**:
- On-Premise Corporate Data Center boundary
- Direct Connect
- Transit Gateway

**Present only if the application has a frontend/CDN**:
- Global Region (Route 53, CloudFront, WAF, ACM)
- AWS Shield Advanced (placed in the LZB Log Account per template, not the Global Region)

## Step 4 — Diagram Generation

### If using Strategy A (Template Subtraction):
1. **Copy the template file** to the output location
2. Identify cells to remove by their `value=` attribute (service name/label)
3. Remove only `<mxCell>` elements for services explicitly marked as unnecessary in Step 3
4. Remove associated edges (`<mxCell>` with `edge="1"` referencing removed cells via `source=` / `target=`)
5. Remove edge labels (cells with `style="edgeLabel..."` whose `parent=` references a removed edge)
6. Add new services using the same style conventions below
7. Update the Versions page by appending a new table row (see `output-format.md`) with an incremented version number and change description
8. Preserve the overall layout structure (accounts, subnets, regions, Log Account)

### If using Strategy B (Pattern Assembly):
1. **Build a new diagram from scratch** with a single page
2. Place ALL components from the selected pattern's requirements
3. Add ALL Landing Zone integration points per the table in Step 0
4. Include proper account/region boundaries for all accounts shown
5. Add edges showing data flows, log flows (dashed), and security associations
6. Follow the style conventions below for all cells
7. Include a notes box describing the application

> **WARNING (both strategies)**: If in doubt about whether to keep or remove a component, KEEP IT.

## Draw.io XML Style Conventions
- **Use the latest AWS icon set (2024/2025/2026)**: prefer `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.<service>` (AWS Architecture Icons 2024+). Do NOT use deprecated `mxgraph.aws3.*` shapes.
- **strokeColor must always be `#ffffff`** for AWS service icons. Never use `strokeColor=none`. Example: `strokeColor=#ffffff;dashed=0;`
- When a newer icon variant exists (e.g., `mxgraph.aws4.cloudwatch_2` instead of `mxgraph.aws4.cloudwatch`), always use the latest variant.
- Account boundaries: `shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_aws_cloud`
- Subnet groups: `shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_security_group`
- VPC group: `shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc2` (use `group_vpc2` not `group_vpc`)
- Connections: `edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1`
- Encrypted links labeled: "PGP Encrypted", "HTTPS", "mTLS", "SFTP"
- TLS indicators: lock icon (`shape=mxgraph.mscae.enterprise.lock`)
- "C?" circles indicate components to confirm with the project team
- **Human actors (End User, Developer, etc.)**: use the plain shape `shape=mxgraph.aws4.user;` (NOT `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.user;`). The `resourceIcon` form draws a dark filled tile behind the silhouette, which is wrong for a human actor. Use `sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3E;strokeColor=none;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;shape=mxgraph.aws4.user;`.

### File Encoding (avoid mojibake)
- Always write the `.drawio` file as **UTF-8 without BOM**.
- **Avoid non-ASCII characters** in cell `value` text (em dash, bullets, curly quotes). They frequently get double-encoded and render as garbage.
- Use ASCII equivalents instead: `-` (hyphen) instead of em dash/bullet, straight quotes `'` `"` instead of curly ones.
- If a bullet list is needed inside a text cell, use `- ` at the start of each line (with `&#10;` as the newline separator).
- After generating, verify no mojibake: search the file for the byte sequence formed by `\u00E2\u20AC` — there should be zero matches.

### AWS Icon Reference (latest shapes to use)
| Service | Shape |
|---------|-------|
| ECS | `mxgraph.aws4.ecs` |
| ECS Service | `mxgraph.aws4.ecs_service` |
| ECS Task | `mxgraph.aws4.ecs_task` |
| ECR | `mxgraph.aws4.ecr` |
| Lambda | `mxgraph.aws4.lambda` |
| API Gateway | `mxgraph.aws4.api_gateway` |
| S3 | `mxgraph.aws4.s3` |
| RDS | `mxgraph.aws4.rds` |
| CloudFront | `mxgraph.aws4.cloudfront` |
| Route 53 | `mxgraph.aws4.route_53` |
| CloudWatch | `mxgraph.aws4.cloudwatch_2` |
| WAF | `mxgraph.aws4.waf` |
| Shield | `mxgraph.aws4.shield_shield_advanced` |
| ACM | `mxgraph.aws4.certificate_manager_3` |
| KMS | `mxgraph.aws4.key_management_service` |
| Secrets Manager | `mxgraph.aws4.secrets_manager` |
| Inspector | `mxgraph.aws4.inspector` |
| EventBridge | `mxgraph.aws4.eventbridge` |
| Step Functions | `mxgraph.aws4.step_functions` |
| Batch | `mxgraph.aws4.batch` |
| Transfer Family | `mxgraph.aws4.transfer_family` |
| MSK (Kafka) | `mxgraph.aws4.managed_streaming_for_kafka` |
| Transit Gateway | `mxgraph.aws4.transit_gateway` |
| VPC PrivateLink | `mxgraph.aws4.vpc_privatelink` |
| Network Firewall | `mxgraph.aws4.network_firewall` |
| Internet Gateway | `mxgraph.aws4.internet_gateway` (with `pointerEvents=1`) |
| ALB | `mxgraph.aws4.elastic_load_balancing` (with `resIcon`) |
| NLB | `mxgraph.aws4.network_load_balancer` |
| VPC Endpoint | `mxgraph.aws4.endpoint` or `mxgraph.aws4.endpoints` |

## Step 5 — Validation Checklist
- [ ] All selected patterns have their required components present
- [ ] No orphaned edges (connections to removed components)
- [ ] Security services present: WAF, KMS, ACM, Secret Manager, CloudWatch
- [ ] Logging configured: S3 logging bucket in Log Account, CloudWatch
- [ ] Network path complete: Ingress -> through subnets -> service -> database
- [ ] Egress path complete: Service -> Transit Gateway -> appropriate destination
- [ ] VPC endpoints present for all inter-account communication
- [ ] Encryption noted on all external connections
- [ ] "C?" markers on optional/TBD components
- [ ] Versions page updated
- [ ] Geometry validated (see `layout-validation.md`)

## Common Modifications

### Adding a new ECS service
1. Add `mxCell` with `shape=mxgraph.aws4.ecs_service` in the Application ECS Cluster group
2. Add edge from ALB to the new service
3. Add edge from service to database (if applicable)

### Removing file handling
1. Remove S3 Inbox/Outbox cells
2. Remove Batch ECS Cluster and its jobs
3. Remove Step Functions / EventBridge (if only used for file processing)
4. Remove Transfer Family from Shared Services
5. Remove MTS2 connections and related edges
6. Remove File Handling Pattern boundary box

### Adding Kafka integration
1. Keep MSK in Shared Kafka Account
2. Add VPC endpoint for MSK in Application Account
3. Add edge from ECS service to MSK endpoint

### Removing MongoDB Atlas
1. Remove the MongoDB Atlas cluster boundary and contained DB icons
2. Remove edges from ECS services to MongoDB
