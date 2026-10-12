# Output format - Threat Modeling pre-fill

Two deliverables in the per-project output folder **`output/${project_name}/`** (see the
`output-convention.md` steering - single source of truth for output location; never in the scratch
area `.kiro/.temp_ai/`):
- `${project_name}_threat_modeling.xlsx` - the STRIDE-LM scenario workbook (the main deliverable).
- `${project_name}_threat_modeling_README.md` - the companion README / audit trail
  (see `readme-template.md`). Its editable model `${project_name}_threat_modeling.model.json`
  may be kept next to it for regeneration.

## The .xlsx (built by ThreatModelXlsx.psm1)
Three sheets, in order:

1. **Cover** - project / author / date, AI engine (Bedrock by default), inputs (DAT + dataflow),
   scenario count, the risk/effectiveness scales, and - mandatory - the banner
   **"STATUS: TO BE VALIDATED BY THE SECURITY TEAM - NOT ACQUIRED"** plus the disclaimer.
2. **Threat Scenarios** - one row per candidate scenario, columns:
   `ID | Element / asset | Scope | Threat scenario | STRIDE-LM | Occurrence (1-4) | Impact (1-4) |
   Risk level | Countermeasures | Effectiveness (0-3) | NIST families | Validation status`.
   This is the qualification table required by M3 (ID, element, scope, scenario, STRIDE-LM,
   occurrence, impact, risk level, countermeasures) plus the countermeasure-effectiveness score
   and the NIST mapping.
3. **NIST Mapping** - `Scenario ID | STRIDE-LM | NIST SP 800-53 families | Family names`.

## Encoding / OPC rules
- Built WITHOUT Python / Office: the module writes minimal Open XML parts and zips with
  `ZipArchiveMode.Create` (NEVER `Update`). UTF-8 without BOM; cell text XML-escaped as inline
  strings; English.
- Always run `assets/scripts/validate-threatmodel.ps1` after building; it must print
  `THREAT MODEL VALIDATION OK` and exit 0 before delivery.

## Risk / effectiveness values
All scores (occurrence, impact, risk level, effectiveness) use the scales in
`prefill-logic.json`. They are PROPOSED; `Validation status` stays "To be validated by the
security team" until the SFES Cybersecurity team signs off.
