# Threat Modeling README - companion template (audit trail)

Write `${project_name}_threat_modeling_README.md` to the per-project output folder
`output/${project_name}/` (see the `output-convention.md` steering - single source of truth for
output location), in English. It is the
audit trail of the pre-fill: inputs used, how each scenario was derived, the proposed scores, and
what still needs the security team. The STRIDE-LM / scales / NIST reference come from
`prefill-logic.json`; the scenarios themselves come from `threat-catalog.json` and the
countermeasures from `countermeasure-library.json` (render, do not duplicate).

```markdown
# <Project> - Threat Modeling (STRIDE-LM) pre-fill

Version: <x.y>  |  Date: <YYYY-MM-DD>  |  Author: threat-modeling-prefill skill
Workbook: <project>_threat_modeling.xlsx
Engine: AWS Bedrock (direct call)   |   Inputs: DAT + dataflow (<files>)
Status: **TO BE VALIDATED BY THE SECURITY TEAM - NOT ACQUIRED**

## Disclaimer
This threat model is a PRE-FILL to accelerate preparation. Every scenario, score and
countermeasure is a CANDIDATE to be reviewed, corrected and validated by the SFES Cybersecurity
team before use. It does not replace the security risk analysis. (MVP scope = project-team panel
only; the CISO and pentest panels are target-vision extensions, out of scope.)

## Scope
Which components / flows / data stores were covered (from the DAT + dataflow).

## Scenarios (summary)
| ID | Element | STRIDE-LM | Risk level | Efficiency | NIST | Source |
|----|---------|-----------|-----------|------------|------|--------|
| TM1 | Data-flow | T | high | 36 (CM.010) | AC, IA, SC | catalog (Applicative) |
| CUSTOM-1 | ... | S | average | - | IA | custom (no catalog match) |

(The full table is in the .xlsx "Threat Scenarios" sheet.)

## How each scenario was derived
List which catalog categories were kept and why (per `prefill-logic.json`'s `scenarioSelection`),
and which were excluded and on what explicit basis (never a silent default exclusion). For a
`custom` scenario, state the architecture signal that triggered it and that its wording came from
the model call, not the catalog. Note: list the FULL applicable catalog subset here, not a
hand-picked sample - a real past delivery shortened this to 7 scenarios and was rejected.

## Proposed scores (to validate)
State that occurrence / impact / risk level / countermeasure efficiency are proposals per the real
scale in `prefill-logic.json` (1-3 occurrence/impact, matrix-lookup risk level, formula-based
efficiency - not the old invented 1-4/1-16/0-3 scales), and on what basis each was set.

## Assumptions
- <anything inferred but not confirmed by the sources / team>

## Open questions (to the project team / security)
- <every TBC, mirroring the questionnaire; e.g. unconfirmed DCP level, missing countermeasure>

## Validation
- Security validator: <name / TBC>  |  Target date: <TBC>
- The TM is NOT acquired until the security team signs off here.

## Change history
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1 | <YYYY-MM-DD> | threat-modeling-prefill skill | Initial pre-fill from DAT + dataflow. |
```

Rules:
- English only, ASCII-safe.
- Keep the "to be validated by the security team" status visible at the top and in every scenario.
- The README and the .xlsx MUST agree (same scenarios, scores, NIST families).
- Append a change-history row on each regeneration; never rewrite history.
