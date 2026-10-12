# Threat Modeling pre-fill - JSON model schema

`assets/scripts/build-threatmodel.ps1` renders the workbook from a single JSON model,
`${project_name}_threat_modeling.model.json`. The risk-scoring rules, STRIDE-LM reference, the real
scenario catalog, the real countermeasure library and the NIST hint all come from
`references/prefill-logic.json` + `references/threat-catalog.json` +
`references/countermeasure-library.json` (single source of truth) - do not restate them here or
hard-code them in the module.

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
      "id": "TM1",
      "custom": false,
      "element": "Data-flow",
      "scope": "Application",
      "scenario": "Handling of invalid or wrong data",
      "stride": "T",
      "occurrence": "2",
      "impact": "3",
      "riskLevel": "high",
      "countermeasures": "CM.010: Detect and handle wrong data; CM.025.001: Implement input and output filtering",
      "efficiency": "36 (CM.010)",
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
| `engine` | string | the AI engine used for CUSTOM scenario wording (Bedrock by default) - a catalog scenario keeps the catalog's own real wording, never re-worded by a model call |
| `inputs` | string | which DAT / dataflow files fed the selection |
| `disclaimer` | string | the "to be validated by the security team" banner text |
| `scenarios[]` | array | one object per candidate STRIDE-LM scenario, selected from `threat-catalog.json` per `prefill-logic.json`'s `scenarioSelection`, plus any genuinely CUSTOM scenario |
| `scenarios[].id` | string | the catalog id (`TM<n>`, matches `threat-catalog.json`) for a catalog scenario, or a new `CUSTOM-<n>` id for a custom one |
| `scenarios[].custom` | bool | `true` only for a scenario with no catalog match (see `prefill-logic.json`'s `scenarioSelection` step 3); `false`/absent for a catalog scenario |
| `scenarios[].stride` | string | one or more STRIDE-LM codes (S,T,R,I,D,E,LM), comma-separated - for a catalog scenario, copy its real `stride[]` verbatim, never re-derive |
| `scenarios[].occurrence` / `impact` | string | **1..3** each (not 1..4) - proposed by the project team per `prefill-logic.json`'s `scales`; a catalog scenario's `sampleOccurrence`/`sampleImpact` (when present) is an illustrative starting point only, never applied silently |
| `scenarios[].riskLevel` | string | the matrix label from `prefill-logic.json` (`very low`/`low`/`average`/`above average`/`high`/`extreme`) - looked up from (occurrence, impact), never computed as a product or given a numeric score |
| `scenarios[].countermeasures` | string | the catalog scenario's real `counterMeasureIds`/`counterMeasureTitles` (from `threat-catalog.json`), or the countermeasure(s) chosen for a custom scenario - `CM.<id>: <title>`, semicolon-separated; never a free-text invented countermeasure when a real CM.xxx applies |
| `scenarios[].efficiency` | string | for each listed countermeasure, its efficiency score per `prefill-logic.json`'s `countermeasureEfficiency` formula (needs that countermeasure's `occurrenceMitigation`/`impactMitigation`/`easeOfImplementation` from `countermeasure-library.json`, and this scenario's own riskLevel) - this REPLACES the old invented 0-3 "effectiveness" field |
| `scenarios[].nist` | string | NIST SP 800-53 family codes, comma-separated, per `prefill-logic.json`'s `nistReference` hint - an SFS/ARB-reporting addition, not part of the source catalog |

## Rules
- `title`, `author`, `date` are mandatory; the rest are recommended.
- **Select, don't invent.** Scenarios come from `threat-catalog.json` via the selection logic in
  `prefill-logic.json`; only a genuinely uncovered signal becomes a `custom: true` scenario, worded
  via the model call. Never hand-pick a "representative sample" of the catalog to shorten the
  deliverable - a real past delivery did exactly that (7 scenarios instead of the applicable
  catalog subset) and was rejected.
- Occurrence/impact/riskLevel/efficiency are PROPOSED values to validate with the security team -
  keep `validationStatus` as "To be validated by the security team" until they sign off.
- Keep STRIDE-LM, scales, the catalog/library ids and the NIST hint consistent with
  `prefill-logic.json`, `threat-catalog.json` and `countermeasure-library.json`.
- UTF-8 (no BOM); ASCII-safe; English.
