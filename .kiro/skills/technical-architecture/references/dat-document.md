# DAT - Technical Architecture Document (single Word .docx)

This skill produces a **complete Technical Architecture Document (DAT)** as a **single** Word
`.docx` file, in addition to the `.drawio` diagram and the technical README.

The DAT MUST follow the **official Stellantis DAT template**. That template's structure was
derived from the official example `BPF B2C CS DAT V0.8` and is **fully reproduced in the mandatory
outline below** - so the skill is self-contained: the example file is provenance only and is NOT
required as an input to generate a DAT. The structure is a `Context` chapter, then a `Target
Architecture` chapter that contains Applicative Architecture, Data Architecture, Technical
Architecture, Flows Matrix, Continuous Integration, Platform Maintenance, Security, Supervision,
Backup/Restoration, FinOps and Appendices. The full outline below MUST be respected (omit only a
sub-section that genuinely does not apply, and replace it with a short "Not applicable / TBC" note
rather than dropping the heading silently).

> The DAT we generate is **ONE file** (`.docx`). Do not produce two separate documents. The skill
> is self-contained: the generator needs no external template file, but the **section structure
> below is mandatory** and mirrors the official Stellantis DAT template.

The bundled anonymized template `assets/templates/DAT_template.docx` (with its editable
`assets/templates/DAT_template.model.json`) reproduces this structure end to end (cover, TOC,
front-matter tables, numbered body). Other-project business content is removed and replaced by
placeholders; the reference reviewer names (PII) are kept as an example of the Approval table. It
is provenance/reference only - the generator does not read it; copy the `.model.json` as a
starting point for a new DAT if useful.

## Document furniture (mirrors the official template)
The generator reproduces the front-of-document structure of the reference example so the DAT
looks like the official Stellantis template, not a bare heading list:
- **Cover page** - the title is **"Technical Architecture File"** (the reference wording; keep it),
  the `subtitle` (application / project name), the `version`, the author and the date, then a page break.
- **Table of Contents** - a real Word `TOC \o "1-4"` field. `settings.xml` sets `updateFields=true`
  so Word offers to build it (with page numbers) on first open; the user clicks "Yes" / "Update Field".
- **Front-matter tables** - Distribution List, Approval of the version, Referenced documents, and
  Document evolution (see the model fields below), then a page break.
- **Numbered body** - Heading 1-4 carry automatic multi-level numbering (1, 1.1, 1.1.1, 1.1.1.1)
  via `numbering.xml`, exactly like the reference DAT.

## How it is generated (no Python / Office on this machine)
Use the bundled PowerShell generator (see `assets/scripts/README.md`):
1. Build a JSON **model** describing the DAT (title, cover/front-matter fields, and an ordered `body`).
2. `build-dat.ps1 -Model <model.json> -Out "<project>_technical_architecture_document.docx"` writes a valid `.docx`.
3. `validate-dat.ps1 -Docx "<project>_technical_architecture_document.docx"` must exit 0 (OPC opens, XML well-formed).

The generator writes valid Open XML parts (document, styles, numbering, settings, rels, docProps)
and zips them OPC-safely (`ZipArchiveMode.Create`, UTF-8 without BOM). Word opens the result without
"repair".

## Language & encoding
- The DAT is written in **English**, like all the other deliverables (diagram, README).
- The `.docx` is written as UTF-8 without BOM. Plain ASCII is preferred; any accented characters
  are still handled correctly (proper UTF-8), but English text should rarely need them.

## Mandatory DAT outline (official Stellantis template)
Reproduce this exact chapter/section structure and numbering (h1 = chapter, h2/h3/h4 =
sub-sections). Keep the headings even when a section is light; if a section does not apply, put a
one-line "Not applicable" / "TBC" note under it (mirroring the diagram `C?` markers and the README
open questions) rather than removing the heading. A front-only app (no backend/compute) legitimately
marks server/compute/backup sub-sections as "Not applicable" but keeps the headings.

**1. Context** (h1)
- 1.1 Purpose of the document (h2)
- 1.2 Presentation and scope of the project (h2) - include the referenced documents & diagrams
  table (architecture `.drawio`, dataflow `.drawio`, README, Data flow mapping, SIBS M2C pattern).
- 1.3 Requirements (h2)
  - 1.3.1 Functional requirements (h3)
  - 1.3.2 Technical requirements (h3): Synthesis (h4), Volumetry (h4), Security (h4), Compatibility (h4)

**2. Target Architecture** (h1)
- 2.1 Applicative Architecture (h2)
  - 2.1.1 Overview (h3)
  - 2.1.2 Applicative components (h3) - one h4 per component/microservice (or a single h4 for a
    front-only widget). **This section also carries the Technical stack table**: the
    products/frameworks/runtime/OS **with versions** (front-end, back-end, runtime, data,
    security, quality/testing, container base image), rendered as a table Layer / Product-Framework
    / Version / Notes. It is the tabular twin of the separate **Frameworks diagram**
    (`<project>_technical_architecture_frameworks.drawio`, see `frameworks-diagram.md`) and of the
    gates Deck slides 30/44 (and 43 if containerized) - all three MUST list the same products and
    versions. Undecided versions are `XX*` / `TBC` and land in the README Missing-information
    table. Reference the Frameworks diagram here.
  - 2.1.3 External systems integration (h3) - one h4 per external system (Ping Federate, APIC,
    host site, ...); "None at MVP" if truly none
