---
name: access-right-matrix
description: Fill the SFS/SIBS Access Right Matrix for CIQ, CI-CD and AWS Console (template SIBS_M2C_DIR_OPE_DEL_AWS_001, "right matrix model" v2.6) for an application. Copies the bundled reference template, solicits the missing application information from the user (PRD code, REFLEX names, DICT, functional description, profile scope), and produces the filled Excel (.xlsx) deliverable. A transient README tracks missing info and open questions and is deleted once complete. Self-contained - the reference template and generation/validation scripts are bundled with the skill. This matrix must be completed before any REUNIS access-service creation/modification.
keywords:
  - access right matrix
  - right matrix
  - rights matrix
  - matrice des droits
  - matrice de droits d'acces
  - access rights
  - droits d'acces
  - REUNIS
  - REFLEX
  - seculogiq
  - SECULOGIQ
  - CIQ
  - CI-CD
  - CICD
  - AWS Console
  - AWS NG
  - Landing Zone
  - LDAP
  - LDAPPING
  - access service
  - service d'acces
  - profile
  - profil
  - DEVOPS
  - RELEASE
  - ApplicationLead
  - PGA
  - ASL
  - PRD code
  - technical rights
  - business rights
  - SIBS_M2C_DIR_OPE_DEL_AWS_001
  - TCC
  - architecture gates
  - Stellantis
  - PSA
  - SFS
---

# Access Right Matrix (SFS/SIBS - CIQ, CI-CD and AWS Console)

This skill fills the official SFS/SIBS **Access Right Matrix** ("right matrix model for
CIQ, CI-CD and AWS Console", v2.6 March 2026, ref `SIBS_M2C_DIR_OPE_DEL_AWS_001`, C2 -
PSA Sensitive) for a given application, and produces the filled **Excel (.xlsx)**
deliverable. This matrix must be completed **before any request to create or modify an
access service in REUNIS**. It records, per application, all access rights, the user
types who may receive them, and how they are assigned.

The deliverable is produced by **copying the bundled reference template** and editing
only the target cells and placeholder tokens (`<PRD>` -> the app PRD code; the
`APPLICATION Information` cells; optional REFLEX application names). The 15 predefined
technical profiles, the business-profile skeleton, cell comments, hidden `Parameters`
drop-down lists, styles and drawing are preserved verbatim.

## When to use this skill
- Produce or update the Access Right Matrix deliverable for a gate (TCC / Architecture
  Gates) or before a REUNIS access-service request.
- Answer a question about a profile, an LDAP target, an access-service code, an
  incompatibility rule, or the DEV+OPS cumulative derogation.
- Fill / refresh the `APPLICATION Information` sheet or substitute the PRD code across
  the workbook.

## Bundled assets
- `assets/templates/SFS_right_matrix_for_ciq_and_CI_CD_AWS_NG_v2026_03.xlsx` - the
  authoritative reference template (READ-ONLY source of truth). Its full structure is
  reproduced in `references/template-structure.md`.
- `assets/scripts/RightMatrixXlsx.psm1` - OPC-safe fill module (copy template + edit
  cells/tokens in place; re-zip with `Create`, never `Update`).
- `assets/scripts/build-rightmatrix.ps1` - wrapper: JSON model -> filled `.xlsx`.
- `assets/scripts/validate-rightmatrix.ps1` - OPC/XML validator + placeholder report.

## Deliverables (always produce)
Written to the per-project output folder `output/${project_name}/` (create it if missing) - see the
`output-convention.md` steering (single source of truth for output location).
1. `${project_name}_access_right_matrix.xlsx` - the filled matrix. **This is the only
   deliverable.**
2. `${project_name}_access_right_matrix.model.json` - the JSON model driving the fill
   (intermediate input; keep it beside the `.xlsx` for regeneration/versioning).
3. `${project_name}_access_right_matrix_README.md` - **transient** working notes: missing
   information + open questions (see `references/readme-template.md`). **Delete it once
   all information is collected and the `.xlsx` is complete.**

