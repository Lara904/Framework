# Filling Guidance (per topic)

Distilled from the template's yellow placeholders and speaker notes. Use these applicable
values instead of inventing your own. Never fabricate names, costs, SLA or CMDB values.

**Language: English only.** The audience is international, so all filled content is written in
English. If the user provides input in another language, translate it to clear, professional
English before writing it into the deck (do not paste it verbatim).

> **Positions are V5.2** (75-slide template). See `template-structure.md` for the full map.

## Architecture One Pager (pos 9)
Multi-select fields with their allowed values:
- **Demand type**: New Application; Enhancement (no arch/infra change, no SOX/CIA/privacy/user
  impact); Enhancement with arch/infra change or SOX/CIA/privacy/user impact; New Software
  Product Approval Request (PAR); Move to Cloud; Technical migration / Infrastructure
  refreshment (obsolescence); Decommissioning; PoC.
- **Build type**: M2C Rehosting; M2C Replatforming; M2C Refactoring; Based on an existing
  platform; Based on a SaaS solution; Commercial off-the-shelf; In-house ("custom")
  development; Decommissioning; Other.
- **End users**: Internal Stellantis employees (with ID); External users (Partners, Dealers,
  Suppliers); Dealers with/without contract; Stellantis end customers; Other.
- **Regulatory compliance**: SOX/CAC; Personal data GDPR; CCPA; Accessibility.
- **Technologies involved**: Cloud implementation; API used; GenAI; RPA; DATA; IOT; Low-code &
  Citizen Dev; Infrastructure.
- **Cloud implementation type** (if hosted in cloud, not for external SaaS): SAAS / CAAS /
  PAAS / IAAS Cloud.
- **API re-use or new**: API Producer (new) / API Consumer (re-use).
- **Platform re-used**: ADOBE, AR/VR, Blue Prism, DigitalMe Foundry Data4All, GenAI platform,
  IBM API Connect, IOT platform, Microsoft Power Platform, Mulesoft, PEGA, Salesforce, SAP,
  SharePoint/K2, Snowflake Data4All, Stella.AI, Workday.
- Also: business capabilities impacted (with criticality), DigitalMe Demand ID + link,
  primary business domain (e.g. CORF) and other domains (SMKG, EDSC...).
- DORA note: business-critical cloud applications require an exit plan; state the
  substitutability of the service provider.

## Project Synthesis / DICT (pos 12)
CIAT = Confidentiality, Integrity, Availability, Traceability (equivalent to (D/A)ICT).
Values must align with the target CMDB application; note "no change" or "changed from ...".
- **Availability** (max tolerable non-accessibility): 1 = >48h; 2 = 12-48h; 3 = 4-12h; 4 = <4h.
- **Integrity**: 1 = Weak; 2 = Moderate; 3 = Strong; 4 = Critical.
- **Confidentiality**: max confidentiality across the whole pipeline (C1..C4; C4 = auto not
  approved for data initiatives).
- **RTO** (Recovery Time Objective): 1 = 0-48h; 2 = 2-4 days; 3 = 4-7 days; 4 = 7 days;
  5 = Preproduction; 6 = Archive; 9 = not involved.
- **RPO** (Recovery Point Objective): 0 = zero data loss; 1 = 24h max; 2 = 48h max;
  3 = 7 days; 4 = data can be rebuilt; 9 = no data involved.
- **SOX relevance**: any process that can significantly impact financial statements; SOX-relevant
  use cases need specific ITGC controls.
- **DORA compliance**: Yes/No; if Yes, exit plan required.
- Include: main application (New/Update/Decom), suppliers involved, go-live date, dev approach
  (Waterfall/Agile), documents repository link, JV regional impacts.

## SLA / Availability (pos 12, 34, 33)
- SLA is the business owner's expected value, measured end-user side; planned maintenance counts
  as downtime. Design infra + software + process to reach the DICT/SLA target.
- Reference figures: digital apps for average end-users >= 99.95% (~4h/year down); cheap B2B
  single-region app ~99% (~3d/year) may suffice.
- Use https://uptime.is/ for SLA computation. Show maintenance windows and dependency risks
  (a dependency with a lower SLA needs a workaround: retry, design for failure).

## Data Privacy (pos 13)
- List personal data managed; link the self-assessment (Criteria per Gates) for G1 PoC and G2.
- Applicable regulation: EU GDPR, North America CCPA, South America, Asia, etc.
- GDPR/CCPA business processes to anticipate: user can request all data, request deletion,
  refuse data transfer (manual process or embedded feature). Ask the DPO in case of doubt.
- AI Act (AIU-14): guarantee privacy across the AI system lifecycle; remove/obfuscate PII
  before use in an AI system.

