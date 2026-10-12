# Template Structure — SIBS Architecture Gates V5.2

Authoritative slide-by-slide map, built from the bundled template's slide TEXT **and speaker
notes** (`assets/templates/SIBS_Architecture_Gates_Template_V5.2.pptx`). Use it to know each
slide's purpose, which gate it belongs to, and how to fill it.

- Format: PowerPoint 16:9, 75 slides. Display position N = `ppt/slides/slideN.xml`
  (order from `<p:sldIdLst>`; the bundled scripts resolve it).
- ONE document for all gates (G1 -> G4). Fill only the current gate's section; update earlier
  sections if something changed. Read the yellow guidance + speaker notes, then remove them.
- "Gate" column = the gate(s) where the slide is primarily completed, as stated on the slide
  itself or its speaker notes (not a guess).

> **V5.2 vs V5.1 numbering.** This map was recaled on the real V5.2 template. V5.2 dropped the
> second "Revisions index (your document)" slide and inserted four new content slides:
> **Exit plan for SaaS Applications** (pos 14), **Exit Plan for make cloud applications (AWS)**
> (pos 15), **FOR SOX / CAC Applications** (pos 20) and **DATA MODEL** (pos 43). Net result: 75
> slides. From the old "Objectives of the project" slide onward every position shifted (e.g.
> Technical stack 1/2 is now pos 32 and Technical stack 2/2 is now pos 47, where V5.1 had 30/44).
> Always trust the positions in this file, not any older V5.1 reference.

## Important note on the missing-data heuristic
`find-missing.ps1` flags slides by generic markers (`Link`, `Example`, `List`, `xxx`, `TBD`...).
Some of those markers are part of a slide's LEGITIMATE structure, not leftover guidance - e.g.
"(For example see References section)" on the Overview slide, or a "Link" that denotes a REAL
required deliverable (Cloud eligibility tree, FinOps guidelines, cost details). So a flagged
slide is a prompt to REVIEW, never proof the slide is unfinished. Always read the slide (this
map) before deciding. When a slide's only remaining "gap" is a deliverable link, track it in the
deliverables section (see `deliverables.md`), not as unfilled slide text.

## Cover & front matter (context / not project content)
| Pos | Title | Gate | Purpose / guidance |
|-----|-------|------|--------------------|
| 1 | Cover: "Architecture Gates Dossier - Presentation & Approval" | - | Replace `<<Name of the project>>`. |
| 2 | Revisions index of the template | - | Template's own changelog (now the ONLY revisions index in V5.2; the separate "your document" revisions slide was removed). Leave as-is. |
| 3 | Introduction | - | Explains the Architecture Gates / ARB (ex-TCC) process. Context. |
| 4 | Approval process: Study/NO/Discovery | - | Process diagram (audit controls) for Gates 1-2 phase. |
| 5 | Approval process: Realisation/NE/Delivery | - | Process diagram for Gates 3-4 phase. |
| 6 | NOTES - User guide | - | How to use the template: fill only your gate's section, remove yellow, rely on the Criteria-per-Gates list. |
| 7 | Table of content | - | Sections + the four gates. Indicate the validation date of the submitted gate. |

