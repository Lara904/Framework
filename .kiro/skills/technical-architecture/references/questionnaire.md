# Clarifying Questions (ask before generating)

This skill is interactive. Before generating the diagram, the README and the DAT, ask the user
the questions below - adapting to what is already known from the conversation, the functional
README, or existing files. Group them; do not dump all at once if a few answers already settle
the design. Record every answer in the README and the DAT; mark anything unresolved as an
assumption + open question, with a matching `C?` / TBC marker on the diagram.

> Ask only what you genuinely need. If the user has already described the app (e.g. "single JS
> UMD web component in S3 behind CloudFront, no backend"), confirm the key inferred choices in
> ONE short round of questions rather than interrogating them section by section.

## 1. Application & purpose
- What does the application do, in one or two sentences?
- Solution name (for file names and titles) and author name (for the Versions page / DAT)?
- Is there an existing functional README / diagram to align with?

## 2. Pattern selection (drives the diagram)
- Does it serve a **static frontend** (SPA / web component)? -> Static Web Hosting (S3 + CloudFront).
- Does it expose **REST APIs** to external consumers? -> REST API Exposition (APIC / mTLS).
- Does it run **containers / backend services**? -> ECS Fargate.
- Does it **exchange files** with external systems (SFTP / MTS2)? -> File Handling.
- More than one may apply. If none of the above, ask the user to describe the runtime.

## 3. Backend / compute
- Is there any backend tier at all, or is it front-only? (A front-only app has no VPC, subnets,
  Transit Gateway, Egress account, etc.)
- If backend: which compute (ECS Fargate, Lambda, Batch)? How many services? Sizing known?
- Any database (RDS Postgres/MySQL, MongoDB Atlas)? Any cache?

## 4. Integrations & auth
- Which external systems does it call? (APIC, MTS2/Secur-IT, LDAP, SMTP, Kafka/MSK, Bedrock,
  third-party SaaS...)
- Authentication/authorization? (OIDC via Ping Federate, mTLS, Cognito, IAM roles...)
- On-premise connectivity needed? (Direct Connect / Transit Gateway.)

## 5. Frontend / exposure (if applicable)
- Public DNS / domain name? Managed by Route 53?
- TLS certificate via ACM? WAF + Shield Advanced on CloudFront (or on ALB/API Gateway)?
- For a widget: how is it loaded by the host site (remote script / UMD bundle)?

## 6. Data & security (for the DAT)
- What data is processed, and where does it live? Any personal data?
- Encryption at rest (KMS) and in transit (TLS/HTTPS) - confirm.
- Data retention period? Logging destination (LZB Log Account)?
- Network filtering (security groups, public/private subnets) - if there is a backend.

## 6bis. Data flows (for the separate Data Flow Diagram)
Needed to build the separate Data Flow Diagram file (see `data-flow-diagram.md`). Ask only what is not already
clear from the architecture answers:
- Is there an existing **Data flow mapping** spreadsheet (the Stellantis ARIS/CMDB/GDPR flow
  inventory)? If so, reuse its flows, C1/C2/C3/C4 values and DCP flags rather than re-deriving.
- Which **applications/systems/actors** exchange data with this app (inter-application flows)?
- Which **internal tiers/components** exchange data inside the app (intra-application flows,
  e.g. browser widget -> host page, service -> database)?
- For each flow: **what data** does it carry, and how sensitive is it on the official
  **C1/C2/C3/C4** scale? (C1 public, C2 internal/restricted, C3 confidential/personal-GDPR,
  C4 secret/highly sensitive.) And does it carry **personal data (DCP=Yes/No)**? Align DCP=Yes
  with the DICT/GDPR reading - any personal/financial data flow is DCP=Yes (usually >= C3).
- For each flow: **transport protection** - TLS 1.2+, mTLS, SFTP, PGP, or `none` (in-browser /
  same-process)? Port and protocol if relevant.
- If a flow's criticality, DCP or protection is unknown, do NOT guess - it becomes a `C?` on the
  diagram + an Open question in the README + a TBC note in the DAT.

## 6ter. Technical stack (for the Frameworks diagram, DAT 2.1.2 and Deck slides 30/44/43)
Needed to build the Frameworks diagram (see `frameworks-diagram.md`) and fill the DAT technical
stack table and the gates Deck. Reuse whatever is already known from the repo / functional README;
ask only for the gaps. Never invent a version - an undecided version becomes `XX*` / `TBC`.
- **Front End**: UI framework + version (e.g. Angular 21 LTS, React, plain TS/JS UMD)? i18n,
  styling/layout libs, date/format libs, language (TypeScript/JS)?
- **Back End** (if any): language runtime + distribution + version (e.g. OpenJDK 21 - Corretto)?
  Core framework + version (Spring Boot/Core, Quarkus, Node/Express, ...)? Web, Data/ORM,
  Messaging, Batch layers used?
- **Corporate baseline**: parent POM / build baseline (e.g. PSA `ciq-java-parent`)? BOM strategy?
- **Security / quality / testing / documentation tooling**: dependency scanning, SonarQube,
  Checkmarx, test frameworks, OpenAPI docs?
- **Container base image** (if containerized): base image / buildpacks (e.g. Paketo
  builder-noble-java-tiny) and layers?
- Which of the standard CIQ layers are **Not applicable** for this app (e.g. all Spring/Java
  layers for a front-only widget)?

## 7. Environments & CI/CD
- Which environments (dev/staging/prod)? Account organization?
- CI/CD: confirm the Stellantis external stack (GitHub + TeamCity + Artifactory + Terraform).
  Deploy target: S3 (static) or ECR+ECS (containers)?

## 8. DAT specifics
The DAT MUST follow the official Stellantis DAT template outline (see `dat-document.md`). Ask:
- Any revision history to seed the "Fiche d'evolution" / revision table?
- Any figures/links to reference (existing diagrams, tickets, cost estimates)?
- For each mandatory section of the official outline (Requirements incl. Volumetry/Compatibility,
  Data Architecture layers, Continuous Integration, Platform Maintenance, Security, Supervision,
  Backup/Restoration, FinOps), what content applies? A section that does NOT apply keeps its
  heading with a short "Not applicable"/"TBC" note - it is never silently dropped.

## When answers are missing
- Do NOT invent services, flows, ports, sizing, or integrations.
- Generate what is confirmed; for each gap, add a visible `C?` marker on the diagram, a "TBC"
  note in the DAT, an `XX*` / `TBC` version on the Frameworks diagram, and an Open question in the
  README. Then ask the user.
- All deliverables (architecture diagram, dataflow diagram, dataflow mapping, README, DAT,
  Frameworks diagram) must stay consistent - same components, flows, criticalities and stack
  versions.
