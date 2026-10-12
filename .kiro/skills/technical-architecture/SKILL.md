---
name: technical-architecture
description: Generate and validate TECHNICAL AWS architecture diagrams (draw.io) for the SFS NG Landing Zone, based on the official template and the SIBS M2C patterns. Also manages the application technical stack (products/frameworks/runtime/OS with versions) and renders it as a Frameworks diagram, writes a technical README and a complete single-file Technical Architecture Document (DAT) in Word. Asks the user clarifying questions when details are missing. For the FUNCTIONAL view (companies, applications, interactions, users) use the functional-architecture skill instead.
keywords:
  - technical architecture
  - architecture
  - diagram
  - drawio
  - aws
  - landing zone
  - sfs
  - sibs
  - pattern
  - schema
  - technical stack
  - frameworks
  - framework diagram
  - stack
  - spring
  - angular
  - versions
---

# Technical AWS Architecture Diagram Generation (SFS NG Landing Zone)

This skill generates and validates **technical** AWS architecture diagrams in draw.io
(`.drawio`) format, based on the official **SFS-AWS_NG-Architecture_design_template** and the
**SIBS M2C** patterns. It produces self-contained diagrams that match the validated Stellantis
Landing Zone architecture (VPCs, subnets, AWS services, flows, CI/CD).

It also produces a **separate Data Flow Diagram** deliverable (`.drawio`) that illustrates the
inter- and intra-application flows, with the **data criticality (C1/C2/C3)** and the **transport
protection (TLS / mTLS / SFTP / none)** shown on every flow - see `references/data-flow-diagram.md`.

Like the functional skill, it also writes a **technical README** (`.md`) next to the diagram,
and it generates a **complete single-file Technical Architecture Document (DAT)** in Word
(`.docx`) - merging the main architecture document and the AWS complement into ONE document. The
DAT generator is self-contained (no external template or example file required).

It also manages the application **technical stack** (products, frameworks, runtimes and OS with
their **versions**) and renders it as a **Frameworks diagram** (`.drawio`) - the "building blocks"
view that complements the AWS infrastructure diagram. The same stack information feeds the DAT
(section 2.1.2 Applicative components) and the gates Deck (slides 30/44 "Technical stack", 43
"Container orchestrator") and MUST stay consistent across all three - see
`references/frameworks-diagram.md`.

> For a **functional** architecture diagram (companies ICT/SFS, their applications, the
> interactions between applications, and the main users), use the separate
> **functional-architecture** skill. This skill is the technical/infrastructure view.

## When to use this skill
Activate this skill when the user wants to:
- Create a new AWS architecture diagram for an application on the SFS NG Landing Zone
- Modify or extend an existing `.drawio` architecture diagram
- Validate a diagram against the template and the SIBS patterns
- Apply a specific pattern (REST API exposition, ECS Fargate, static web hosting, file handling, CI/CD)
- Define or update the application **technical stack** (products/frameworks/runtime/OS with versions) and produce the **Frameworks diagram** that feeds the DAT and the gates Deck

## Bundled assets (inside this skill)
- `assets/templates/` — the authoritative source diagrams (the template is the source of truth):
  - `SFS-AWS_NG-Architecture_design_template.v0.3.drawio` — the master template
  - `FMK_Diagram_template.drawio` — the authoritative technical-stack / **Frameworks diagram** template (Angular front-end + OpenJDK/Spring back-end, Corretto runtime, Paketo container base image, quality/testing/documentation tooling). Source of truth for the stack layout — see `references/frameworks-diagram.md`.
  - `SIBS_M2C_PAT_DES_ZZZ_AWS_001_P_RESTAPIExposition_v0.6.drawio` — REST API (mTLS)
  - `SIBS_M2C_PAT_DES_ZZZ_AWS_001_P_schem_3__APP_CSR_ECS_FARGATE_V1.0.drawio` — ECS Fargate
  - `SIBS_M2C_PAT_DES_ZZZ_AWS_003_schem1_P_StaticWebHosting_V01.1.drawio` — Static web hosting
  - `SIBS_M2C_PAT_OPE_DEL_AWS_001_P__Pipeline_CICD_STLA_V01.2.pdf` — CI/CD pipeline
  - `DAT_template.docx` / `DAT_template.model.json` — anonymized DAT template (official Stellantis
    structure, other-project content removed, reviewer PII kept). Provenance/reference only.
  - `Data_flow_mapping_template.xlsx` / `Data_flow_mapping_template.model.json` — anonymized Data
    Flow Mapping template (official Cover/Functional/Technical sheets, other-project flows removed).
    Provenance/reference only.