## Objectives & synthesis
| Pos | Title | Gate | Purpose / guidance |
|-----|-------|------|--------------------|
| 8 | Objectives (points to validate) | G1/G2 | List the points to be validated at the gate (functional & technical architecture, cybersecurity, data privacy, costs, timelines; SaaS: exit plan). Solutions are defined and problems solved BEFORE the gate. |
| 9 | Architecture One Pager (Demand/Project Overview) | G1 / G1 PoC | Demand type, build type, business capabilities impacted (+ criticality), business applications, related records (GenAI/BrightIdea/DigitalMe/RPA ids), regulatory compliance, technologies, cloud implementation type, API re-use/new, platform re-used, decommissioning, scope (regions/plants/brands/countries), end users, DigitalMe Demand ID, primary/other business domains. Applicable values are in the speaker notes. |
| 10 | Architecture Overview Diagram | G1 / G1 PoC | High-level As-Is/To-Be diagram of the solution - a visual reflection of slide 9. ("For example see References section" is template text, not a gap.) |
| 11 | Applicability | G1 | Mark each domain Yes/No (API, Cloud, Data, Data privacy, DevSecOps, Enterprise Architecture, Gen AI, Infrastructure, Cybersecurity, Accessibility, IOT, RPA, LowCode, Services Contracts, HW/SW Contracts). Confirmed by the Enterprise Architect vs the Global Criteria List. Non-applicable domains/slides are hidden and not discussed. |
| 12 | Project information / Project Synthesis | G2 | Main application; DICT/CIAT levels (Availability/Integrity/Confidentiality/Traceability), RTO/RPO, SLA - aligned with the CMDB; SOX, DORA required (Y/N), suppliers, go-live date, dev approach (Waterfall/Agile), documents repository, JV regional impacts. Value scales are in the speaker notes. |
| 13 | Data Privacy | G1 PoC / G2 | Personal data handled; link the self-assessment (Criteria list); regulation (EU GDPR, CCPA...); GDPR business processes (access/delete/refuse transfer); AI Act (AIU-14). |
| 14 | Exit plan for SaaS Applications | G2 (SaaS) | **NEW in V5.2.** DORA compliance + SaaS contract management (provider, responsible persons, subcontractors, critical functions, contract end date, termination notice) and SaaS exit readiness (exit plan in contract, support during exit, data migration ease, exit readiness level, substitutability, reintegration, estimated cost, likelihood, test plan). Fill only when the solution is/relies on a SaaS. **Hide if no SaaS.** |
| 15 | Exit Plan for make cloud applications (AWS) | G2 (Cloud) | **NEW in V5.2.** Exit plan for a "make" cloud (AWS) solution: contract management for a non-CSP service provider, landing-zone/CSP info, vendor lock-in avoidance (containers/terraform, open standards), exportability of compliance artefacts, redeployability on another CSP, exit cost/likelihood/testing. **Hide if not an AWS/make cloud build.** |
| 16 | Objectives of the project | GEN | Objectives, stakes, benefits (project summary). |

## Functional & Enterprise architecture
| Pos | Title | Gate | Purpose / guidance |
|-----|-------|------|--------------------|
| 17 | Functional Architecture - dependencies macro view | G2 | Functional architecture document (link) + functional diagram (app interactions, user profiles/localization/access mode), decommissioning list. Validated by the Functional Architect before the technical gate. |
| 18 | Non-Functional Requirements (NFR) | G2 | NFR document link (MANDATORY). Compliance; any non-implemented NFR justified and validated at the TCC. Topics: security, compliance, infrastructure, performance, compatibility, usability, reliability, maintainability. |
| 19 | Enterprise Architecture - dependencies macro view | G2 | Business/functional application flow (ARIS) + link; flow mapping. Validated by the Enterprise Architect. (N/A if no data-model/flows.) |
| 20 | FOR SOX / CAC Applications | G2 (SOX) | **NEW in V5.2.** Stock-flow identification and controls ("Control Tower" architecture) for SOX/CAC financial data flows: scope, securing inter-SOX / inter-IFRS9 flows and General-Ledger ITD treatments, discrepancy alerting via PSASM. To review with the Risk team. **Hide if the application is not SOX/CAC relevant.** |
| 21 | SOLUTION TO BE VALIDATED (divider) | - | Section divider; duplicate the solution block for alternatives. |
| 22 | Enterprise Architecture - Impacted Applications Service | G2 | Table from CMDB: AIC/SOX/Data Privacy severity/hosting/technology/RTO-RPO/SLA; decommissioned applications. |
| 23 | Solution - Risks | G1 PoC, G2/4 | Risk name, Impact (0..3), Likelihood (0..3), mitigation. Consider GenAI, accessibility, lack of training. Risks of the solution (not the demand). |
| 24 | Costs (global view) | G1 PoC, G2/4 | Quarterly IT/cloud/investment costs + next-year recurrent, Year 1/2 (K amounts); links to detailed cost docs. G3 highlights deltas vs G2. |
| 25 | (Solution X) Costs (AWS estimate) | G2/4 | Per-environment AWS Calculator estimate (region, service, monthly/annual, currency, config summary) + link. |
| 26 | (Solution X) Timeline | GEN | Macro schedule with key milestones, sprint duration (agile), critical path; link + version. |
| 27 | Summary of the Solutions | GEN | Criteria x Solution comparison (smileys) + recommended solution. |

