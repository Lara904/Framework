# Access Right Matrix - JSON model schema

The generator `assets/scripts/build-rightmatrix.ps1` copies the bundled reference
template and edits only the target cells / placeholder tokens from a single JSON model,
`${project_name}_access_right_matrix.model.json`. Everything else in the workbook (the
15 predefined technical profiles, the business-profile skeleton, comments, drop-down
lists in the hidden `Parameters` sheet, styles, drawing/logo, print settings) is copied
**verbatim** from the template.

## What the model drives

The template contains two kinds of placeholder that the model resolves:

| Token in template | Where it appears | Model field | Notes |
|---|---|---|---|
| `<PRD>` | Access service codes (`<PRD>X`), LDAP target values (`<PRD>.CICD.DEV`, `<PRD>.BPF.AWS.PRD.ADMIN`, ...), CIQ env codes (`<PRD>00**`...), GitHub rows | `prdCode` | Substituted **everywhere** (23 occurrences). This is the app's PRD code. |
| `<REFLEX_NAME of the DEV Application ...>` | Technical profiles labels (DEV/DEV ADMIN/READ/console DEV) | `reflexNameDev` | Optional. If empty, the descriptive placeholder is kept. |
| `<REFLEX_NAME of the PREPROD/preProduction Application ...>` | OPS / DEVOPS / console PRE labels | `reflexNamePre` | Optional. |
| `<REFLEX_NAME of the PROD/production Application>` | RELEASE / console PROD labels | `reflexNameProd` | Optional. |
| `<Reflex_Application>` | Console service descriptions | (derived) | Uses `reflexNameProd`, else `reflexTechnicalName`. |

The **APPLICATION Information** sheet cells are written directly:

| Cell | Row label (col B) | Model field |
|---|---|---|
| C3 | REFLEX name of the technical production application | `reflexTechnicalName` |
| C4 | REFLEX name of the functional application | `reflexFunctionalName` |
| C5 | DICT | `dict` |
| C6 | PRD Code | `prdCodeField` (normally equals `prdCode`) |
| C7 | Functional description of the application | `functionalDescription` |

## Schema

The values below are a filled **exemple fictif** (replace with the real application's values):

```json
{
  "prdCode": "ABCD",
  "reflexTechnicalName": "MYAPP-T",
  "reflexFunctionalName": "Online My Application",
  "dict": "D3 I3 C3 T2",
  "prdCodeField": "ABCD",
  "functionalDescription": "One-line functional description of the application.",
  "reflexNameDev": "",
  "reflexNamePre": "",
  "reflexNameProd": ""
}
```

## Rules

- **Never invent a value.** Any field left as `""` is NOT substituted: the original
  template placeholder stays visible in the deliverable, and the missing value must be
  listed as an Open question in the companion README until the user provides it.
- `prdCode` and `prdCodeField` are normally identical; keep both in sync.
- `dict` should match the project DICT deliverable (`*_DICT_README.md`) - format like
  `D3 I3 C3 T2` (Disponibilite / Integrite / Confidentialite / Tracabilite).
- The model does NOT decide which profiles apply. The 15 technical profiles are a
  fixed catalogue in the template; profile applicability / scoping is documented in the
  companion README, not by removing columns.
- Values are XML-escaped by the generator; write plain UTF-8 text in the model.
