# access-right-matrix scripts

Self-contained PowerShell (no Python, no Microsoft Office). The deliverable is produced
by **copying** the bundled reference template and editing only the target cells /
placeholder tokens in place, then re-zipping with `ZipArchiveMode.Create` (never
`Update`, which corrupts OPC packages).

## Files
- `RightMatrixXlsx.psm1` - module. `New-RightMatrixXlsx -Model <obj|json> -TemplatePath
  <xlsx> -OutFile <xlsx>`. Reads every template part into memory, rewrites
  `xl/sharedStrings.xml` (token substitution `<PRD>`, optional REFLEX names) and
  `xl/worksheets/sheet3.xml` (APPLICATION Information cells C3..C7), copies all other
  parts verbatim.
- `build-rightmatrix.ps1` - wrapper. Reads the JSON model, calls the module. Defaults
  the template to `../templates/SFS_right_matrix_for_ciq_and_CI_CD_AWS_NG_v2026_03.xlsx`.
- `validate-rightmatrix.ps1` - OPC-level validator (would Excel repair this?) + XML
  well-formedness + placeholder report. Exit 0 = OK.

## Usage
```powershell
$s = '.kiro\skills\access-right-matrix\assets\scripts'
powershell -ExecutionPolicy Bypass -File "$s\build-rightmatrix.ps1" `
  -Model 'output/${project_name}/${project_name}_access_right_matrix.model.json' `
  -Out   'output/${project_name}/${project_name}_access_right_matrix.xlsx'
powershell -ExecutionPolicy Bypass -File "$s\validate-rightmatrix.ps1" `
  -Xlsx  'output/${project_name}/${project_name}_access_right_matrix.xlsx'
```

## Rules
- The template under `../templates/` is READ-ONLY. Never write back to it.
- Write modified parts UTF-8 without BOM; the module XML-escapes all injected text.
- An empty model field is left as the original placeholder (never invent a value).
- The `.model.json` is an intermediate input; the `.xlsx` is the deliverable.