## Cloud
| Pos | Title | Gate | Purpose / guidance |
|-----|-------|------|--------------------|
| 28 | Presentation of the Cloud Project (Cloud Eligibility Tree) | G1 PoC / G2 | Positioning vs SFES cloud strategy; the **Cloud Eligibility Tree** (diagram + link + version/date) proving the project's eligibility to use the cloud; implementation typology (New/Replatforming); provider (AWS, else justify). |
| 29 | Cloud (architecture) | G1 PoC / G2 | Provider, Landing Zone, main/backup regions, network model, on-prem connectivity, SLA desired vs provided, new accounts (PROD + Non-Prod). |
| 30 | Cloud: Build & Run organization | G3 / G4 | Build/Run teams (app dev vs infra/IaC), IaC (Terraform) confirmation, and the **Cloud Operating Model** (who supports, with which tools/ITSM, how incidents & changes are managed; AWS Well-Architected Operational Excellence / GDP_CCOE). Ask the user for these inputs - see filling-guidance "Cloud operating model". |

## Technical architecture (Solution X)
| Pos | Title | Gate | Purpose / guidance |
|-----|-------|------|--------------------|
| 31 | Technical Architecture - global description | GEN | Main aspects, selection criteria, common elements, macro description of each solution. |
| 32 | Technical stack (1/2) | G3 | Products/frameworks/OS with versions (CMS, back-end, front-end, DB, OS). "TO BE COMPLETED AT GATE 3". |
| 33 | Application Flows technical diagram | G2 / G1 PoC | Data-flow applicative diagram + technical architecture doc link. Notes list what to show (systems, direction, gateways, hosting/region, auth, CICD). |
| 34 | Availability, SLA | GEN | Global SLA, per-environment SLA, SLA per function, maintenance/shutdown windows. |
| 35 | Data summary | DATA | Business owner, data managers, target solution, milestones. **Hide if no data.** |
| 36 | Functional objects for [data platform] | DATA | Functional objects & sources (confidentiality, personal data, retention, disposal). **Hide if no data.** |
| 37 | Power BI sizing - technical information | DATA | Ingestion, SKUs, users, refresh, confidentiality. **Hide if no data.** |
| 38 | DevSecOps | G1 PoC / G2 | CICD platform (CIQ), software quality (SonarQube), SAST/DAST (Checkmarx), test strategy. CIQ gives access to SonarQube/Artifactory/Checkmarx. |
| 39 | DevSecOps (environment) | G2 + G3 | Environments (PROD/PREPROD/QA/DEV/STAGING), IaC (terraform), deployment, blue/green (Gate 3). |
| 40 | Enterprise Architecture - interactions details | G2 | Consumer/producer, flow type+protocol, exchange format, gateway, authentication, volume, new/update/no-change (ARIS names). |
| 41 | Enterprise Architecture - Impacted Applications Service | G2 | Same CMDB table as pos 22. |
| 42 | (Solution X) Technical Architecture global view | G2 | Production technical diagram (draw.io/png) + technical doc link; must show security/logging services, flow security (https/mTLS/TLS/SFTP), all source/destination dependencies, managed services (in the DAT), PPROD+DEV; subnet pattern FRW/PUB/PRIV/ISOLATED/TGW. **Fill CLEAN (validated layout):** only the DAT `.docx` filename in the "document" field and the diagram `.drawio` filename in the "diagram (production)" field; strip all tooltip/instruction/subnet-pattern runs; replace the top-right example thumbnail with the diagram PNG. See filling-guidance "Slide 42 validated target layout". |
| 43 | DATA MODEL | G2 (Data) | **NEW in V5.2.** Enterprise/Business Data Model deliverable (link to the data model, based on the examples). **Hide if no data model.** |
| 44 | API | G2 | API gateway (IBM APIC in AWS eu-west-1), consumer/producer; new vs subscribed API. |
| 45 | Gen AI | G2 + G3 | GenAI gateway, cost estimation (G1 PoC/G2), API keys per environment (G3). |
| 46 | Container orchestrator - technical stack | G3 | Container stack example (Docker, Apache, PHP, Symfony, MySQL, TLS). "TECHNICAL STACK (gate 3)". |
| 47 | Technical stack (2/2) | GEN | Remaining stack; upgrade at least yearly. |
| 48 | Technical Architecture global view (focus) | GEN | Extra diagrams: monitoring/alerts, backup strategy, environments, obsolescence, exit/reversibility plan. |
| 49 | Localization | CLOUD | AWS regions/AZ required vs business context (Paris; Dublin for DRP); end-user localization and latency checks. |
| 50 | Environments needs & Account organization | CLOUD (G3) | List of cloud environments (Dev/Preprod/Prod on Stellantis AWS LZ) and account organization; justify any extra environment (cost impact). |
| 51 | Existing migration strategy | M2C | Migration of existing features (DMS/CDC/SQL), coexistence vs big bang. |
| 52 | Batch strategy | if applicable | List/orchestration of batches (AWS Batch, EventBridge, Step Functions, Airflow) - only if batch processing exists. |
| 53 | Data-flow | GEN | Data-flow document link (draw.io/png), updated continuously (Build & Run). |
| 54 | Application architecture: SSDLC | GEN | SSDLC progress (AWS / on-premise). |
| 55 | Access rights | GEN | Application roles matrix (business, Dev&Ops, technical accounts) + link. (N/A if no roles/back-office.) |
| 56 | Environment deployment | GEN | CI/CD pipeline pattern (image copy, ECR purge, Artifactory on-prem historization, non-prod stop/relaunch rules). |
| 57 | Tagging and FinOps strategy | CLOUD | Tagging policy + FinOps guidelines (links) to KEEP and confirm the project applies them: resource automation, right-sizing, cost monitoring, consumption alerting. |
| 58 | Monitoring | G2 / G3 | Critical metrics + thresholds, alerting to the product team. G3 updates vs G2. |
| 59 | RPA | if applicable | RPA portal idea, demand form, assessment, checkpoint. **Remove if no RPA.** |
| 60 | Low code & Citizen development | G3 | Roles/permissions, deployment package, GitHub. **Remove if not used.** |
| 61 | (Solution X) Costs (AWS estimate) | GEN | Same AWS estimate table as pos 25. |
| 62 | Costs (global view) | GEN | Same quarterly cost table as pos 24. |
| 63 | Threat modeling - Report | G2 | Threat modeling planned/validated with the SFES Cybersecurity team before the TCC. (Slide text tags it "Gate 2"; still finalised/validated by G4.) |
| 64 | Application architecture: SSDLC | GEN | Same SSDLC slide as pos 54 (V5.2 adds SaaS / Azure variants). |
| 65 | Solution - Residual Risks | G1 PoC, G2/4 | Residual risks after mitigation (same structure as pos 23). |