- `assets/logos/` — official CI/CD tool logos (GitHub, TeamCity, Artifactory) with pre-encoded
  base64 data URIs (`.b64`) ready to inline. See `assets/logos/README.md`.
- `assets/scripts/` — self-contained PowerShell generators (no Python / Office needed):
  - DAT `.docx`: `DatDocx.psm1` (module), `build-dat.ps1` (wrapper), `validate-dat.ps1` (OPC validator).
  - Data Flow Mapping `.xlsx`: `FlowMappingXlsx.psm1` (module), `build-flowmapping.ps1` (wrapper), `validate-flowmapping.ps1` (OPC validator).
  See `assets/scripts/README.md`.

## Six deliverables (always produce all six)
All six are written to the per-project output folder `output/${project_name}/` (create it if
missing) - see the `output-convention.md` steering (single source of truth for output location).
All six share the naming convention `${project_name}_technical_architecture_<kind>`:
1. `<project>_technical_architecture_diagram.drawio` — the technical AWS diagram (Versions page first, then the Architecture page[s]).
2. `<project>_technical_architecture_dataflow.drawio` — the **Data Flow Diagram** (a separate file): inter/intra-application flows with C1/C2/C3/C4 data confidentiality, DCP flag and TLS/mTLS transport, its own Versions page first — see `references/data-flow-diagram.md`.
3. `<project>_technical_architecture_dataflow_mapping.xlsx` — the **Data Flow Mapping** workbook (a separate Excel file): the official Stellantis flow inventory (Cover + Functional Flow Pattern + Technical Flow Pattern, C1-C4 + DCP) — see `references/data-flow-mapping.md`.
4. `<project>_technical_architecture_README.md` — the technical README (includes a Data Flow table and a consolidated **Missing information (to be provided)** table gathering every `TBC`/`C?`) — see `references/readme-template.md`.
5. `<project>_technical_architecture_document.docx` — the single-file Technical Architecture Document (DAT), whose Flows Matrix carries the C1-C4 + DCP columns and whose section 2.1.2 carries the technical stack table — see `references/dat-document.md`.
6. `<project>_technical_architecture_frameworks.drawio` — the **Frameworks diagram** (a separate file): the technical stack (products/frameworks/runtime/OS with versions) as a layered "building blocks" view, its own Versions page first. Feeds the DAT 2.1.2 and the gates Deck slides 30/44/43 — see `references/frameworks-diagram.md`.

All deliverables are written in **English**. The intermediate models, if kept, are
`<project>_technical_architecture_document.model.json` and
`<project>_technical_architecture_dataflow_mapping.model.json`.

## Ask before generating (clarifying questions)
This skill is interactive. Before generating, ask the user the questions in
`references/questionnaire.md` (application purpose, pattern selection, backend/compute,
integrations & auth, exposure, data & security, technical stack, environments & CI/CD, DAT
specifics). Ask only
what you genuinely need - if the app is already described, confirm the key inferred choices in
one short round rather than interrogating section by section. Do not invent services, flows,
ports, sizing or integrations: unknowns become a `C?` marker on the diagram, a "TBC" note in the
DAT, and an entry in the README **Missing information (to be provided)** table (plus an Open
question), then ask the user. That table is the single consolidated list of every `TBC` / `C?`
across the DAT, the Data flow mapping and the diagrams, with what each item unblocks and who owns
it - keep it in sync whenever any deliverable changes. See `references/readme-template.md`.

