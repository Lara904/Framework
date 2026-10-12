# Helper scripts - threat-modeling-prefill

Self-contained PowerShell generator + validator for the Threat Modeling (STRIDE-LM) workbook, with
no Python / Office dependency. All treat the output as a `.xlsx` OPC package.

## Module (the engine)
`ThreatModelXlsx.psm1` builds a valid `.xlsx` from a JSON model: it writes the minimal Open XML
parts (workbook, 3 worksheets, styles, rels, content types) and zips them with
`ZipArchiveMode.Create` (NEVER `Update`, which corrupts OPC packages and triggers "repair on
open"). UTF-8 without BOM; cell text XML-escaped as inline strings. Public function:
`New-ThreatModelXlsx -Model <hashtable|pscustomobject> -OutFile <path>`.

Sheets produced: `Cover` (incl. the "TO BE VALIDATED BY THE SECURITY TEAM" banner + the real
scales), `Threat Scenarios` (the STRIDE-LM qualification table + countermeasure efficiency + NIST),
`NIST Mapping`.

## Wrappers
- `build-threatmodel.ps1 -Model "<project>_threat_modeling.model.json" -Out "<project>_threat_modeling.xlsx"`
  Renders the workbook from the JSON model. Fails loudly if no file (or a <1000-byte file) is produced.
- `validate-threatmodel.ps1 -Xlsx "<project>_threat_modeling.xlsx"`
  OPC-level check ("would Excel repair this?") + every XML part well-formed + workbook declares a
  sheet, PLUS a content check that every scenario's occurrence/impact/risk level use the real
  1-3/matrix scale and not a leftover invented one (added after a real delivery shipped the old
  1-4/1-16 scale). Prints `THREAT MODEL VALIDATION OK` and exits 0 on success; non-zero on failure.
  Run it on every generated workbook before delivery.

## Invocation (per the command-execution steering)
Call the scripts directly with `-File` and their documented arguments; do NOT wrap them in a
`_run.ps1` that re-imports the module by relative path (silent-failure trap). Example:
```
powershell -NoProfile -ExecutionPolicy Bypass -File ".kiro\skills\threat-modeling-prefill\assets\scripts\build-threatmodel.ps1" -Model "<project>_threat_modeling.model.json" -Out "<project>_threat_modeling.xlsx"
powershell -NoProfile -ExecutionPolicy Bypass -File ".kiro\skills\threat-modeling-prefill\assets\scripts\validate-threatmodel.ps1" -Xlsx "<project>_threat_modeling.xlsx"
```

The risk matrix, efficiency formula, STRIDE-LM reference, scenario-selection logic and NIST mapping
are in `../../references/prefill-logic.json`; the real scenario content is in
`../../references/threat-catalog.json` and the real countermeasure data is in
`../../references/countermeasure-library.json` (single source of truth) - the module/scripts do
not restate them.
