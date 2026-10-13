---
name: threat-modeling-prefill
description: Pre-fill a project-team Threat Model (STRIDE-LM) for a SIBS / Stellantis Financial Services Architecture Gates (ARB, Gate 2) submission, from the application's Technical Architecture Document (DAT) and its dataflow. Selects candidate threat scenarios from a bundled REAL 176-scenario SFS STRIDE-LM catalog (by category/scope/element), scores occurrence/impact/risk with the real SFS matrix and countermeasure efficiency with the real formula (from a bundled 97-countermeasure library), maps each scenario to NIST SP 800-53 families, and produces an Excel (.xlsm/.xlsx) workbook plus an audit-trail README. Only a genuinely custom scenario with no catalog match is worded by an explicit AI call (AWS Bedrock by default); the skill embeds no intelligence of its own otherwise. Self-contained - the real catalog, the real countermeasure library, the OPC-safe Excel generator and the validator are bundled. Every scenario is a CANDIDATE to be validated by the security team, never acquired. MVP scope is the project-team panel only (the CISO and pentest panels are target-vision extensions, out of scope).
keywords:
  - threat modeling
  - threat model
  - TM
  - STRIDE
  - STRIDE-LM
  - spoofing
  - tampering
  - repudiation
  - information disclosure
  - denial of service
  - elevation of privilege
  - lateral movement
  - risk scenario
  - countermeasure
  - NIST
  - NIST 800-53
  - cybersecurity
  - CISO
  - SFES
  - gate 2
  - architecture gates
  - ARB
  - TCC
  - DAT
  - dataflow
  - Bedrock
---

# Threat Modeling pre-fill (STRIDE-LM, project-team panel)

This skill produces a **pre-filled Threat Model** (STRIDE-LM) for a project, to accelerate the
preparation carried by the project team and reduce the load on the CISO team at Architecture Gates
(ARB) Gate 2. It reads the application's **Technical Architecture Document (DAT)** and its
**dataflow**, selects candidate threat scenarios from the bundled **real 176-scenario SFS
catalog** (`references/threat-catalog.json`), scores them with the real SFS risk matrix and the
real countermeasure-efficiency formula (`references/countermeasure-library.json`), maps them to
NIST, and writes an Excel workbook plus an audit-trail README.

> **v2.0 note.** v1.0 of this skill derived scenarios from only 4 generic, hand-written rules and
> scored them with an invented 1-4/1-16 risk scale and an invented 0-3 "effectiveness" score. A
> real delivery built on it ("Le threat modeling ne va pas du tout") shipped 7 thin, hand-picked
> scenarios with fabricated scoring. v2.0 replaces both: the real SFS catalog and countermeasure
> library (supplied directly from the live Cybersecurity TM tool) are now bundled and are the
> single source of truth for scenario content and scoring - see "Single source of truth" below.

> **Non-negotiable guardrail - validation by the security team.** Everything this skill produces is
> a PRE-FILL: every scenario, score and countermeasure is a CANDIDATE to be reviewed, corrected and
> validated by the SFES Cybersecurity team before use. The workbook and README carry a visible
> "TO BE VALIDATED BY THE SECURITY TEAM - NOT ACQUIRED" status at all times. The skill assists the
> preparation; it does not replace the security risk analysis.

> **MVP scope = project-team panel only.** The vision for this module has three panels; only the
> project-team pre-fill is in scope here. The CISO panel (a separate tool for the CISO team) and
> the pentest panel (Gate 3/4) are target-vision extensions - never present them as delivered or
> engaged.

> **No embedded intelligence.** The skill is a deterministic orchestration layer. The deterministic
> parts (signal detection, risk scales, NIST mapping) live in `references/prefill-logic.json`; the
> scenario wording is produced by an explicit model call - **AWS Bedrock by default** (SFS Assist
> only as an optional conversational layer if a dialog need is confirmed). Threat scenarios and
> vulnerability details stay internal; never route them to an unvalidated external tool.

## When to use this skill
- A project has reached Gate 2 with a DAT and a dataflow available, and needs a first Threat Model.
- You want to pre-fill STRIDE-LM scenarios, scores and the NIST mapping for the project team to
  review with the security team.
- You need to refresh the TM workbook after the DAT / dataflow changed.