## Reference guides (load on demand)
Read the relevant reference file(s) in `references/` for the task at hand:
- `references/questionnaire.md` — clarifying questions to ask the user before generating
- `references/architecture-context.md` — accounts, network topology, subnets, component inventory
- `references/patterns.md` — the SIBS patterns (REST API, ECS Fargate, static hosting, file handling, CI/CD) with required components and flows
- `references/data-flow-diagram.md` — the separate Data Flow Diagram spec (inter/intra flows, C1/C2/C3/C4 confidentiality scale, DCP flag, TLS/mTLS encryption labels, legend, node/edge conventions)
- `references/data-flow-mapping.md` — the Data Flow Mapping `.xlsx` spec (official Stellantis workbook: Cover + Functional/Technical Flow Pattern, C1-C4 + DCP, JSON model schema)
- `references/generation-process.md` — step-by-step generation (strategies, LZ integration points, component selection, style conventions, AWS icon reference, encoding rules)
- `references/layout-validation.md` — geometry/overlap/containment validation and reference dimensions
- `references/output-format.md` — six deliverables, Versions page (table format), file output rules
- `references/readme-template.md` — the technical README template (companion to the diagram)
- `references/dat-document.md` — the DAT outline + JSON model schema for the `.docx` generator
- `references/frameworks-diagram.md` — the technical stack + Frameworks diagram spec (stack layers/categories, source template, tailoring rules, consistency with DAT 2.1.2 and Deck slides 30/44/43)

## Core rules (always apply)
1. **The template is the source of truth.** Start from a copy of the template (Strategy A) or assemble
   from patterns while including all Landing Zone integration points (Strategy B). When in doubt, KEEP a component.
2. **Never omit mandatory Landing Zone infrastructure** (e.g., LZB Log Account, logging flows) — see
   `references/generation-process.md`.
3. **CI/CD is the external Stellantis stack** (GitHub + TeamCity + Artifactory), drawn OUTSIDE the AWS Cloud
   boundary. Never use AWS CodePipeline/CodeBuild/CodeCommit/CodeDeploy.
4. **Self-contained output**: embed logos as base64 from `assets/logos/*.b64`. No external image references.
5. **Latest AWS icon set** (`mxgraph.aws4.*`), `strokeColor=#ffffff` on service icons, human actors use
   `shape=mxgraph.aws4.user` (no dark tile).
6. **UTF-8 without BOM, ASCII-only text** in cell values (avoid em dashes/bullets/curly quotes → mojibake).
7. **Versions page** is always a predictable table (Version / Date / Author / Description).
8. **Always produce the Data Flow Diagram as a SEPARATE file** (`<project>_technical_architecture_dataflow.drawio`,
   its own Versions page first): show inter- and intra-application flows, label each flow with its
   data confidentiality on the official Stellantis **C1/C2/C3/C4** scale (or `C?` if unknown), a
   **DCP** flag (personal data Yes/No), and its transport protection (TLS 1.2+, mTLS, SFTP, PGP,
   or `none` for in-browser / same-process), plus the criticality/DCP/encryption legend — see
   `references/data-flow-diagram.md`. It is the graphical view of the Stellantis **Data flow
   mapping** (ARIS/CMDB/GDPR); reuse that mapping's values when it exists. Never invent a
   criticality, DCP or protocol: unknowns become `C?` (dashed grey) + an Open question.
9. **Always produce the Data Flow Mapping as a SEPARATE `.xlsx`** (`<project>_technical_architecture_dataflow_mapping.xlsx`):
   the official Stellantis workbook (Cover + Functional Flow Pattern + Technical Flow Pattern) with
   the C1/C2/C3/C4 confidentiality and DCP columns. Build it with the self-contained generator
   `assets/scripts/build-flowmapping.ps1` and validate it with `assets/scripts/validate-flowmapping.ps1`.
   Keep it consistent with the DFD and the DAT Flows Matrix (same flows/values) — see
   `references/data-flow-mapping.md`.
