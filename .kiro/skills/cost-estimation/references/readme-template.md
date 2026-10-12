# Costs README - format and JSON model

The costs deliverable is a markdown README, generated from a JSON model so regeneration and
versioning are trivial (skill-authoring rule 5). Both live in the per-project output folder
`output/${project_name}/` (see the `output-convention.md` steering - single source of truth for
output location):
- **`${project_name}_costs_model.json`** - the machine-readable source of truth (values + assumptions).
- **`${project_name}_costs_README.md`** - the rendered, human-readable tracker (what the user reads).

`assets/scripts/costs-readme.ps1` renders the README from the model, computes the column totals,
and lists everything still missing (any `null`). Never hand-edit the README's computed parts;
edit the JSON model and re-render.

## JSON model schema
```json
{
  "project": "${project_name}",
  "gate": "3",
  "startQuarter": "Q1",
  "currency": "EUR",
  "fx": { "usdToEur": null, "asOf": null },
  "cloud": {
    "calculatorLink": null,
    "services": [
      { "region": "EU (Paris)", "service": "Amazon S3", "monthly": null, "annual": null, "currency": "USD", "config": "TBD - stored GB, requests, DTO" }
    ]
  },
  "it": {
    "internalDailyRate": null,
    "supplierDailyRate": null,
    "items": [
      { "label": "Development + unit tests", "internalJH": null, "outsourcedJH": null },
      { "label": "Project piloting",          "internalJH": null, "outsourcedJH": null },
      { "label": "Delivery (analysis/design/test/UAT/go-live/support)", "internalJH": null, "outsourcedJH": null }
    ],
    "backlogLink": null
  },
  "investments": {
    "hardware": [],
    "licenses": []
  },
  "global": {
    "IT":          { "Q1": null, "Q2": null, "Q3": null, "Q4": null, "Y2": null },
    "Cloud":       { "Q1": null, "Q2": null, "Q3": null, "Q4": null, "Y2": null },
    "Investments": { "Q1": null, "Q2": null, "Q3": null, "Q4": null, "Y2": null }
  }
}
```
- All monetary values in the `global` grid are in **k€**. `null` = not yet known (rendered `TBD`).
- `cloud.services[].monthly/annual` are in each row's `currency` (usually USD from the Calculator).
- The script computes the **Total** row (sum of IT + Cloud + Investments per column).

## README structure (rendered)
```
# Costs README - <project>
Source model: <project>_costs_model.json   Generated: <date>   Gate: <n>   Currency: k€ (FX ...)

## 1. Global view (k€) - Year 1 by quarter, Year 2 recurrent
| Cost type | Q1 | Q2 | Q3 | Q4 | Y2 recurrent |
| IT costs (incl. outsourcing) | ... |
| Cloud consumption | ... |
| Investments (hardware + license) | ... |
| **Total** | ... |
-> feeds deck slide 59 (and 22)

## 2. Cloud - AWS Calculator detail (slide 58)
Shared Calculator link: <link | TBD>
| Region | Service | Monthly | Annual | Currency | Configuration summary |
...
-> feeds deck slide 58 (and 23)

## 3. IT costs (development / piloting / delivery, internal + outsourcing)
Daily rates: internal <..> k€/JH, supplier <..> k€/JH   Backlog: <link | TBD>
| Item | Internal JH | Outsourced JH | k€ |
...

## 4. Investments
Hardware: ...    Software licenses: ...

## 5. Open questions / Missing
- [ ] <every null / TBD, as an actionable question>

---
Totals: Year-1 = <..> k€ | Year-2 recurrent = <..> k€ | Open items: <n>
```

## Persistence
Values live in the JSON model, so they survive regeneration. The "Open questions / Missing"
section is derived from the `null`s on each run, so it always reflects the current gaps. Update the
JSON as the user provides figures; never overwrite a user-set value with a guess.