## Single source of truth - the pre-fill logic and the real catalog
> The risk matrix, the countermeasure-efficiency formula, the STRIDE-LM categories, the
> scenario-selection logic, and the STRIDE-LM -> NIST SP 800-53 mapping all live in ONE structured
> file: **`references/prefill-logic.json`**. The scenario content itself lives in two more bundled,
> REAL data files: **`references/threat-catalog.json`** (176 real scenarios) and
> **`references/countermeasure-library.json`** (97 real countermeasures). The generator and any
> generated doc read from these. There is NO second copy and NO hand-written substitute - never
> restate a rule or a scenario in a `.md`, hard-code one in the module, or invent a "representative"
> scenario when the catalog already has the real one. To change a rule, the matrix or the NIST
> mapping, edit `prefill-logic.json` only; to correct a scenario or countermeasure's real-world
> wording or scoring inputs, edit the catalog/library file, never a generated deliverable.

## Bundled assets (inside this skill)
- `references/prefill-logic.json` - risk matrix, efficiency formula, STRIDE-LM reference,
  scenario-selection logic and NIST map.
- `references/threat-catalog.json` - the real 176-scenario SFS STRIDE-LM catalog.
- `references/countermeasure-library.json` - the real 97-countermeasure library.
- `references/stride-library.json` - the official STRIDE-LM definitions, explanation, cloud
  example and mitigation concept per code.
- `references/` - also the questionnaire, STRIDE-LM guide, output format, model schema and
  README template.
- `assets/scripts/ThreatModelXlsx.psm1` - OPC-safe `.xlsx` generator (no Python / Office).
- `assets/scripts/build-threatmodel.ps1` - wrapper: JSON model -> `.xlsx`.
- `assets/scripts/validate-threatmodel.ps1` - OPC/XML validator PLUS a content check that
  occurrence/impact/risk level use the real scale, not a leftover invented one (must exit 0
  before delivery).

## Deliverables (always produce both)
Naming convention `${project_name}_threat_modeling_<kind>`, written to the per-project output
folder `output/${project_name}/` (create it if missing) - see the `output-convention.md` steering
(single source of truth for output location):
1. `${project_name}_threat_modeling.xlsx` - the STRIDE-LM scenario workbook (Cover + Threat
   Scenarios + NIST Mapping) - see `references/output-format.md`.
2. `${project_name}_threat_modeling_README.md` - the audit-trail README (how each scenario was
   derived, proposed scores, open questions, validation block) - see `references/readme-template.md`.
   Its editable model `${project_name}_threat_modeling.model.json` may be kept beside it.

All deliverables are in **English**.