- 2.2 Data Architecture (h2)
  - 2.2.1 Overview (h3)
  - 2.2.2 Data Sources (h3)
  - 2.2.3 Enterprise API Management (h3)
  - 2.2.4 Data Storage Layer (h3)
  - 2.2.5 Data Processing Layer (h3)
  - 2.2.6 Platform Private API (h3)
  - 2.2.7 Data Visualization Layer (h3)
  - 2.2.8 Data Security Layer (h3) - encryption at rest/in transit, personal-data (DCP) handling,
    reference the data flow diagram + Data flow mapping
  - 2.2.9 Data Monitoring Layer (h3)
- 2.3 Technical Architecture (h2)
  - 2.3.1 Overview (h3) - reference the technical `.drawio`, the SIBS M2C pattern(s)
  - 2.3.2 Infrastructure services (h3): AWS Services (h4, table Service / Account-Region / Role),
    AWS services & resources provided by the Landing Zone / Cloud Management (h4), deployment
    pattern (h4), any processing specifics (h4). Recommended server resources go here as a table
    Component / Description / Resources - mark "Not applicable" for a front-only app.
    (The **Technical stack** table lives in section **2.1.2 Applicative components**, not here.)
- 2.4 Flows Matrix (h2) - the **detailed flow matrix** (table Source / Destination / Protocol /
  Port / Criticality / DCP / Description). **Criticality** = official Stellantis C1/C2/C3/C4 (C? if
  unconfirmed); **DCP** = personal-data flag (Yes/No). This matrix is the tabular twin of the
  separate Data Flow Diagram (`<project>_technical_architecture_dataflow.drawio`, see
  `data-flow-diagram.md`) and the synthetic extract of the Stellantis **Data flow mapping**
  (ARIS/CMDB/GDPR) - all three MUST carry the same flows, C1-C4 values and DCP flags. Reference
  both the Data flow mapping and the DFD here.
- 2.5 Continuous Integration (h2)
  - 2.5.1 Environments (h3)
  - 2.5.2 DevOps tools (h3) - **external Stellantis stack** (GitHub + TeamCity + Artifactory +
    Terraform), NEVER AWS CodePipeline/CodeBuild/CodeCommit/CodeDeploy
  - 2.5.3 Deployment process (h3)
  - 2.5.4 Release Management (h3): Git Flow (h4), Release Name (h4), Release Deployment (h4)
- 2.6 Platform Maintenance (h2): Release update (h3), Security Patch & Vulnerability Detection (h3)
- 2.7 Security (h2): Roles and Access (h3), Access restriction (h3), Domain Name (h3), Data
  Anonymization and Resources Security (h3), Antivirus Detection (h3)
- 2.8 Supervision (h2): Health Check (h3), Logs monitoring (h3)
- 2.9 Backup / Restoration management (h2): Backup policy & Restoration process (h3) - "Not
  applicable" for a stateless front-only app, but keep the heading
- 2.10 FinOps (h2)
- 2.11 Appendices (h2): Glossary (h3), Acronyms (h3)

