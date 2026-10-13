---
name: nfr-requirements
description: Assess the Stellantis (ex-PSA) Non-Functional Requirements repository DP-MD18-EN (ISO 25010) for an application - answer questions about any NFR (meaning, triggers, dispensation, roles, status), decide relevance and status per NFR from the system context (DICT, RTO, SOX, data privacy), and generate a filled Excel (.xlsm) deliverable by copying the bundled reference model. Self-contained - the reference model and a distilled catalog of all NFRs are bundled with the skill.
keywords:
  - NFR
  - NFRs
  - non-functional requirements
  - non functional requirement
  - DP-MD18-EN
  - DP-MD18
  - ISO 25010
  - exigences non fonctionnelles
  - requirements repository
  - relevant
  - dispensation
  - dispense
  - status
  - proposed
  - accepted
  - implemented
  - verified
  - not feasible
  - reliability
  - security requirement
  - maintainability
  - portability
  - performance efficiency
  - compatibility
  - usability
  - functional suitability
  - DICT
  - RTO
  - SOX
  - data privacy
  - TCC
  - architecture gates
  - Stellantis
  - PSA
---

# NFR Requirements Assessment (Stellantis DP-MD18-EN)

This skill assesses the **Non-Functional Requirements** of the Stellantis (ex-PSA) reference
repository **`DP-MD18-EN`** (classified per ISO 25010) for a given application. It does three
things:
1. **Answers questions** about any NFR - meaning, context triggers, dispensation rule, roles,
   deliverables, expected status.
2. **Decides relevance and status** per NFR from the application's system context
   (DICT / RTO / SOX / data privacy + functional/technical nature), with a justification.
3. **Generates the Excel deliverable** (`.xlsm`) by copying the bundled reference model, writing
   the system parameters, and applying the per-NFR decisions.

The repository is a **fixed list** of NFRs: you never add, modify or remove one. **Relevant**
(Yes/No) is COMPUTED by the model's filter from the system context (DICT/RTO/SOX/DP) - never
hand-set. The project only sets **Status** (Proposed -> Accepted -> Implemented -> Verified,
plus Not relevant / Not feasible) and a justification in **Comments / Valorization**.

## Self-contained
The skill bundles everything it needs - no external file is required:
- `assets/templates/DP-MD18-EN_Non-Functional_Requirements.xlsm` - the authoritative reference
  model (source of truth: sheet "NFR repository" for the requirements, "Synthesis" for the
  system parameters and status charts, "Params" for the valid values).
- `references/nfr-catalog.md` - all 133 NFRs (incl. lettered sub-variants) distilled to text
  (reference, title, detail, dispensation, context triggers) for fast relevance decisions.
- `references/nfr-cards/NFR-XXXX.md` - 108 detailed cards, one per NFR base id: goal, why it
  matters, technical constraints, applicability checklist, full governance data (BUILD/RUN roles,
  milestones, triggers), and the official DocInfo link. Open these to answer detailed questions.
- `references/nfr-index-bilingual.md` - EN/FR title index (code -> title) for quick lookup.
- `references/dict-filter-reference.md` - the DICT 1..4 level scales and how each filter column
  (D/I/C/T, RTO, Data privacy, SOX) triggers an NFR - to explain the macro's decisions.
- `references/docinfo-links.md` - the official DocInfo document links per NFR.

## Absolute rule - the reference model is READ-ONLY
> **NEVER modify the bundled `.xlsm` template.** It is the single source of truth. Always work on
> a **copy** saved under a new name (`new-nfr-workbook.ps1` handles this). Never write to,
> rename, move or overwrite the bundled template itself.

## When to use this skill
- Answer a question about one or more NFRs (what it means, when it applies, who is responsible,
  can it be dispensed, what status is expected).
- Decide, for an application, which NFRs are relevant and at what status, given its context.
- Produce or update the filled NFR Excel deliverable for a gate (TCC / Architecture Gates) or the
  pre-study.
- Review an already-filled NFR workbook (dump + summary).

## Reference (bundled - load on demand)
- `references/nfr-catalog.md` - the full distilled NFR list, grouped by ISO 25010 chapter. Use
  this to drive relevance; cite the bundled `.xlsm` as the authority.
- `references/nfr-cards/NFR-XXXX.md` - the detailed card per NFR (goal, constraints, governance,
  DocInfo link). Open the matching card to answer a detailed question about one NFR.
- `references/nfr-index-bilingual.md` - EN/FR title lookup by code.
- `references/dict-filter-reference.md` - DICT scales + how the filter columns trigger NFRs.
- `references/docinfo-links.md` - official DocInfo links per NFR (share with the user).
- `references/workflow.md` - the end-to-end assessment method: gather context -> run the filter
  macro -> set status -> produce deliverable. Read this before doing an assessment.