## Objectives of the project (pos 16, GEN)
Body text fills the slide's "Objectives" and "Stakes" (benefits) placeholders directly - that
part is routine. The trap on this slide is its **two "Current situation" / "Target situation"
callout boxes**, which the template ships as a worked EXAMPLE for a DIFFERENT, unrelated past
project (not blank placeholders): they contain another project's real narrative text, sized and
positioned for that project's wording, with two `<p:pic>` picture elements layered behind/over
them carrying that same example project's "current/target" diagram snippets.
- **Remove both example pictures first** (`Remove-PptxImagesFromSlide -Position 16`) - leaving
  them in place means a real delivered deck ends up showing a stale, unrelated project's name and
  diagram to the ARB behind the current project's text. This is NOT a diagram slot to keep and
  reuse (contrast with rule 8c's "replace the example image" slides, e.g. slide 42) - slide 16
  has no diagram requirement at all; the pictures are pure leftover and must go.
- **Then replace the example callout text** with this project's actual current/target situation,
  and **re-check the two callout boxes' position** (`<p:sp>` `<a:off>`/`<a:ext>`) against the
  Objectives/Stakes body text box once your text is in: the example project's wording was shorter
  than most real fills, so the boxes as positioned in the template sit low enough to overlap the
  last line(s) of a full-length Stakes paragraph. Nudge the callout boxes down (increase `<a:off
  y=.../>`) rather than shrinking your body text, and re-render/inspect the slide after any text
  length change on this slide specifically - this is the one slide on the deck where "the shapes
  didn't move" and "the text got longer" combine into a near-guaranteed overlap.

## NFR (pos 18)
Mandatory link to the NFR document(s). NFR topics: Security, Compliance (privacy, SOX),
Infrastructure (incl. Cloud), Performance, Compatibility, Usability, Reliability,
Maintainability. Any non-implemented NFR must be justified and validated at the gate
(e.g. a non-implemented security NFR must be validated by the security team).

## Cloud (pos 28-30, 49, 57)
- Provider: AWS by default (justify if not AWS). Landing Zone: AWS Global Landing Zone.
- Regions: eu-west-1 main; backup eu-west-3 if needed (Paris main, Dublin for DRP).
- Network model, connectivity to on-premise (none / private endpoint / VPN), SLA desired vs
  provided, new accounts (PROD + Non-Prod), operating model (build & run teams, Terraform/IaC).
- FinOps: tagging policy, resource automation (start/stop), right-sizing, consumption alerting.

## Cloud: Build & Run organization + Cloud Operating Model (pos 30) - G3/G4
The **Cloud Operating Model** describes HOW the product is managed/operated once in the cloud
(the "who does what, with which tools, under which processes" over the product life), NOT the
technical architecture. Reference: AWS Well-Architected **Operational Excellence** pillar and the
**GDP_CCOE** recommendations. It is a Gate 3 / Gate 4 deliverable (leave TBD at G1/G2).

The slide has three blocks - fill each and strip the guidance runs:
- **Build organization**: which team does the build (app dev vs infra), and the IaC tool
  (Terraform by default on the SFS AWS Landing Zone; justify any other).
- **Run organization**: which team operates/supports in production, and the IaC tool in run
  (consistent with build). (Template duplicates the word "build" here - read it as "run".)
- **Cloud Operating Model** (the description): operating model for Build and for Run - who does
  support (L1/L2/L3, hours, on-call), with which tools (monitoring/alerting, ITSM/ticketing for
  incidents & changes), how incidents and changes are managed; aligned with GDP_CCOE / AWS
  Well-Architected Operational Excellence.

**Ask the user (do not invent) - record answers in the gates README:**
- Who develops the application in **build**? in **run** (maintenance/support)? (e.g. a supplier
  such as SFEIR).
- Who builds and who runs the **infrastructure / IaC**? (e.g. the internal SFS team). Confirm the
  **IaC tool** (Terraform?).
- Which **ITSM tool** manages incidents & changes? (SFS default: **PSASM**.)
- Support levels/hours/on-call, and monitoring/alerting tooling.
For a static front-end (S3 + CloudFront, no back-end) the run model is light: no back-end to
operate, monitor CloudFront/S3 availability + error rates, releases via the CI/CD, incidents via
the ITSM tool; no 24/7 on-call if criticality (DICT) is low.

## DevSecOps (pos 38-39)
- CICD platform: CIQ (https://ciq.mpsa.com) gives access to SonarQube, Artifactory, Checkmarx.
- Software quality: SonarQube report + Quality Gate value (G3), validated report (G4).
- Security: SAST/DAST with Checkmarx scan + action plan with CISO validation (G4).
- Environments: PROD + PREPROD + QA + DEV + STAGING. IaC: Terraform. Blue/green in preprod/prod.

## Costs (pos 24/25, 61/62)
- Global view: quarterly (Q1-Q4) IT costs, cloud consumption, investments (hardware, licenses),
  next-year recurrent costs, over Year 1 / Year 2.
- AWS estimate per environment (Multi-AZ) using the AWS Calculator: region(s), service, monthly,
  annual, currency, configuration summary. Link the shared AWS calculator estimation.
- G3: update planned cost and highlight differences vs G2.

## Risks (pos 23 Risks, pos 65 Residual Risks)
Risk of the current solution (not the demand - that lives in DigitalMe). Table columns: Risk name,
Impact 0..3 (Negligible -> Severe), Likelihood 0..3 (very unlikely -> very likely), Mitigation
plan, Comments. Slide 65 = residual risk (net risk AFTER mitigation).

The template ships four EXAMPLE rows (Gen AI / Accessibility / Lack of training / Data) - these
are indicative prompts, not content to keep (see SKILL.md rule 8d). For each: if applicable,
replace with the real risk; if NOT applicable, **delete the whole row** (do not keep it as "N/A").
Then ADD the project-specific rows the examples miss, keeping the SAME font/size as the body rows.
Never invent Impact/Likelihood scores - propose them as values to validate with the MOA and the
security team.
Example for a static browser front-end (S3 + CloudFront, no back-end): Gen AI row deleted (not
applicable); real risks are accessibility (visible UI), host-site integration conflicts, CDN/
hosting availability, client-side security, and data handling (personal data local to the browser,
handed to the host site).

## Technical architecture diagram (pos 42 global view, pos 33 application flows)
Must include: services/tools for security and logging; flow security (https, mTLS/TLS, SFTP,
encryption) for all internal/external exchanges; all source/destination dependencies (on-prem,
cloud, APIC, partners); managed services with usage context; diagrams for PPROD + DEV.
Network subnet pattern: FRW (firewall -> ICT Palo Alto), PUB (public: ALB / API gateway),
PRIV (private: ECS/EC2 workloads), ISOLATED (databases), TGW (transit gateway).

### Slide 42 - Technical Architecture global view (validated target layout)
This slide is dense with template instructions/tooltips; keep it CLEAN and readable. Reproduce
this exact end state:
1. **Two reference fields only, one filename per field:**
   - "Technical Architecture document" field -> the DAT filename on its own run, e.g.
     `${project_name}_technical_architecture_document.docx` (a `.docx`).
   - "Technical architectural diagram (production):" field -> the diagram filename on its own run,
     e.g. `${project_name}_technical_architecture_diagram.drawio` (a `.drawio`; a `.png` exported
     for the embedded picture).
2. **Strip everything else** (template guidance, not project content): remove the
   "Add here the link ...", the "Link to the file support (draw.io, png): Link (Date & Version)"
   tooltip tails, the "The diagram(s) must include ...", "Remarks", and the
   "Action / Check the following network design pattern" + FRW/PUB/PRIV/ISOLATED/TGW subnet runs.
   Clear those runs (set text to empty) so only the two field HEADINGS + their filenames remain.
   Keep the headings ("Technical Architecture document", "Technical architectural diagram
   (production):") intact.
3. **Diagram picture**: the slide has no free space, so REPLACE the top-right example thumbnail
   with the technical architecture diagram PNG (rule 8c): `Remove-PptxImagesFromSlide -Position 42`,
   then `Add-PptxImageToSlide` into the former example slot (right-aligned to the slide edge),
   preserving the PNG aspect ratio (constrain by the slot height). Do not add a second picture or
   overlap text.
4. Then clear any status banner (slide is validated); it should show no missing markers.

Slide 33 (Application flows) mirrors this: the dataflow diagram PNG goes in the body diagram
zone, and the DAT filename goes in the "... document link here" field only - no extra sentences.

## Interactions details (pos 40)
Columns: consumer, producer, flow type + protocol, exchange format, gateway, authentication,
volume/frequency, New/update/no-change, comment. Use ARIS names. Example gateways: PingFederate
(OIDC/oAuth), APIC in AWS eu-west-1 (JSON REST, oAuth + mTLS), MTS2/SFTP, Kafka.

## Committee (pos 66, 68-70)
Approvers: IT project manager (organizer), IT Manager, Enterprise/Solution/Security/Platform
architects, Data Privacy rep, CISO referent, Solution delivery, Infrastructure referents,
Maintain-in-production resp. Informed: Contract Manager, OPS owner, DRP referent, API catalog
referent, Data platform referent (sibs-cct@stellantis.com), SaaS Manager.
Mark Resp. / Present / Approved (Yes/No) per person. Do not invent approvals.

## Do-not-fill slides
Slides at positions 71-75 are "Reference & examples", the SME directory, the flow-mapping
guideline and the two EXAMPLE diagrams — do not fill them with project content. Slide 2
(revisions index of the template) is the template changelog.
