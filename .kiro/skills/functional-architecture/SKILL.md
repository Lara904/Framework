---
name: functional-architecture
description: Generate a FUNCTIONAL architecture diagram (draw.io, with a Versions page) showing the companies involved (ICT for brand websites/IT, SFS for the bank's applications/IT), the applications of each company, the interactions between applications, and the main users. Also writes a functional architecture README and a complete Functional Architecture Dossier (FAD) in Word (.docx) following the official Stellantis template DP-MD76-EN. Asks the user clarifying questions and identifies the inputs it needs (backlog, statement of needs, user journey/flow, business processes, impacted applications, data). Self-contained - the template and the OPC-safe .docx generator are bundled. For the TECHNICAL/AWS view use the technical-architecture skill instead.
keywords:
  - functional architecture
  - functional diagram
  - drawio
  - companies
  - ICT
  - SFS
  - applications
  - interactions
  - users
  - business flow
  - dependencies
  - overview diagram
  - functional architecture dossier
  - FAD
  - DP-MD76-EN
  - urbanisation
  - master plan
  - backlog
  - user journey
  - user flow
  - business process
  - statement of needs
---

# Functional Architecture Diagram

This skill produces a **functional** architecture diagram in draw.io (`.drawio`) format that
shows the business/application landscape of a solution, NOT the technical/infrastructure view.
It answers: which companies are involved, which applications each owns, how those applications
interact, and who the main users are.

Like the technical skill, it also writes a **functional README** (`.md`) next to the diagram, and
it generates a **complete single-file Functional Architecture Dossier (FAD)** in Word (`.docx`)
following the official Stellantis template **DP-MD76-EN**. The FAD generator is self-contained (no
external template or example file required at runtime).

It is the right skill for the SIBS Architecture Gates deck slides "Functional Architecture -
dependencies macro view" (pos 16) and the "Architecture Overview Diagram" (pos 11). For the
technical view (VPCs, subnets, AWS services) use **technical-architecture**.

## What the diagram must contain
1. **Companies** (swimlanes / container boxes), chosen per case:
   - **ICT** - the brands' websites and IT (e.g. brand marketing sites, host web pages).
   - **SFS** - the bank's applications and IT (e.g. financing, CRM, lead management).
   - Add other parties only if the user confirms them (e.g. an external partner, a JV).
2. **Applications** of each company, drawn inside that company's container.
3. **Interactions** between applications: directed arrows with a short label describing the
   exchange (what flows, e.g. "lead data", "product catalogue", "eligibility result").
4. **Main users**: actor shapes connected to the applications they use (e.g. end customer,
   sales agent, marketing).

## Bundled assets (inside this skill)
- `assets/templates/`:
  - `Functional_Architecture_Dossier_template.docx` — the official Stellantis DP-MD76-EN template.
    **Runtime asset**: the FAD generator clones it (styles, theme, Stellantis-logo header, footers,
    numbering) and injects the body, so the output looks like the real template. Read-only - never
    modify it.
  - `Functional_Architecture_Dossier_template.model.json` — an editable starting model whose
    `body` reproduces the DP-MD76-EN outline; copy it to start a new FAD.
- `assets/scripts/` — self-contained PowerShell generator for the FAD `.docx` (no Python / Office):
  `FadDocx.psm1` (module), `build-fad.ps1` (wrapper), `validate-fad.ps1` (OPC validator).
  See `assets/scripts/README.md`.

## Three deliverables (always produce all three)
All three are written to the per-project output folder `output/${project_name}/` (create it if
missing) - see the `output-convention.md` steering (single source of truth for output location).
All three share the naming convention `${project_name}_functional_architecture_<kind>`:
1. `<project>_functional_architecture_diagram.drawio` - the diagram, with a **Versions** page first.
2. `<project>_functional_architecture_README.md` - the functional architecture README
   (companies, applications, interactions, users, assumptions, a consolidated **Missing
   information (to be provided)** table gathering every `TODO`/"to confirm", and open questions).
3. `<project>_functional_architecture_document.docx` - the Functional Architecture Dossier (FAD):
   a single Word document following the official Stellantis **DP-MD76-EN** template (scope of the
   transformation project, scope of the functional architecture / master plan, IT urbanisation
   appendix) — see `references/fad-document.md`. Its editable model
   `<project>_functional_architecture_document.model.json` may be kept next to it.

All deliverables are written in **English**.

## Ask before generating (clarifying questions & inputs)
This skill is interactive. Before generating, ask the user the questions in
`references/questionnaire.md`:
- For the **diagram + README**: companies in scope, applications per company, interactions,
  users, hosting boundary (sections 1-6).
- For the **FAD** (`.docx`): the business/urbanisation inputs (sections 7-9) - project
  positioning, **backlog / statement of needs**, **user journey / user flow / business
  processes**, impacted applications (ideally from ARIS) and their state, reference/enterprise
  data used, impacted BIS and functional architects, the target master plan, and any new
  application description. Each input maps to a FAD section - see `references/fad-document.md`.

Ask only what you genuinely need; if the solution is already described, confirm the key inferred
choices in one short round rather than interrogating section by section. Do not invent
applications, company names, flows, BIS, architects or data - if a detail is unknown, mark it as
an assumption in the README, a `TODO` note on the diagram / a "TBC" in the FAD, and an entry in
the README **Missing information (to be provided)** table (with what it unblocks and who owns it -
use the fixed role vocabulary and `- **Ask:** <Role>` tag from
`.kiro/steering/open-questions-convention.md` so `open-questions-consolidation` can route it),
then ask the user. That table is the single consolidated list of every `TODO`/"to confirm" / "TBC"
across the diagram, README and FAD; keep it in sync. See `references/readme-template.md`.

## Reference guides (load on demand)
Read the relevant reference file(s) in `references/` for the task at hand:
- `references/questionnaire.md` — clarifying questions and FAD inputs to gather before generating
- `references/companies.md` — the functional model (companies, applications, interactions, users)
- `references/generation-process.md` — how to build the `.drawio` (layout, styles, geometry, validation)
- `references/output-format.md` — the three deliverables, the Versions page, file output rules
- `references/readme-template.md` — the functional README template (companion to the diagram)
- `references/fad-document.md` — the FAD outline (DP-MD76-EN), the input-to-section mapping, and
  the JSON model schema for the `.docx` generator

## Core rules (always apply)
1. **Functional, not technical.** No VPCs, subnets, AWS services, ports or protocols. Describe
   business applications and what they exchange, in business terms.
2. **Company grouping is mandatory.** Every application belongs to exactly one company
   container (ICT or SFS, or another confirmed party). See `references/companies.md`.
3. **Interactions are directed and labelled.** Each arrow has a direction (who calls whom /
   who sends to whom) and a concise business label.
4. **Main users are shown** as actors linked to the applications they interact with.
5. **English only.** All labels and the README are in English (international audience).
6. **ASCII-safe, UTF-8 without BOM.** Avoid em dashes, curly quotes, bullets in cell values.
7. **Versions page first**, table format (Version / Date / Author / Description); append a new
   row per change, never rewrite history. See `references/output-format.md`.
8. **Never invent facts.** Unknowns become README assumptions + on-diagram TODO + a "TBC" in the
   FAD + a row in the README **Missing information (to be provided)** table, and questions back to
   the user.
9. **The FAD follows the official DP-MD76-EN template.** Reproduce its exact chapter/section
   structure and numbering (see `references/fad-document.md`); keep every heading even when a
   section is light (write "Not applicable"/"TBC" rather than dropping it). Build it with the
   self-contained generator `assets/scripts/build-fad.ps1` and validate it with
   `assets/scripts/validate-fad.ps1` (must exit 0) before delivery.
10. **Inter-deliverable consistency.** The diagram, the README and the FAD MUST agree - same
    companies, applications, interactions and users. The README application/interaction tables and
    the diagram feed FAD sections 1.3 (IT situation) and 2.2 (master plan).
11. **Output to `output/${project_name}/`** (see the `output-convention.md` steering): the
    `.drawio`, the README, and the FAD `.docx` (plus its optional `.model.json`). Create the
    folder if missing.
12. **No unresolved "fill this in" markers from the template itself.** The bundled FAD template's
    running header (`header1.xml`) carries a literal "Project name " label followed by a red
    Wingdings "fill here" glyph (`w:sym char="F03F"`), meant for someone completing the template
    by hand in Word. `FadDocx.psm1` resolves this automatically (using the model's `subtitle`,
    falling back to `title`) when it clones the template - found during an end-to-end pipeline
    verification pass (2026-10-29) where a generated FAD still showed this unfilled marker on
    every page but the cover. Do not "simplify" the generator back to copying `header1.xml`
    verbatim; that silently reintroduces this defect. If the template is ever replaced/updated,
    re-check whether it still carries this marker and keep this resolution logic in sync.

## Quick workflow
1. Ask the clarifying questions and gather the FAD inputs - see `references/questionnaire.md`.
2. Map the answers to companies -> applications -> interactions -> users - see
   `references/companies.md`.
3. Build the `.drawio` (Versions page + functional page) - see `references/generation-process.md`
   and `references/output-format.md`.
4. Validate geometry (containment, no overlapping nodes, no overlapping edges, no orphaned edges) - see `references/generation-process.md`.
5. Write the functional architecture README - see `references/readme-template.md`.
6. Build the FAD: assemble the JSON model following the DP-MD76-EN outline, then run
   `assets/scripts/build-fad.ps1` and `assets/scripts/validate-fad.ps1` **directly** (with `-File`
   and their `-Model`/`-Out`/`-Docx` arguments; do NOT wrap them in a `_run.ps1` helper - a wrapper
   re-importing the module by relative path can fail silently). Confirm validation prints
   `FAD VALIDATION OK` and exits 0 - see `references/fad-document.md`.
7. Save all files to `output/${project_name}/` (see `output-convention.md`) and list assumptions / missing information / open questions to the user.
