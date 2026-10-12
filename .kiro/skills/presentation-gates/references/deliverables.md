# Required Annex Deliverables (per gate)

The gates require documents/artefacts IN ADDITION to filling the slides - the template's
"Link to ..." fields point to these. The missing-data checklist tracks them in a dedicated
**"Required annex deliverables"** section, with a persisted status per item.

## Catalogue (single source of truth)
Defined in `PptxGates.psm1` as `$script:Deliverables` (function `Get-Deliverables`). Each entry:
- `Id`, `Name`, `Gate` - identity and which gate(s) require it.
- `SlideRole` - a case-insensitive **title/role marker** searched in the TITLE zone of the ACTUAL
  deck to resolve the real display position. This is what makes the checklist robust to decks
  that add or reorder slides versus the standard V5.2 count (the carrier deck below is 80 slides,
  not 75). `Resolve-DeliverableSlide` matches this marker in each slide's leading ~140 chars, so a
  short word that also appears in the table of contents or a synthesis slide does not cause a
  false positive.
- `SlideHint` - the V5.2 standard position, used **only** as a fallback when `SlideRole` is not
  found, and as documentation. It never drives the real position when the role resolves.
- `LinkFile` - the generated deliverable's filename. When that string is present on the resolved
  slide, the link is considered posted and the deliverable's default status becomes `Provided`.

The real position is therefore **resolved at scan time against the deck**, not read from a fixed
number. The `_(slide N)_` label in the generated checklist shows that resolved position (with a
trailing `?` when only the `SlideHint` fallback was used).

| Deliverable | Gate | SlideRole (title marker) | SlideHint (V5.2) | LinkFile |
|-------------|------|--------------------------|------------------|----------|
| DigitalMe Demand (ID + link) | G1 | `Architecture One Pager` | 9 | _(link / ID, no file)_ |
| As-Is / To-Be Overview diagram | G1 | `Architecture OVERVIEW DIAGRAM` | 10 | _(diagram on slide)_ |
| Data Privacy self-assessment (GDPR) | G1, G2 | `Data Privacy` | 13 | _(xlsx)_ |
| Functional Architecture document | G2 | `Functional Architecture document` | 17 | `_functional_architecture_document.docx` |
| Non-Functional Requirements (NFR) document | G2 | `Non-Functional Requirements` | 18 | `_NFR.xlsm` |
| Enterprise data model / Application flow | G2 | `Enterprise Architecture - DEPENDENCIES` | 19 | _(diagram)_ |
| Risk analysis | G2 | `RISKs` | 23 | _(docx)_ |
| Cost estimate (AWS Calculator + K amounts) | G2 | `Costs (for Gate` | 24 | _(xlsx)_ |
| Timeline / macro planning | G2 | `Timeline` | 26 | _(xlsx)_ |
| Cloud eligibility tree | G2 | `PRESENTATION OF THE CLOUD PROJECT` | 28 | _(diagram)_ |
| Technical Architecture document (DAT) + diagram | G2 | `Technical Architecture global view` | 42 | `_technical_architecture_document.docx` |
| Functional & Technical flow mapping | G2 | `Data-flow` | 73 | `_technical_architecture_dataflow_mapping.xlsx` |
| Access rights matrix | G2 | `ACCESS RIGHTS` | 55 | `_access_right_matrix.xlsx` |
| Threat modeling report | G2 | `Threat modeling` | 63 | `_threat_modeling.xlsx` |

Keep this table in sync with `$script:Deliverables` in the module - the module is the source of
truth, this table documents it. Add/remove entries **there** (not just here) so every script
stays consistent, and keep `SlideRole`/`SlideHint`/`LinkFile` identical between the two.

## Deliverable format conventions
Match the file format to what the "Link to ..." field expects (this mirrors rule 8b in SKILL.md):

- **Diagram / schema / map** (architecture overview, application flows, data flow, technical
  architecture view, cloud eligibility tree, enterprise/functional flow mapping) -> author it as a
  **`.drawio`** file. Export a `.png`/`.svg` for the picture embedded on the slide, but the
  referenced deliverable is the editable `.drawio` (produced with the
  `functional-architecture` / `technical-architecture` skills).
- **Document / analysis / write-up** (functional or technical architecture document/DAT, risk
  analysis, security note, exit plan) -> a **`.docx`**.
- **Spreadsheet / matrix / structured data** (NFR, cost/AWS estimate, access-rights matrix, GDPR
  self-assessment, environments/accounts list) -> an **`.xlsx`**, or **`.xlsm`** when it carries
  macros. **NFR (slide 17)**: always the Excel workbook (`.xlsm`/`.xlsx`, e.g.
  `<Project>_NFR.xlsm`) - never a `.tsv`/`.csv` working export.
- **Slide deck** deliverable -> a **`.pptx`**.
- **External record / portal item** (e.g. DigitalMe Demand) -> a **link/ID**, not a file.

In every case reference the official file by name/link on the slide - never paste its content
into the slide, and never point to an intermediate/working export.

## How status is tracked (persisted)
- `find-missing.ps1` renders a `## Required annex deliverables` section listing the deliverables
  for the scanned gate(s), each as:
  `- [ ] <Name> (<gates>) - status: <status>  _(slide <n>)_`
- Status is **persisted**: on each run the script reads the previous status/checkbox from the
  EXISTING checklist file and carries it over, so a value the user set by hand always wins and is
  never downgraded by a regeneration (including the `agentStop` hook).
- For a NEW deliverable (no persisted status yet) the default is derived from the deck: if the
  deliverable's `LinkFile` string is found on its resolved slide, the link is posted and the
  default becomes `Provided`; otherwise it defaults to `Not started`. Deliverables with no
  `LinkFile` (a link/ID or an on-slide diagram) always default to `Not started` and are confirmed
  by the user.
- The user updates the status text (e.g. `Not started` -> `In progress` -> `Provided`) and ticks
  the box `[x]` when done. Those edits survive every regeneration, including the `agentStop` hook.
- The footer shows `Open slide items: <n> | Open deliverables: <m>`.

## Rules for the agent
- When filling a slide that references a deliverable, remind the user of the linked deliverable
  and, if they confirm it is provided/linked, update that deliverable's status line accordingly.
- Never mark a deliverable `Provided` on your own unless the user confirms it exists (or you have
  produced/linked it in the project). Otherwise leave it as the user set it.
- Non-applicable deliverables: set status to `N/A` and tick the box (counts as resolved).
