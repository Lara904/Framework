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
- **"End users" classification is not always "internal" just because the people are SFS staff
  (found 2026-11, forensic-tooling deck).** The real, team-validated deck classified "SFS CISO
  analysts" under **"External Stellantis users like Partners"**, not "Internal Stellantis
  employees" - a generated deck defaulted the same analysts to "internal users" without checking.
  Do not assume the obvious category for a mixed/contractor-staffed team (e.g. DFIR-EXT); confirm
  the multi-select value the project previously used (or ask) rather than picking the category
  that merely sounds right from the team name.

## Project Summary / Objectives (pos 16)
**Keep the Scope line, even though it looks redundant with slide 9 (found 2026-11,
forensic-tooling deck).** Slide 9's "Scope coverage" is about where the TOOLING is hosted/
processes data (narrower); this slide's "Scope" is about the breadth of what the solution covers
end-to-end (e.g. "all SFS-managed applications: SaaS, cloud-hosted AWS & Azure make-applications,
on-premise, both HQ & local" for a forensic tool whose log SOURCES are far broader than its own
AWS hosting). A generated deck dropped this line entirely while correctly keeping the narrower
slide-9 wording - re-check both fields are present and that neither silently absorbed the other.

**Historical note, resolved at the template level (2026-11):** this slide used to ship with two
decorative photos sitting on top of its "Current situation"/"Target situation" callouts
("Carré corné 25"/27). On inspection they turned out not to be generic stock art but screenshots
of an unrelated real Stellantis project ("Leapmotor") baked into the template itself - invisible
behind the template's own short "Example:" placeholder, but a real legibility defect (and a
content-leak risk: a foreign project's data on every deck built from this template) once real
text was filled in. Removed from `assets/templates/SIBS_Architecture_Gates_Template_V5.2.pptx`
directly (`Remove-PptxImagesFromSlide -Position 16` on the template, a one-time maintenance edit
- not something a filling pass does; the template stays read-only during normal use). A deck
built from the template from this point on has nothing to clean up here: just fill "Carré corné
25"/"Carré corné 27" with the real Current/Target situation text (see Project Synthesis below for
the content - this slide's two callouts are a 2-3 line summary of it, not a duplicate of the full
text). `Get-PptxImageTextOverlaps` (run automatically by `validate-deck.ps1`) stays in place as a
general-purpose check - it is what would catch a similar defect anywhere else, template or
filling pass, before it ships again.

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
- **Do not substitute PIA for TIA (found 2026-11, forensic-tooling deck).** The template's own
  footnote on this slide asks for "**DPA + PIA** (Privacy impact assessment)" when contracting a
  supplier. A **PIA/DPIA** (Data Protection Impact Assessment) and a **TIA** (Transfer Impact
  Assessment, for personal data leaving the EU/EEA) are two different GDPR deliverables - a
  generated deck wrote "DPA and transfer impact assessment (TIA)" where the real, team-validated
  deck wrote "DPA + PIA" for the same project. Default to **PIA** (it is what the template asks
  for and is almost always required); only add/also require a TIA when the project actually
  involves an international data transfer outside the EU/EEA - do not swap one for the other by
  assumption.
- **Carry the read/write invariant forward if it is already established elsewhere in the deck
  (found 2026-11).** If Objectives (pos 8) or Project Summary (pos 16) already states a hard
  privacy-relevant invariant (e.g. "no change on data, read-only access, confidentiality kept via
  encryption"), repeat it here too - a generated deck stated it once on slide 8 and then dropped
  it from the Data Privacy slide itself, where a reviewer looks for it first.

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
- **Verify the column a known figure lands in, cell by cell (found 2026-11, forensic-tooling
  deck).** The global-view table's "Costs types" rows are MERGED across a quarter PLUS a
  "Next year recurrent costs" column; `Set-PptxSlideReplacements` matches the FIRST occurrence
  of the find-text in the slide's raw XML, which is NOT necessarily the run under the intended
  column header if the row's cells share similar placeholder text (several "TBD"/"Xxx K€" runs in
  a row). A real figure (the project's "2.8 K€" IT cost) shipped in the generated deck under the
  wrong column (it landed next to Q2/Q3 instead of the real deck's Q4-with-0-recurrent mapping).
  After filling this table, re-dump the slide (`inspect-slides.ps1`) and check each filled figure
  against its COLUMN HEADER, not just that a value was written - prefer `Set-PptxSlideRuns`
  (run-index addressed, unambiguous) over `Set-PptxSlideReplacements` for this table whenever two
  cells in the same row start as identical placeholder text.

## Risks (pos 23 Risks, pos 65 Residual Risks)
Risk of the current solution (not the demand - that lives in DigitalMe). Table columns: Risk name,
Impact 0..3 (Negligible -> Severe), Likelihood 0..3 (very unlikely -> very likely), Mitigation
plan, Comments. Slide 65 = residual risk (net risk AFTER mitigation).

The template ships four EXAMPLE rows (Gen AI / Accessibility / Lack of training / Data) - these
are indicative prompts, not content to keep (see SKILL.md rule 8d). For each: if applicable,
replace with the real risk; if NOT applicable, **delete the whole row** (do not keep it as "N/A").
Use `Remove-PptxTableRow -ContainsText '<marker>'` (or `-RowIndex`) for the deletion - do not leave
the row's cells blank/empty either, that is still "keeping the row", just invisibly.
Then ADD the project-specific rows the examples miss, keeping the SAME font/size as the body rows.
Never invent Impact/Likelihood scores - propose them as values to validate with the MOA and the
security team.
Example for a static browser front-end (S3 + CloudFront, no back-end): Gen AI row deleted (not
applicable); real risks are accessibility (visible UI), host-site integration conflicts, CDN/
hosting availability, client-side security, and data handling (personal data local to the browser,
handed to the host site).

**Do not thin out the risk register vs. what the project already knows (found 2026-11,
forensic-tooling deck).** A generated deck shipped only 4 risk rows, most scored "TBC", for a
project whose real/validated deck already carried 8 fully-scored, specific risks (tooling
overtake by group-wide tooling, cloud-cost fluctuation, licence-cost escalation, integration
difficulties, log-volume performance, forced supplier change with its own mitigation, AWS
unavailability, forensic-team-member unavailability). If earlier project material (threat
modeling, cost notes, architecture discussions) already surfaces a risk with a concrete
mitigation, carry it into this table scored - do not drop it to "TBC" or omit it because the
gate-fill pass did not independently re-derive it. "TBC" is for a risk that is genuinely new and
unscored yet, not a default for every row.

## Impacted Applications Service (pos 22, 41) / Interactions details (pos 40)
These three tables ship with the template's own EXAMPLE rows pre-filled with an UNRELATED real
project's data (e.g. "PingFederate (PASSEXT/IDP2)", "AWS GLZ Dublin / Websphere zOS",
"Onprem HR / Linux", "OMS VN | Queue / Kafka:8886") - rule 8d applies here exactly as it does to
Risks: if the example row does not apply to this project, **delete it** with
`Remove-PptxTableRow`, do not leave it verbatim. A generated forensic-tooling deck shipped these
example rows untouched on BOTH slides - leaking an unrelated project's application names and
protocols into the delivered deck. `validate-deck.ps1` now hard-fails this
(`Get-PptxLeftoverExampleRowHits` / the "Leftover EXAMPLE table rows" check) - treat a hit there
the same way as a leftover-highlight or leftover-instruction-text failure (rule 10).

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
