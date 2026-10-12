# Threat Modeling pre-fill - JSON model schema

`assets/scripts/build-threatmodel.ps1` renders the workbook from a single JSON model,
`${project_name}_threat_modeling.model.json`. The pre-fill RULES, STRIDE-LM reference, risk scales
and the NIST mapping all come from `references/prefill-logic.json` (single source of truth) - do
not restate them here or hard-code them in the module.

Every scenario is a CANDIDATE to be validated by the security team; `validationStatus` defaults to
"To be validated by the security team".

## Schema
```json
{
  "title": "Threat Modeling (STRIDE-LM)",
  "subtitle": "<App / project name>",
  "author": "<name>",
  "date": "YYYY-MM-DD",
  "engine": "AWS Bedrock (direct call)",
  "inputs": "DAT + dataflow (<project>_technical_architecture_document.docx / _dataflow.drawio)",
  "disclaimer": "This threat model is a PRE-FILL ... validated by the SFES Cybersecurity team before use.",
  "scenarios": [
    {
      "id": "TM-01",
      "element": "<asset / component from the DAT or dataflow>",
      "scope": "<edge / flow / data store / infra ...>",
      "scenario": "<one-line threat scenario, produced by the model call>",
      "stride": "S, T",
      "occurrence": "3",
      "impact": "4",
      "riskLevel": "High (12)",
      "countermeasures": "<existing or proposed countermeasures>",
      "effectiveness": "2",
      "nist": "AC, IA, SC",
      "nistNames": "Access Control; Identification and Authentication; System and Communications Protection",
      "validationStatus": "To be validated by the security team"
    }
  ]
}
```

### Field notes
| Field | Shape | Notes |
|-------|-------|-------|
| `title`, `author`, `date` | string | mandatory (cover + docProps) |
| `subtitle` | string | project name |
| `engine` | string | the AI engine used for scenario wording (Bedrock by default) |
| `inputs` | string | which DAT / dataflow files fed the pre-fill |
| `disclaimer` | string | the "to be validated by the security team" banner text |
| `scenarios[]` | array | one object per candidate STRIDE-LM scenario |
| `scenarios[].stride` | string | one or more STRIDE-LM codes (S,T,R,I,D,E,L), comma-separated |
| `scenarios[].occurrence` / `impact` | string | 1..4 per the scales in `prefill-logic.json` |
| `scenarios[].riskLevel` | string | band + value, e.g. "High (12)" = occurrence x impact |
| `scenarios[].effectiveness` | string | 0..3 countermeasure effectiveness |
| `scenarios[].nist` | string | NIST SP 800-53 family codes, comma-separated |

## Rules
- `title`, `author`, `date` are mandatory; the rest are recommended.
- Never invent an element, scenario, score or countermeasure: derive scenarios from the DAT +
  dataflow via the rules in `prefill-logic.json`; an unknown becomes `TBC` + an Open question in
  the README, not a fabricated value.
- Occurrence/impact/effectiveness are PROPOSED values to validate with the security team - keep
  `validationStatus` as "To be validated by the security team" until they sign off.
- Keep STRIDE-LM, scales and NIST mapping consistent with `prefill-logic.json`.
- UTF-8 (no BOM); ASCII-safe; English.