## Committee / approval
| Pos | Title | Gate | Purpose / guidance |
|-----|-------|------|--------------------|
| 66 | Technical Check Committee after Design - approvers | G3 | Approvers/informed table (architects, security, data privacy, CISO, infra, ...). Fill Resp./Present/Approved. |
| 67 | Summary of the Solutions | GEN | Same comparison table as pos 27. |
| 68 | Technical Check Committee initial - Approval | G2 | Global decision, approved solution. Mandatory before DOPCO/CIO. Dispenses validated by the CTO team. |
| 69 | Technical Check Committee initial - Actions | G2 | Actions requested by approvers (code, responsible, other actors, due date). |
| 70 | Technical Check Committee initial - approvers | G2 | Approvers/informed table (as pos 66). |

## References & examples (never fill - reference only)
| Pos | Title | Purpose |
|-----|-------|---------|
| 71 | Reference & examples (divider) | "Not to fill in your presentation." |
| 72 | Subject Matter Experts | Directory of SMEs per topic (Cloud, API, DevSecOps, Security, Data, FinOps, SOX, Contract, Accessibility, SaaS...). |
| 73 | Functional & Technical flow mapping - guideline | Flow mapping (mandatory, continuous): initialized end-of-study G2, completed end-of-design G3, validated Go-Live G4; centralized in DocInfo. |
| 74 | Architecture Overview Diagram - EXAMPLE | Example As-Is/To-Be diagram. |
| 75 | Timeline for Data project - EXAMPLE | Example data project macro schedule. |

## Notes
- Repeated slides (Costs 24/62, AWS Costs 25/61, Summary 27/67, SSDLC 54/64, Impacted Apps 22/41)
  support multiple solutions / gates.
- "Solution X" / "Solution 1" blocks are meant to be duplicated for alternative solutions.
- CIAT = Confidentiality, Integrity, Availability, Traceability; equivalent to (D/A)ICT in a
  different letter order.
- Data section = slides 35-37 + Data Model 43 (hide if no data). RPA = 59, Low-code = 60,
  GenAI = 45, Batch = 52, SOX stock-flow = 20, Exit plans = 14 (SaaS) / 15 (make cloud) -
  hide/N/A if not applicable, per the Applicability slide.