10. **Output** goes to `output/${project_name}/` (see the `output-convention.md` steering; create it if missing): the architecture `.drawio`, the dataflow `.drawio`, the dataflow mapping `.xlsx`, the README `.md`, the DAT `.docx`, and the frameworks `.drawio`.
11. Validate geometry (containment, no overlapping nodes, no overlapping edges, no orphaned edges) before delivering.
12. **The DAT is a SINGLE `.docx`** that MUST follow the **official Stellantis DAT template**
    (Context; Target Architecture with Applicative/Data/Technical Architecture, Flows Matrix,
    Continuous Integration, Platform Maintenance, Security, Supervision, Backup, FinOps,
    Appendices) - see the mandatory outline in `references/dat-document.md`. Keep the template's
    headings even when a section is light (mark "Not applicable"/"TBC" rather than dropping it).
    Write it in **English**, like all deliverables. The generator is self-contained (no external
    template file needed). Always run `assets/scripts/validate-dat.ps1` on it before delivery.
13. **All deliverables are in English.** Ask the user clarifying questions when details are
    missing (see `references/questionnaire.md`); never invent services, flows, ports or sizing.
14. **Always produce the Frameworks diagram** (`<project>_technical_architecture_frameworks.drawio`,
    its own Versions page first): the technical stack (products/frameworks/runtime/OS with
    **versions**) as a layered "building blocks" view, starting from
    `assets/templates/FMK_Diagram_template.drawio`. The stack MUST be identical across the
    Frameworks diagram, the DAT section 2.1.2 (technical stack table) and the gates Deck slides
    30/44 (and 43 if containerized). Never invent a version: an undecided version becomes `XX*` /
    `TBC` plus a README Missing-information entry. Keep every stack layer heading even when it is
    "Not applicable" (e.g. Spring/Java layers for a front-only widget) — see
    `references/frameworks-diagram.md`.

## Quick workflow
1. Ask the clarifying questions — see `references/questionnaire.md`.
2. Select applicable pattern(s) — see `references/patterns.md`.
3. Choose Strategy A or B and select components — see `references/generation-process.md`.
4. Build/modify the architecture diagram following style + encoding conventions.
5. Build the **separate Data Flow Diagram** file (Versions page + Data Flow page: inter/intra flows, C1/C2/C3/C4 confidentiality, DCP flag, TLS/mTLS transport, legend) — see `references/data-flow-diagram.md`.
6. Validate layout/geometry of BOTH `.drawio` files — see `references/layout-validation.md`.
7. Write the Versions page and save both `.drawio` files to `output/${project_name}/` — see `references/output-format.md` and `output-convention.md`.
8. Build the **Data Flow Mapping** `.xlsx`: assemble the JSON model, run `assets/scripts/build-flowmapping.ps1`, then validate with `assets/scripts/validate-flowmapping.ps1` — see `references/data-flow-mapping.md`.
9. Write the technical README `.md` to `output/${project_name}/` (with the Data Flow table) — see `references/readme-template.md`.
10. Build the DAT: assemble the JSON model, run `assets/scripts/build-dat.ps1`, then validate with
    `assets/scripts/validate-dat.ps1` — see `references/dat-document.md`. Fill section 2.1.2 with the
    technical stack table (same versions as the Frameworks diagram).
11. Build the **Frameworks diagram** `.drawio`: copy `assets/templates/FMK_Diagram_template.drawio`,
    tailor each stack layer to the app's real products/frameworks/versions (mark non-applicable
    layers "Not applicable", undecided versions `XX*`/`TBC`), add its Versions page, validate
    geometry, and save to `output/${project_name}/`. Keep it consistent with DAT 2.1.2 and Deck slides
    30/44/43 — see `references/frameworks-diagram.md`.
