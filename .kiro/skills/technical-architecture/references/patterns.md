# SIBS M2C Patterns

Each pattern below maps to a source diagram in `assets/templates/`. Apply the pattern(s) that match the
application's needs. Multiple patterns can coexist in one diagram.

## Pattern 1 — REST API Exposition (SIBS_M2C_PAT_DES_ZZZ_AWS_001_P_RESTAPIExposition)

**Use when**: Application exposes REST APIs to external consumers via APIC (mTLS).

**Required components**:
1. APIC (on-premise/TEIC) -> mTLS connection
2. AWS API Gateway (REST/Regional) with custom domain + Trust Store
3. VPC Link (PrivateLink)
4. NLB (no public IP)
5. ALB (no public IP)
6. ECS Service (target)
7. WAF (attached to API Gateway via Firewall Manager tagging)
8. Lambda Authorizer (CRL & Certificate validation)
9. Route 53 Private (custom domain resolution)
10. ACM (regional certificate)
11. Secret Manager (for credentials/keys)
12. CloudWatch (logs & monitoring)
13. Shared Services -> Trust Store S3 bucket (CA certificates)

**Known limitations**:
- Not covered by Shield Advanced or Palo Alto protections (trade-off for mTLS)
- Terraform limitation on WebACL rule attachment (hashicorp/terraform-provider-aws#39291)
- ALB cannot be used as proxy due to mTLS whitelisting limitation
- HTTP API cannot be used (no WAF support)

**Connection flow**: APIC -> (mTLS) -> API Gateway -> VPC Link -> NLB -> ALB -> ECS Service

## Pattern 2 — ECS Fargate Application (SIBS_M2C_PAT_DES_ZZZ_AWS_001_P_schem_3__APP_CSR_ECS_FARGATE)

**Use when**: Application runs containerized workloads.

**Required components**:
1. ECS Cluster (Fargate launch type)
2. ECS Services (one per microservice)
3. ECR (container registry, with Inspector scanning)
4. ALB or NLB (depending on protocol needs)
5. CloudWatch (container logs)
6. Secret Manager (runtime secrets)
7. Private subnet deployment
8. Security Groups (per service)

**Deployment**: Via the Stellantis CI/CD pipeline (GitHub + TeamCity + Artifactory) — see "CI/CD Deployment Pattern".

## Pattern 3 — Static Web Hosting (SIBS_M2C_PAT_DES_ZZZ_AWS_003_schem1_P_StaticWebHosting)

**Use when**: Application serves a frontend SPA/static website.

**Required components**:
1. S3 bucket (website content, private, access logs enabled)
2. CloudFront distribution (OAI/OAC access to S3)
3. Route 53 (public DNS alias to CloudFront)
4. ACM (global certificate for CloudFront)
5. WAF (attached to CloudFront)
6. AWS Shield Advanced

**Connection flow**: User -> Route 53 -> CloudFront (WAF + Shield) -> S3 (OAC)

## Legacy/Simple Compute Pattern

**Use when**: The application runs on a single (non-clustered) compute instance with no
containerization, no managed database, and a legacy/on-host batch scheduler - typically a
rehosted or lightly-replatformed legacy on-premise batch job, not a cloud-native redesign. Signals
that point here rather than to Pattern 2 (ECS Fargate) or the File Handling Pattern: the source
material explicitly states there is "no database" (data lives in local/attached storage only,
with a retention window rather than a managed data store), the scheduler is named and is not
AWS-native (e.g. Dollar Universe / $Universe, cron, AutoSys, Control-M - anything that predates
the cloud move and is being carried over unchanged), and file exchange with other systems goes
through an existing enterprise file-transfer service (e.g. CFT/CFTS) directly to/from the
instance's local or attached storage, with no S3 staging bucket in the loop. **Do not force this
case into the File Handling Pattern** just because files are exchanged - that pattern assumes an
S3 Inbox/Outbox plus Transfer Family plus event-driven (EventBridge/Step Functions) triggering,
which is a different, more cloud-native design than "the legacy scheduler still runs the jobs on
a single instance, the file-transfer tool is unchanged, and the only thing that moved is the
hosting". Applying File Handling's required components here would silently invent an S3 staging
layer, an event-driven trigger and a Transfer Family endpoint that the real solution does not
have.

**Required components**:
1. EC2 instance (single instance, sized per the application's actual job profile - not an Auto
   Scaling Group unless the source material says the workload is horizontally scaled)
2. EBS volume(s) (attached storage for input/output files and any local working data; if there is
   genuinely no database, say so explicitly rather than leaving the data-layer question open)
3. The legacy/on-host scheduler, named as given by the source (do not substitute
   EventBridge/Step Functions - those belong to the File Handling Pattern's different design)
4. The existing enterprise file-transfer service used for inbound/outbound files (e.g. CFTS),
   connecting directly to the instance - not through an S3 Inbox/Outbox unless the source material
   says files land in S3 first
5. CloudWatch (instance + application-level monitoring, consistent with whatever on-premise
   monitoring approach is being carried over)
6. KMS (EBS volume encryption at rest)
7. Backup mechanism as stated by the source (this may be a non-AWS-native service such as an
   existing enterprise backup tool, carried over unchanged - do not assume AWS Backup /
   aws_backup_retention tagging unless the source says so)

**Known limitations**:
- A single EC2 instance with no clustering is a single point of failure; if the source material's
  stated Availability/RTO/RPO targets look inconsistent with that (e.g. a tight RTO alongside no
  stated failover mechanism), flag it as an open item rather than silently upgrading the design to
  Multi-AZ or adding redundancy the source never mentioned.
- Public-subnet placement of the instance (when the source states this) is itself a security
  signal worth flagging as a Missing-information / open item, not a silent pass-through - the
  question of why a batch-only instance with no inbound web traffic sits in a public subnet
  deserves an explicit answer from the project team or Cloud-Infra.

**Connection flow**:
- Inbound: Upstream system -> (enterprise file-transfer service, e.g. CFT/CFTS) -> EC2 instance
  (reads from local/attached storage) -> scheduler-triggered job processes the file
- Outbound: Scheduler-triggered job writes to local/attached storage -> (enterprise file-transfer
  service) -> Downstream system

## File Handling Pattern

**Use when**: Application exchanges files with external systems via SFTP/MTS2.

**Required components**:
1. S3 App Inbox (decrypted files received)
2. S3 App Outbox (files to send)
3. Transfer Family (SFTP endpoint, in SFS Shared Services account)
4. MTS2 (on-premise file transfer system)
5. PGP encryption (files encrypted in transit)
6. EventBridge or Step Functions (trigger batch processing on file arrival)
7. Batch/ECS jobs (process files)

**Connection flow**:
- Inbound: MTS2 -> (PGP/SFTP) -> Transfer Family -> S3 Inbox -> Batch Job
- Outbound: Batch Job -> S3 Outbox -> (PGP/SFTP) -> Transfer Family -> MTS2

## CI/CD Deployment Pattern (SIBS_M2C_PAT_OPE_DEL_AWS_001_P__Pipeline_CICD_STLA)

**Use when**: Any application/IaC that is deployed to AWS (essentially all of them).

> **CRITICAL — the Stellantis CI/CD stack is NOT AWS-native.** Do NOT use AWS CodePipeline, CodeBuild, CodeCommit, or CodeDeploy. The Stellantis toolchain is external:

**Required components (external tooling, drawn outside the AWS Cloud boundary)**:
1. **GitHub** — source code repository (both application source code AND Infrastructure-as-Code / Terraform)
2. **TeamCity** — CI server: builds, tests, and orchestrates the pipeline (application build + IaC provisioning)
3. **Artifactory** — artifact repository: stores build artifacts (bundles, container images, packages)

**Targets inside AWS**:
- For static hosting (Pattern 3): artifacts are deployed to the **S3** bucket
- For containers (Pattern 2): container images are pushed to **ECR**, then ECS services are updated

**Representation conventions**:
- Draw GitHub, TeamCity and Artifactory using their **official logos**, placed **outside** the AWS Cloud boundary — they are corporate/SaaS tooling, not AWS resources.
- **The logos are bundled with this skill** in `assets/logos/`, with pre-encoded base64 data URIs ready to inline. See `assets/logos/README.md`.
  - GitHub -> `assets/logos/github.png` + pre-encoded `assets/logos/github.b64`
  - TeamCity -> `assets/logos/teamcity.png` + pre-encoded `assets/logos/teamcity.b64`
  - Artifactory -> `assets/logos/artifactory.png` + pre-encoded `assets/logos/artifactory.b64`
- **The logos MUST be embedded as base64 data URIs** so the generated `.drawio` is fully self-contained (auto-carried). Do NOT reference external file paths in the `image=` attribute.
  - **Preferred method**: read the full content of the matching `.b64` file (already in the exact draw.io form `data:image/png,<BASE64>`, no `;base64,`) and set it directly as the `image=` value. No encoding step needed.
  - Style: `shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=1;labelBackgroundColor=#ffffff;image=<CONTENT OF the .b64 file>;` with the tool name + role as the cell `value`.
  - **Preserve the image aspect ratio** — always use `imageAspect=1` (NOT `imageAspect=0`, which stretches/squashes the logo). Never `aspect=fixed` with mismatched width/height.
  - **Impose a uniform maximum image height** across all logos (`height=64`), and use these pre-computed widths (from each logo's native ratio): GitHub `113`, TeamCity `204`, Artifactory `103`.
  - Space the logos horizontally so their (variable) widths do not overlap — leave at least ~30px gap between them.
  - If you ever need to re-encode (e.g., a logo was replaced), see the regeneration snippet in `assets/logos/README.md`. Reference dimensions: GitHub 4000x2262, TeamCity 300x94, Artifactory 1200x746.
  - Fallback only if a logo file is somehow missing: labelled boxes in brand colors (GitHub `#24292E`, TeamCity `#0F7CC0`, Artifactory `#41BF47`) — but the embedded-logo version is the norm since the logos ship with the skill.
- After generation, verify the diagram contains no external image references (no file paths in `image=` — only `data:image/png,` URIs).
- Do NOT place them inside an "Application Account" or a "CI/CD" AWS group.
- Never use `mxgraph.aws4.codepipeline`, `mxgraph.aws4.codebuild`, `mxgraph.aws4.codecommit`, or `mxgraph.aws4.codedeploy` shapes.

**Connection flow**:
- Developer -> **GitHub** (push app code + IaC/Terraform)
- **GitHub** -> **TeamCity** (triggers CI: build + test)
- **TeamCity** -> **Artifactory** (publish build artifacts)
- **TeamCity** / **Artifactory** -> AWS target:
  - Static: deploy bundle -> **S3** (widget bucket)
  - Container: push image -> **ECR** -> deploy -> **ECS**
  - IaC: TeamCity applies **Terraform** to provision/update AWS resources