## Ask before generating
Scope the requirements interactively with `references/questionnaire.md`. Ask ONLY what
is not already known from the workspace (DICT README, architecture READMEs, existing
REFLEX/PRD references). Anything still unknown becomes a visible placeholder in the
`.xlsx` and an Open question in the transient README - never invent a value.

## Reference guides (load on demand)
- `references/questionnaire.md` - requirements questionnaire (identity, REFLEX names,
  profile scope, governance).
- `references/template-structure.md` - the 6 sheets, the 15 technical profiles with
  their LDAP targets, the business skeleton, and every placeholder (provenance).
- `references/model-schema.md` - the JSON model fields and how each maps to a cell/token.
- `references/readme-template.md` - the transient companion README structure + when to
  delete it.
- `assets/scripts/README.md` - how to run the build and validate scripts.

## Core rules (always apply)
1. **The bundled template is the authority and is READ-ONLY.** Always work on a copy
   saved under the deliverable name; never write to, rename or overwrite the template.
2. **Never add, modify or remove a profile, column, comment or drop-down list.** The 15
   technical profiles and the 19 business columns are the fixed SFS catalogue. Profile
   applicability / scoping is documented in the README, not by deleting columns.
3. **Never invent a value.** PRD code, REFLEX names, DICT, description come from the
   user / MOA / the DICT deliverable. Any unknown stays as its template placeholder
   (`<PRD>`, `<REFLEX_NAME ...>`) and is listed as an Open question in the README.
3b. **The "Matrix of BUSINESS rights" decision is mandatory and lives in the `.xlsx`,
   not only the README.** Set the model's `businessProfiles` field to `"none"` or
   `"defined"` (never skip this) - `build-rightmatrix.ps1` throws rather than produce a
   file with that sheet silently left at its blank template state ("Profile 1".."Profile
   19" with nothing under them). A past real deliverable shipped exactly that blank
   sheet; `validate-rightmatrix.ps1` now FAILS (not warns) if it detects this state, so
   never deliver a matrix that fails validation here.
4. **The PRD code substitutes `<PRD>` everywhere** (access-service codes, LDAP targets,
   CIQ env codes, GitHub rows). Keep `prdCode` and the `PRD Code` cell (`prdCodeField`)
   in sync.
5. **Reuse the project DICT.** The `dict` value must match the `*_DICT_README.md`
   deliverable; do not re-rate it here.
6. **Coherence inter-livrables.** REFLEX/PRD names, DICT and environment scope must
   agree with the technical and functional architecture deliverables and the DICT
   README.
7. **Keep the output a valid `.xlsx`.** Re-zip with `Create` (never `Update`); write
   modified parts UTF-8 without BOM; XML-escape injected text. The validator MUST exit 0
   before delivery.
8. **The `.xlsx` is the only deliverable; the README is transient.** Delete the
   `*_access_right_matrix_README.md` once all info is collected and the `.xlsx` is
   complete. Presentations and checklists reference the `.xlsx`, never the README.

## Quick workflow
1. Gather context from the workspace (DICT, architecture READMEs, existing REFLEX/PRD).
2. Ask the remaining questions from `references/questionnaire.md`. Create the transient
   `${project_name}_access_right_matrix_README.md` capturing collected info + open
   questions.
3. Write `${project_name}_access_right_matrix.model.json` (see `references/model-schema.md`),
   leaving unknown fields empty.
4. Generate with `assets/scripts/build-rightmatrix.ps1` (copies the template, fills
   cells C3..C7, substitutes `<PRD>` and optional REFLEX names).
5. Validate with `assets/scripts/validate-rightmatrix.ps1` (must exit 0; review the
   placeholder report for remaining `<PRD>` / REFLEX placeholders).
6. Iterate with the user on the open questions; regenerate as answers arrive.
7. When no required placeholder remains and the README open-questions list is empty,
   **delete the transient README**. The `.xlsx` (+ its `.model.json`) is the deliverable.