- `references/tooling.md` - how to run the model's macros and fill the workbook via Excel COM,
  the OneDrive save caveat, the scripts, and the valid values. Read before running a script.
- `references/roles-glossary.md` - the BUILD/RUN roles referenced by each NFR (IT-PM, ASI, TPM,
  ITE-TN, PGA, ...).
- `references/faq.md` - common NFR questions with precise answers.
- `references/decisions-template.tsv` - starter decisions file for `new-nfr-workbook.ps1`.

## Scripts (bundled - see `references/tooling.md`)
- `assets/scripts/NfrRepo.psm1` - shared Excel-COM module (sheet/cell map, read helpers). Reuse
  it; do not re-implement the COM plumbing inline.
- `assets/scripts/export-nfr.ps1` - read-only dump of a workbook to TSV + status summary.
- `assets/scripts/new-nfr-workbook.ps1` - produce the filled deliverable from a decisions file.

## Core rules (always apply)
1. **The bundled `.xlsm` is the authority and is read-only.** Answer from `nfr-catalog.md` for
   speed; cite the model. Copy it first; edit only the copy.
2. **Never add/modify/remove an NFR.** Only Status, dates and Comments are project decisions.
3. **Relevant is computed ONLY by the model's macro.** The generator runs the model's own
   `RequirementsFilter` + `ShowHideRequirements` macros (the human "filter button"), auto-
   confirming the Oui/Non MsgBox. This is the ONLY authorised calculation - never hand-set
   Relevant and never substitute another method. If the macro cannot run, the script stops and
   asks the user to run it manually and come back (do not compute Relevant yourself).
   `Test-NfrRelevant` is explain-only (for questions), not for filling a deliverable. Trap:
   `C1234`/`D1234` list all levels, so they are relevant even at level 1. Filtered-out rows are
   hidden. Put your applicability opinion in Status, not Relevant.
4. **Never invent the system context.** DICT, RTO, SOX and data-privacy inputs come from the
   MOA / DPO / the `dict-assessment` deliverable. If unknown, mark `TBD - to validate` and say
   so; produce a best-effort draft and list open questions - tag each one
   `- **Ask:** MOA`/`DPO`/`PGA` per `.kiro/steering/open-questions-convention.md` so
   `open-questions-consolidation` routes it correctly instead of it staying buried in this README.
5. **Respect dispensation (via Status).** `No dispense possible` = mandatory (never Status Not
   relevant; use Not feasible + contingency if truly impossible). A conditional dispensation may
   be applied only when its condition holds - record which condition applies.
6. **Justify every decision.** Each Not relevant / Not feasible needs a one-line reason tied to
   the trigger and/or dispensation (it is audited at the gate).
7. **Flag security gaps.** A relevant Security NFR left unimplemented at Go-Live must be
   validated by the right CRIS member (RDMI too if DICT >= 3). Surface it, never hide it.
8. **Keep output `.xlsm`, UTF-8/ASCII-safe.** Write it to the per-project output folder
   `output/${project_name}/` (create it if missing - see the `output-convention.md` steering,
   single source of truth for output location), named `${project_name}_NFR.xlsm`. Preserve the
   macros and Synthesis charts; avoid
   mojibake (use `-`, straight quotes).
9. **The `.xlsm` is the only NFR deliverable; do NOT keep the working decisions file.** The
   decisions TSV (and any `*_NFR_decisions.tsv` / `*_NFR_decisions.csv` export) is only an
   intermediate input to `new-nfr-workbook.ps1`. Once the `.xlsm` is generated, delete the TSV so
   it is not mistaken for the deliverable. Presentations and checklists must reference the
   `.xlsm`, never the TSV.

## Quick workflow
1. Gather the system context: DICT, RTO, SOX, data-privacy level, and the app's functional/
   technical nature. (Use the `dict-assessment` skill if the DICT is not settled.)
2. Read `references/workflow.md`. Relevance is computed from the context; for each NFR that comes
   out relevant, decide the project Status and write a one-line justification (dispensation).
3. Put the Status + Comment decisions in a TSV (see `references/decisions-template.tsv`) - no
   Relevant column.
4. Generate the deliverable with `assets/scripts/new-nfr-workbook.ps1` (system parameters ->
   computed Relevant -> your Status/Comment) - see `references/tooling.md`.
5. Re-dump with `assets/scripts/export-nfr.ps1` to confirm values landed and review the
   status/relevance summary.
6. **Delete the working decisions TSV** - the `.xlsm` is the deliverable; do not leave the
   `*_NFR_decisions.tsv` behind (it must not be mistaken for or referenced as the deliverable).
7. Report what is relevant / not relevant / not feasible and what still needs MOA/business
   validation.
