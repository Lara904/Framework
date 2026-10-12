---
name: deliverable-detection
description: Scan a folder of files dropped in bulk (no imposed naming or sorting) and produce an ordered checklist of which files map to which expected ARB deliverable category, with confidence and evidence, plus what is missing or ambiguous. Routes each category to its consumer skill. Read-only on the sources; the only output is a detection README. Never classifies silently when ambiguous - it asks the user.
keywords:
  - deliverable detection
  - detection
  - classification
  - mapping
  - triage
  - inventory
  - ARB
  - TCC
  - architecture gates
  - drop folder
  - sources
  - checklist
  - functional architecture
  - technical architecture
  - dataflow
  - DICT
  - NFR
  - cost
  - access rights
  - threat modeling
---

# Deliverable Detection

This skill looks at a folder where a project owner has dropped documents **as-is** (no required
naming, no required folder layout) and figures out, file by file, which expected ARB / TCC
deliverable each one corresponds to - before any other skill runs. It is the entry point that
makes good on the product promise: *the user drops their files, the tool sorts it out.*

It produces an **ordered mapping checklist** (`${project_name}_deliverables_detection_README.md`):
for each detected file, the proposed category, the consumer skill, a confidence level and the
evidence; for each expected category with nothing found, a "missing" line; for each ambiguous
file, an explicit question to the user.

## Absolute rule - sources are READ-ONLY
> **Never move, rename, modify or delete anything in the scanned folder** (e.g. `sources/`). This
> skill only READS. The single artefact it writes is the detection README in the per-project
> output folder `output/${project_name}/` (see the `output-convention.md` steering). Any work file
> (e.g. the scan JSON) goes under `.kiro/.temp_ai/`, never in `output/` and never inside the sources.

## Single source of truth - the category map
> The categories, their **consumer skill**, and the **detection signals** (name keywords, path
> keywords, expected extensions, notes) live in ONE structured file:
> **`references/categories.json`**. The scan script reads it; the README renders its rows from it.
> There is NO second copy - do not hard-code the mapping in the script or retype it in a `.md`.
> To add or change a category, edit `categories.json` only. (This is the lesson carried over from
> `presentation-gates`, where a duplicated table almost drifted silently.)

## When to use this skill
- A project folder (e.g. `sources/tcc-reel/`) contains unsorted documents and you need to know
  what is there and what feeds which skill.
- Before launching `functional-architecture`, `technical-architecture`, `nfr-requirements`,
  `cost-estimation`, `dict-assessment`, `access-right-matrix`, `threat-modeling-prefill` or
  `presentation-gates` - so each one knows where to look.
- To re-check coverage after new files are dropped.

## Bundled assets
- `references/categories.json` - the authoritative category -> consumer-skill map + signals.
- `references/detection-method.md` - the 3-pass method (cheap signals, content check, resolve).
- `references/readme-template.md` - the detection README format (the deliverable).
- `assets/scripts/detect-deliverables.ps1` - read-only scanner that reads `categories.json` and
  emits per-file candidates + per-category coverage as JSON. Holds no category table of its own.

## Core rules (always apply)
1. **Read-only on sources.** Never alter the scanned folder. Only the README is produced.
2. **One source of truth.** All category/skill/signal data comes from `references/categories.json`.
   Never duplicate it into prose or code.
3. **Never classify silently when ambiguous.** If a file could be two categories (and neither is a
   clear High), or nothing matches, put it under "Open questions" with the exact question for the
   user - do not guess. Same "never invent" guardrail as the other skills.
4. **Cite evidence for every mapping.** A High-confidence mapping must name the signal (file name,
   extension or path) that justifies it. Medium/Low mappings are provisional and say so.
5. **Map per file, not per folder**, when a folder mixes categories (e.g. flow diagrams next to a
   general technical diagram). See the disambiguation notes in `references/detection-method.md`.
6. **A file can map to more than one category** when it legitimately carries two things (e.g. a
   PRD/REFLEX code or a DICT value embedded in an architecture doc) - record both with evidence.
7. **English only, ASCII-safe** in the README (use `-`, straight quotes; no mojibake).
8. **The README is an audit trail.** Historize re-runs (change-history row) and preserve the
   user's resolutions of earlier open questions across runs.
9. **Work files under `.kiro/.temp_ai/`.** The script's JSON output is a work artefact; write it
   there, not to `output/`.

## Quick workflow
1. Confirm the folder to scan (e.g. `sources/tcc-reel/`) and the `${project_name}`.
2. Run the scanner (read-only), writing its JSON to the temp area:
   `powershell -ExecutionPolicy Bypass -File assets/scripts/detect-deliverables.ps1 -Path "<folder>" -Out ".kiro/.temp_ai/<project>_detection.json"`.
3. For every file left ambiguous or only Medium/Low, do a content check (Pass 2 in
   `references/detection-method.md`) to confirm or reject - never promote to High without evidence.
4. Resolve: Detected (clear) / Missing (required, no file) / Open question (still ambiguous ->
   ask the user).
5. Write `${project_name}_deliverables_detection_README.md` to the per-project output folder
   `output/${project_name}/` (create it if missing - see the `output-convention.md` steering,
   single source of truth for output location), using `references/readme-template.md`, rendering
   the category rows from `categories.json`.
6. Report coverage (detected/total, required missing, open questions) and the questions the user
   must answer before the downstream skills run.
