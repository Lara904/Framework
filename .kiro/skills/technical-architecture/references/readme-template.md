# Technical Architecture README - template

Alongside the `.drawio` diagram, always write `<project>_technical_architecture_README.md` at the project
root (same convention as the functional skill's README). It is the human-readable companion to
the diagram: it explains the AWS components, the flows, the Landing Zone integration points and
the CI/CD, and it lists assumptions and open questions.

Keep it factual. Anything not confirmed goes under Assumptions / Open questions and must match a
`C?` / TODO marker on the diagram.

```markdown
# <project> - Technical Architecture

Version: <x.y>  |  Date: <YYYY-MM-DD>  |  Author: <name>
Diagram: <project>_technical_architecture_diagram.drawio
Data flow diagram: <project>_technical_architecture_dataflow.drawio
Frameworks diagram: <project>_technical_architecture_frameworks.drawio
DAT: <project>_technical_architecture_document.docx

## Overview
One short paragraph: what the application does technically, which SIBS M2C pattern(s) it uses
(REST API exposition, ECS Fargate, static web hosting, file handling), and whether it has a
backend tier.

## Pattern(s) applied
| Pattern | Applies | Notes |
|---------|---------|-------|
| Static Web Hosting | Yes/No | <e.g. single JS UMD web component, S3 + CloudFront, no backend> |
| REST API Exposition | Yes/No | <mTLS via APIC, API Gateway...> |
| ECS Fargate | Yes/No | <containers...> |
| File Handling | Yes/No | <SFTP / MTS2...> |

## AWS components
| Component | Account / Region | Role |
|-----------|------------------|------|
| CloudFront | Application Account / Global | CDN distribution of the widget |
| S3 (widget) | Application Account / eu-west-3 | Private bucket, widget bundle (OAC) |
| WAF | Application Account / Global | WebACL attached to CloudFront |
| ... | ... | ... |

## Flows
| From | To | Protocol | Purpose |
|------|----|----------|---------|
| End user (browser) | Host website | HTTPS | Loads the host page |
| Host page | CloudFront | HTTPS | Loads the widget (UMD) |
| CloudFront | S3 (widget) | OAC / HTTPS | Fetches the bundle |
| ... | ... | ... | ... |

## Data flows (Data Flow diagram)
Mirrors the separate `<project>_technical_architecture_dataflow.drawio` file, and stays aligned
with the Stellantis **Data flow mapping** (ARIS/CMDB/GDPR) when it exists. `Type` is inter
(between applications) or intra (inside the application). `Crit.` is the official data
confidentiality (C1 public, C2 internal/restricted, C3 confidential/personal-GDPR, C4
secret/highly sensitive, or C? to confirm). `DCP` flags personal data (Yes/No). `Transport` is
the in-transit protection (TLS 1.2+, mTLS, SFTP, PGP, or none for in-browser / same-process).

| # | From | To | Type | Data carried | Crit. | DCP | Transport |
|---|------|----|------|--------------|-------|-----|-----------|
| F1 | End user (browser) | Host web application | inter | Loads the host page | C1 | No | TLS 1.2+ 443 |
| F2 | CloudFront | Widget component | inter | Widget bundle delivered | C1 | No | TLS 1.2+ 443 |
| F3 | S3 (widget) | CloudFront | intra | Bundle origin fetch | C1 | No | TLS 1.2+ (OAC) |
| F4 | End user (browser) | Widget component | intra | Income/expenses input | C3 | Yes | none (in-browser) |
| ... | ... | ... | ... | ... | ... | ... | ... |

## Technical stack (Frameworks diagram)
Mirrors the separate `<project>_technical_architecture_frameworks.drawio` file and the DAT section
2.1.2, and must match the gates Deck slides 30/44 (and 43 if containerized). List the
products/frameworks/runtime/OS with their **versions**. `Applies` is Yes/No (mark the standard
CIQ layers Not applicable rather than hiding them). An undecided version is `XX*` / `TBC` and must
appear in the Missing information table below.

| Layer | Product / Framework | Version | Applies | Notes |
|-------|---------------------|---------|---------|-------|
| Front End | <e.g. Angular> | <e.g. 21 LTS / XX*> | Yes | <i18n, styling, date libs, language> |
| Runtime | <e.g. OpenJDK - Corretto> | <e.g. 21> | Yes/No | <Not applicable for a front-only widget> |
| Core | <e.g. Spring Boot> | <e.g. 4.0> | Yes/No | ... |
| Quality | <e.g. SonarQube / Checkmarx> | <XX*> | Yes | ... |
| Container base image | <e.g. Paketo builder-noble-java-tiny> | <...> | Yes/No | ... |
| ... | ... | ... | ... | ... |

## Landing Zone integration
- Logging: which services log to the LZB Log Account S3 logging bucket.
- Encryption: KMS on S3.
- Monitoring: CloudWatch.
- Security: WAF, Shield Advanced, ACM.

## CI/CD (external Stellantis stack)
- GitHub (app code + IaC/Terraform) -> TeamCity (build/test) -> Artifactory (artifacts) ->
  deploy to <S3 / ECR+ECS>.

## Assumptions
- <anything drawn or stated that is not yet confirmed by the user>

## Missing information (to be provided)
A single consolidated list of everything still unknown, so the reader knows exactly what to
provide to finalize the deliverables. It MUST gather every `TBC` / `C?` / `XX*` / "Not applicable-
to-confirm" marker found in the DAT (`.docx` model), the Data flow mapping (`.xlsx` model), the
architecture, dataflow and Frameworks diagrams - all deliverables and this list must agree. Give
each item an owner and where it lands.

| # | Missing information | Needed for | Owner / source |
|---|---------------------|-----------|----------------|
| M1 | <e.g. Public domain / subdomain for the widget> | DAT 2.7 Domain Name, diagram Route 53 | Platform team |
| M2 | <e.g. Volumetry: widget loads per brand site per day> | DAT 1.3.2 Volumetry, FinOps | Business |
| M3 | <e.g. CMDB/ARIS/GDPR extraction dates and URLs> | Data flow mapping Cover | CMDB / DPO |
| ... | ... | ... | ... |

## Open questions
- <questions pending with the user, mirroring the on-diagram C?/TODO markers>
```

Rules:
- Write in **English** (like all deliverables).
- The README, the architecture diagram, the dataflow diagram, the DAT and the Frameworks diagram must agree (same components, flows, patterns, criticalities and stack versions).
- The Technical stack table matches the Frameworks diagram, the DAT 2.1.2 table and the Deck slides 30/44/43; every `XX*` / `TBC` version has a matching Missing-information row.
- Every `C?` / TODO marker on either diagram has a matching Open question here, and vice versa.
- The **Missing information** table is the single place that consolidates every `TBC` / `C?` /
  `XX*` in the DAT model, the Data flow mapping model and the diagrams (including undecided stack
  versions); keep it in sync whenever any deliverable changes. Each row says what is missing, what
  it unblocks, and who owns it.
- Reference the diagram, dataflow, Frameworks and DAT file names so the deliverables stay linked.