## Ask before generating (never invent)
Seed from the DAT + dataflow, then confirm with the project team using
`references/questionnaire.md` (a ~30-min structured interview) - ask ONLY what the sources do not
already answer. **Never invent** an element, scenario, occurrence/impact score, countermeasure or
NIST family: select real scenarios and countermeasures from `threat-catalog.json` /
`countermeasure-library.json`. Any unknown becomes a `TBC` in the workbook, an Open question in the
README, and a question to the project team / security - tag each README item
`- **Ask:** PGA`/`Security` per `.kiro/steering/open-questions-convention.md` so
`open-questions-consolidation` can route it. A category excluded on an assumption (e.g. "no
CI/CD pipeline of its own") is itself an open question to confirm, not a silent default - do not
exclude a catalog category without asking.

## Reference guides (load on demand)
- `references/prefill-logic.json` - single source of truth (matrix, efficiency formula,
  scenario-selection logic, STRIDE-LM, NIST).
- `references/threat-catalog.json` - the real 176-scenario SFS catalog.
- `references/countermeasure-library.json` - the real 97-countermeasure library.
- `references/stride-library.json` - official STRIDE-LM definitions.
- `references/stride-lm.md` - human-readable STRIDE-LM categories, scales and selection logic.
- `references/questionnaire.md` - the project-team interview (project-team panel only).
- `references/output-format.md` - the two deliverables and the three workbook sheets.
- `references/model-schema.md` - the JSON model schema for the generator.
- `references/readme-template.md` - the audit-trail README structure.

## Core rules (always apply)
1. **To be validated by the security team.** The TM is a pre-fill; keep the "NOT ACQUIRED / to be
   validated" status visible on the cover, in every scenario row, and in the README. Never present
   it as acquired.
2. **No embedded intelligence, except for a genuinely custom scenario.** A scenario taken from
   `threat-catalog.json` keeps its real wording verbatim - never re-worded by a model call. Only a
   signal with NO catalog match is worded via an explicit model call (Bedrock by default); the
   deterministic logic (selection, matrix, efficiency, NIST) stays in `prefill-logic.json`.
3. **One source of truth.** All rules / scales / STRIDE-LM / NIST come from `prefill-logic.json`;
   all scenario content comes from `threat-catalog.json`; all countermeasure data comes from
   `countermeasure-library.json`. Never duplicate any of them into prose, code or a generated
   deliverable's hand-edited text.
4. **Select from the real catalog by category/scope/element; never hand-pick a sample.** Apply
   `prefill-logic.json`'s `scenarioSelection` to the DAT + dataflow + questionnaire answers to keep
   the FULL applicable catalog subset - a real delivery narrowed this to 7 scenarios instead of the
   applicable subset and was rejected ("ça ne va pas du tout"). An unknown stays `TBC` + an Open
   question, never a fabricated value.
5. **Infra / Landing Zone coupling is a dedicated alert.** It is a recurrent ARB refusal motive -
   always keep the full "Infra cloud" category subset when it applies, and flag its
   Elevation-of-Privilege / Lateral-Movement scenarios explicitly.
6. **Scores use the REAL SFS scale, not an invented one.** Occurrence/impact are 1-3; risk level is
   the matrix lookup (very low/low/average/above average/high/extreme), never a numeric product or
   band; countermeasure value is the real efficiency formula (occurrenceMitigation x
   impactMitigation x easeOfImplementation x bandWeight), never an invented 0-3 "effectiveness"
   score. All of it stays a proposal; keep each scenario's validation status open until the
   security team signs off.
7. **MVP scope = project-team panel.** Do not produce or imply the CISO or pentest panels.
8. **Keep data internal.** Threat scenarios and vulnerability details are internal; never send them
   to an unvalidated external tool.
9. **English, ASCII-safe, UTF-8 without BOM.** Build the `.xlsx` OPC-safe (`ZipArchiveMode.Create`,
   never `Update`); run `validate-threatmodel.ps1` (exit 0) before delivery - it checks both the
   OPC package AND that occurrence/impact/risk level use the real scale.
10. **Inter-deliverable consistency.** The workbook and the README must agree (same scenarios,
    scores, NIST families); every scenario must trace to either a catalog id (`TM<n>`) or an
    explicit `custom` flag - never an untraceable scenario.

## Quick workflow
1. Read the DAT (`${project}_technical_architecture_document.docx`) and the dataflow
   (`${project}_technical_architecture_dataflow.drawio` / `_dataflow_mapping.xlsx`); identify which
   of the 6 catalog categories apply (Applicative, CI/CD, Infra cloud, EKS, SaaS, LLM IA) and which
   scopes are real for this architecture.
2. Apply `references/prefill-logic.json`'s `scenarioSelection` against `threat-catalog.json` to list
   the full applicable scenario subset; for any signal with no catalog match, call the model
   (Bedrock) to word a `custom: true` scenario from the real context.
3. Confirm with the project team using `references/questionnaire.md` (ask only what is missing);
   propose occurrence/impact (1-3) per scenario.
4. Assemble the JSON model (`references/model-schema.md`): look up each kept scenario's real
   countermeasures in `countermeasure-library.json`, compute riskLevel (matrix) and efficiency
   (formula) per `prefill-logic.json`, and map each scenario to NIST families via the
   `strideToFamilyHint`.
5. Build the workbook with `assets/scripts/build-threatmodel.ps1`, then validate with
   `assets/scripts/validate-threatmodel.ps1` (must print `THREAT MODEL VALIDATION OK`, exit 0).
6. Write `${project_name}_threat_modeling_README.md` (`references/readme-template.md`) tracing each
   scenario to its catalog id or custom flag, the proposed scores, open questions and the
   validation block.
7. Report what was pre-filled and - explicitly - that the TM must be validated by the security team.
