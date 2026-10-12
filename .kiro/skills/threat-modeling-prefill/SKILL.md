---
name: threat-modeling-prefill
description: Pre-fill a project-team Threat Model (STRIDE-LM) for a SIBS / Stellantis Financial Services Architecture Gates (ARB, Gate 2) submission, from the application's Technical Architecture Document (DAT) and its dataflow. Derives candidate threat scenarios via a bundled pre-fill-logic table, scores occurrence/impact/risk and countermeasure effectiveness, maps each scenario to NIST SP 800-53 families, and produces an Excel (.xlsm/.xlsx) workbook plus an audit-trail README. Scenario wording is produced by an explicit AI call (AWS Bedrock by default); the skill embeds no intelligence of its own. Self-contained - the pre-fill logic, the OPC-safe Excel generator and the validator are bundled. Every scenario is a CANDIDATE to be validated by the security team, never acquired. MVP scope is the project-team panel only (the CISO and pentest panels are target-vision extensions, out of scope).
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
**dataflow**, derives candidate threat scenarios, scores them, maps them to NIST, and writes an
Excel workbook plus an audit-trail README.

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

## Single source of truth - the pre-fill logic
> The STRIDE-LM categories, the risk/effectiveness scales, the architecture-signal -> scenario
> pre-fill rules, and the STRIDE-LM -> NIST SP 800-53 mapping all live in ONE structured file:
> **`references/prefill-logic.json`**. The generator and any generated doc read from it. There is NO
> second copy - never restate the table in a `.md` or hard-code it in the module. To change a rule
> or the NIST mapping, edit `prefill-logic.json` only.

## Bundled assets (inside this skill)
- `references/prefill-logic.json` - the pre-fill rules, STRIDE-LM reference, scales and NIST map.
- `references/` - the questionnaire, STRIDE-LM guide, output format, model schema and README template.
- `assets/scripts/ThreatModelXlsx.psm1` - OPC-safe `.xlsx` generator (no Python / Office).
- `assets/scripts/build-threatmodel.ps1` - wrapper: JSON model -> `.xlsx`.
- `assets/scripts/validate-threatmodel.ps1` - OPC/XML validator (must exit 0 before delivery).

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
NIST family. Any unknown becomes a `TBC` in the workbook, an Open question in the README, and a
question to the project team / security.

## Reference guides (load on demand)
- `references/prefill-logic.json` - single source of truth (rules, scales, STRIDE-LM, NIST).
- `references/stride-lm.md` - human-readable STRIDE-LM categories, scales and rules.
- `references/questionnaire.md` - the project-team interview (project-team panel only).
- `references/output-format.md` - the two deliverables and the three workbook sheets.
- `references/model-schema.md` - the JSON model schema for the generator.
- `references/readme-template.md` - the audit-trail README structure.

## Core rules (always apply)
1. **To be validated by the security team.** The TM is a pre-fill; keep the "NOT ACQUIRED / to be
   validated" status visible on the cover, in every scenario row, and in the README. Never present
   it as acquired.
2. **No embedded intelligence.** Scenario wording comes from an explicit model call (Bedrock by
   default); the deterministic logic stays in `prefill-logic.json`.
3. **One source of truth.** All rules / scales / STRIDE-LM / NIST come from `prefill-logic.json`;
   never duplicate them into prose or code.
4. **Derive from the DAT + dataflow; never invent.** Map architecture signals to scenarios via the
   rules; an unknown is `TBC` + an Open question, not a fabricated value.
5. **Infra / Landing Zone coupling is a dedicated alert.** It is a recurrent ARB refusal motive -
   always surface the Elevation-of-Privilege / Lateral-Movement scenario and flag it high.
6. **Scores are proposals.** Occurrence, impact, risk level and effectiveness are proposed values to
   validate; keep each scenario's validation status open until the security team signs off.
7. **MVP scope = project-team panel.** Do not produce or imply the CISO or pentest panels.
8. **Keep data internal.** Threat scenarios and vulnerability details are internal; never send them
   to an unvalidated external tool.
9. **English, ASCII-safe, UTF-8 without BOM.** Build the `.xlsx` OPC-safe (`ZipArchiveMode.Create`,
   never `Update`); run `validate-threatmodel.ps1` (exit 0) before delivery.
10. **Inter-deliverable consistency.** The workbook and the README must agree (same scenarios,
    scores, NIST families); the scenarios must trace back to the DAT / dataflow.

## Quick workflow
1. Read the DAT (`${project}_technical_architecture_document.docx`) and the dataflow
   (`${project}_technical_architecture_dataflow.drawio` / `_dataflow_mapping.xlsx`); identify the
   architecture signals (API exposure, file/batch, PII, infra/LZ coupling).
2. Apply the rules in `references/prefill-logic.json` to list candidate STRIDE-LM scenarios; for
   each, call the model (Bedrock) to word the scenario precisely from the real context.
3. Confirm with the project team using `references/questionnaire.md` (ask only what is missing);
   propose occurrence/impact and the countermeasure effectiveness.
4. Assemble the JSON model (`references/model-schema.md`); map each scenario to NIST families via
   `prefill-logic.json`.
5. Build the workbook with `assets/scripts/build-threatmodel.ps1`, then validate with
   `assets/scripts/validate-threatmodel.ps1` (must print `THREAT MODEL VALIDATION OK`, exit 0).
6. Write `${project_name}_threat_modeling_README.md` (`references/readme-template.md`) tracing each
   scenario to its rule, the proposed scores, open questions and the validation block.
7. Report what was pre-filled and - explicitly - that the TM must be validated by the security team.
