# Output Format

## File output
Three files, all in the per-project output folder **`output/${project_name}/`** (see the
`output-convention.md` steering - single source of truth for output location; never in the scratch
area `.kiro/.temp_ai/`):
- `<project>_functional_architecture_diagram.drawio` - the diagram.
- `<project>_functional_architecture_README.md` - the functional README (see `readme-template.md`).
- `<project>_functional_architecture_document.docx` - the Functional Architecture Dossier (FAD),
  a single Word file following the DP-MD76-EN template (see `fad-document.md`). Its editable model
  `<project>_functional_architecture_document.model.json` may be kept next to it.

The `.drawio` is a valid draw.io XML file with an `<mxfile pages="N">` wrapper; each page is a
`<diagram>` with an `<mxGraphModel>`. Page 1 is `Versions`, page 2 is the functional diagram.
UTF-8 without BOM, ASCII-only cell text, no external image references.

## Versions Page (predictable, table-based)
The FIRST page MUST be named `Versions` and present the history as a table (not free text), so
the format is stable across regenerations.

### Structure
- Title cell above the table: `<Solution> - Functional Architecture (Versions)`, style
  `text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontStyle=1`.
- Header row, exactly four columns in this order: **Version**, **Date**, **Author**, **Description**.
- Header cell style: `text;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;align=center;verticalAlign=middle;fontStyle=1`.
- One data row per version, most recent LAST (append new rows; never rewrite history).
- Data cell style: `text;html=1;fillColor=#ffffff;strokeColor=#6c8ebf;align=center;verticalAlign=middle`
  (Description cell uses `align=left;whiteSpace=wrap;spacingLeft=6`).

### Column geometry (keep consistent)
| Column | x | width |
|--------|-----|-------|
| Version | 40 | 90 |
| Date | 130 | 120 |
| Author | 250 | 130 |
| Description | 380 | 420 |

- Header row `y=90`, `height=30`. Data rows `height=40`, stacked (first `y=120`, next `y=160`, ...).
- Date format `YYYY-MM-DD`. Descriptions are concise, ASCII-only (no em dashes / bullets).

### Reference skeleton
```xml
<mxCell id="vtitle" value="Solution - Functional Architecture (Versions)" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;fontSize=18;fontStyle=1" parent="v1" vertex="1">
  <mxGeometry x="40" y="40" width="560" height="30" as="geometry"/>
</mxCell>
<mxCell id="vth0" value="Version" style="text;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;align=center;verticalAlign=middle;fontStyle=1" parent="v1" vertex="1">
  <mxGeometry x="40" y="90" width="90" height="30" as="geometry"/>
</mxCell>
<!-- vth1 Date (x=130,w=120), vth2 Author (x=250,w=130), vth3 Description (x=380,w=420) -->
<mxCell id="vr0c0" value="1.0" style="text;html=1;fillColor=#ffffff;strokeColor=#6c8ebf;align=center;verticalAlign=middle" parent="v1" vertex="1">
  <mxGeometry x="40" y="120" width="90" height="40" as="geometry"/>
</mxCell>
<!-- vr0c1 Date, vr0c2 Author, vr0c3 Description (align=left;whiteSpace=wrap;spacingLeft=6) -->
```

On every modification, append a new Versions row with an incremented version and a one-line
description of what changed (e.g. "Added SFS pricing engine and its flow from lead management").