## JSON model schema
```json
{
  "title": "Technical Architecture File",
  "subtitle": "<App / project name>",
  "version": "1.0",
  "author": "<name>",
  "date": "YYYY-MM-DD",
  "distributionList": [
    { "recipient": "Technical Architects", "entity": "SFS" }
  ],
  "approval": [
    { "role": "Editor", "function": "Solution Architect", "name": "<name>", "entity": "<company>" },
    { "role": "Validator", "function": "Technical Architect", "name": "<name>", "entity": "SFS" }
  ],
  "referencedDocuments": [
    { "n": "[1]", "title": "Technical architecture diagram", "reference": "<project>_technical_architecture_diagram.drawio" }
  ],
  "documentEvolution": [
    { "date": "YYYY-MM-DD", "version": "1.0", "chapter": "All", "changes": "Initial creation of the DAT", "editors": "<name>" }
  ],
  "body": [
    { "type": "h1", "text": "Context" },
    { "type": "h2", "text": "Purpose of the document" },
    { "type": "p",  "text": "This document describes the technical architecture of ..." },
    { "type": "h2", "text": "Presentation and scope of the project" },
    { "type": "table", "header": ["Ref", "Document"], "rows": [
      ["[1]", "Technical architecture diagram - <project>_technical_architecture_diagram.drawio"],
      ["[2]", "Data flow diagram - <project>_technical_architecture_dataflow.drawio"],
      ["[3]", "Data flow mapping (ARIS/CMDB/GDPR)"]
    ] },
    { "type": "h2", "text": "Requirements" },
    { "type": "h3", "text": "Functional requirements" },
    { "type": "h3", "text": "Technical requirements" },
    { "type": "h4", "text": "Synthesis" },
    { "type": "h4", "text": "Volumetry" },
    { "type": "h4", "text": "Security" },
    { "type": "h4", "text": "Compatibility" },

    { "type": "h1", "text": "Target Architecture" },
    { "type": "h2", "text": "Applicative Architecture" },
    { "type": "h3", "text": "Overview" },
    { "type": "h3", "text": "Applicative components" },
    { "type": "p", "text": "Technical stack (products/frameworks/runtime/OS with versions) - tabular twin of the Frameworks diagram and gates Deck slide 30:" },
    { "type": "table", "header": ["Layer", "Product / Framework", "Version", "Notes"], "rows": [
      ["Front End", "Angular", "21 LTS", "i18n via ngx-translate; angular-material; luxon; TypeScript"],
      ["Runtime", "OpenJDK - Corretto", "21", "Back-end runtime (Not applicable for a front-only widget)"],
      ["Quality", "SonarQube / Checkmarx", "XX*", "Version to confirm at Gate 3"]
    ] },
    { "type": "h3", "text": "External systems integration" },
    { "type": "h2", "text": "Data Architecture" },
    { "type": "h3", "text": "Overview" },
    { "type": "h3", "text": "Data Sources" },
    { "type": "h3", "text": "Data Security Layer" },
    { "type": "h2", "text": "Technical Architecture" },
    { "type": "h3", "text": "Overview" },
    { "type": "h3", "text": "Infrastructure services" },
    { "type": "h4", "text": "AWS Services" },
    { "type": "table", "header": ["Service", "Account / Region", "Role"], "rows": [
      ["CloudFront", "Application Account / Global", "CDN distributing the bundle"]
    ] },
    { "type": "h2", "text": "Flows Matrix" },
    { "type": "table",
      "header": ["Source", "Destination", "Protocol", "Port", "Criticality", "DCP", "Description"],
      "rows": [
        ["CloudFront", "Widget component", "HTTPS", "443", "C1", "No", "Widget bundle delivered via the CDN (pulled by the browser)"],
        ["End user (browser)", "Widget component", "in-browser", "-", "C3", "Yes", "Personal/financial inputs stay local to the browser"]
      ] },
    { "type": "h2", "text": "Continuous Integration" },
    { "type": "h3", "text": "Environments" },
    { "type": "h3", "text": "DevOps tools" },
    { "type": "h3", "text": "Deployment process" },
    { "type": "h3", "text": "Release Management" },
    { "type": "h2", "text": "Platform Maintenance" },
    { "type": "h2", "text": "Security" },
    { "type": "h2", "text": "Supervision" },
    { "type": "h2", "text": "Backup / Restoration management" },
    { "type": "h2", "text": "FinOps" },
    { "type": "h2", "text": "Appendices" },
    { "type": "h3", "text": "Glossary" },
    { "type": "h3", "text": "Acronyms" }
  ]
}
```

### body node types
| type | fields | renders as |
|------|--------|-----------|
| `h1` | `text` | Heading 1 (numbered outline level) |
| `h2` | `text` | Heading 2 |
| `h3` | `text` | Heading 3 |
| `h4` | `text` | Heading 4 |
| `p` | `text` | normal paragraph |
| `bullets` | `items` (string[]) | bulleted list |
| `table` | `header` (string[]), `rows` (string[][]) | bordered table, shaded header row |
| `pagebreak` | - | page break |

### Front-matter fields
| field | shape | renders as |
|-------|-------|-----------|
| `title` | string | cover title - keep **"Technical Architecture File"** (reference wording) |
| `subtitle` | string | cover subtitle (application / project name) |
| `version` | string | cover "Version x.y" line |
| `author`, `date` | string | cover author / date line + docProps |
| `distributionList` | `[{recipient, entity}]` | "Distribution List" table |
| `approval` | `[{role, function, name, entity}]` | "Approval of the version" table |
| `referencedDocuments` | `[{n, title, reference}]` | "Referenced documents" table |
| `documentEvolution` | `[{date, version, chapter, changes, editors}]` | "Document evolution" table |

`documentEvolution` is preferred; if only the legacy `revisions` (`[{date, revision, object,
author}]`) is present it is still rendered as the Document evolution table (chapter defaults to
"All"). Unknown people/entities become "TBC" rather than invented names.

### Rules
- `title`, `author`, `date` are mandatory. The front-matter fields (`subtitle`, `version`,
  `distributionList`, `approval`, `referencedDocuments`, `documentEvolution`) are optional but
  recommended so the DAT matches the official template; a missing section is simply skipped.
- Keep tables rectangular: every row has the same number of cells as the header.
- Escaping is automatic (`&`, `<`, `>`, quotes) - put raw text in the model.
- Save the model file as UTF-8. Write the content in English.

## Output
- File name: `${project_name}_technical_architecture_document.docx` in **`output/${project_name}/`**
  (see the `output-convention.md` steering), next to the `.drawio` files and the README.
- One file only. Always validate with `validate-dat.ps1` before delivery.
- The intermediate `<project_name>_technical_architecture_document.model.json` may be kept next to
  the docx (useful to regenerate / version the DAT) or removed; if kept, it is the source of truth
  for the next revision.
