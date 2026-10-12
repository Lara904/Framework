# Output Format

## Six deliverables (always produce all six)
All six share the naming convention `${project_name}_technical_architecture_<kind>`:
1. `<project>_technical_architecture_diagram.drawio` - the technical AWS diagram, with a
   **Versions** page first, then the **Architecture** page(s).
2. `<project>_technical_architecture_dataflow.drawio` - the **Data Flow Diagram** (a SEPARATE
   file): a **Versions** page first, then a **Data Flow** page showing inter/intra-application
   flows with C1/C2/C3/C4 data confidentiality, a DCP flag and TLS/mTLS transport (see
   `data-flow-diagram.md`).
3. `<project>_technical_architecture_dataflow_mapping.xlsx` - the **Data Flow Mapping** workbook (a
   SEPARATE Excel file): the official Stellantis flow inventory (Cover + Functional Flow Pattern +
   Technical Flow Pattern, C1-C4 + DCP), generated with `build-flowmapping.ps1` and validated with
   `validate-flowmapping.ps1` (see `data-flow-mapping.md`).
4. `<project>_technical_architecture_README.md` - the technical README (see `readme-template.md`).
5. `<project>_technical_architecture_document.docx` - the single-file Technical Architecture Document
   (DAT) (see `dat-document.md`), generated with the bundled PowerShell scripts and validated with
   `validate-dat.ps1`.
6. `<project>_technical_architecture_frameworks.drawio` - the **Frameworks diagram** (a SEPARATE
   file): the technical stack (products/frameworks/runtime/OS with versions) as a layered
   "building blocks" view, a **Versions** page first then a **Frameworks** page. Built from
   `assets/templates/FMK_Diagram_template.drawio` (see `frameworks-diagram.md`).

All six go in the per-project output folder **`output/${project_name}/`** (see the
`output-convention.md` steering - single source of truth for output location). The architecture
diagram, the dataflow diagram, the dataflow mapping, the README, the DAT and the Frameworks
diagram must agree (same components, flows, patterns, C1-C4 criticalities, DCP flags and stack
versions). The optional intermediate models
`<project>_technical_architecture_document.model.json` and
`<project>_technical_architecture_dataflow_mapping.model.json` may be kept in the same folder for
future revisions.

## Versions Page Format (predictable, table-based)

The first page of every generated diagram MUST be named `Versions` and MUST present the version history as a **table**, exactly like the generated diagram. Do NOT use a free-form text block — the format must be predictable and stable across regenerations.

### Structure
- A title cell above the table: `<App Name> - Architecture (Versions)`, style `text;html=1;strokeColor=none;fillColor=none;fontSize=18;fontStyle=1`.
- A header row with exactly four columns, in this order:
  1. **Version**
  2. **Date**
  3. **Author**
  4. **Description**
- Header cells style: `text;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;align=center;verticalAlign=middle;fontStyle=1`.
- One data row per version, most recent LAST (append new rows below existing ones — never rewrite history).
- Data cells style: `text;html=1;fillColor=#ffffff;strokeColor=#6c8ebf;align=center;verticalAlign=middle` (Description cell uses `align=left;whiteSpace=wrap;spacingLeft=6`).

### Column geometry (keep consistent)
| Column | x | width |
|--------|-----|-------|
| Version | 40 | 90 |
| Date | 130 | 120 |
| Author | 250 | 130 |
| Description | 380 | 420 |

- Header row: `y=90`, `height=30`. Each data row: `height=40`, stacked below (first row `y=120`, next `y=160`, etc.).
- Date format: `YYYY-MM-DD`.

### Content rules
- Each row records: version number (e.g., `1.0`, `0.2`), date, author, and a concise ASCII-only description of the change (no em dashes, no bullets — see File Encoding rules in `generation-process.md`).
- On every modification, **append a new row** with an incremented version and a one-line description of what changed. Do not edit or delete previous rows.

### Reference skeleton
```xml
<mxCell id="vtitle" value="App Name - Architecture (Versions)" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;fontSize=18;fontStyle=1" parent="v1" vertex="1">
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

## File Output

The final output must be saved to the per-project output folder **`output/${project_name}/`** (see
the `output-convention.md` steering; not inside `sources/`, `.kiro/`, or the scratch area).

- File name: `${project_name}_technical_architecture_diagram.drawio`
- Location: `output/${project_name}/`
- Format: valid draw.io XML file (`.drawio`) with:
  - A `Versions` page (table format, see above) followed by the architecture page(s)
  - Proper `<mxfile>` wrapper with `pages="N"`
  - Each page in a `<diagram>` element with a `<mxGraphModel>` containing all cells
  - All geometry validated per `layout-validation.md`
  - Written as UTF-8 without BOM, ASCII-only cell text, logos embedded as base64 (no external references)

Additionally, in the same `output/${project_name}/` folder:
- `<project_name>_technical_architecture_dataflow.drawio` - the separate Data Flow Diagram
  (`Versions` page first, then a `Data Flow` page). Same `.drawio` format, encoding and geometry
  rules as above; `<mxfile pages="2">`. See `data-flow-diagram.md`.
- `<project_name>_technical_architecture_dataflow_mapping.xlsx` - the separate Data Flow Mapping
  workbook (Cover + Functional Flow Pattern + Technical Flow Pattern). Built with
  `assets/scripts/build-flowmapping.ps1` and validated with `assets/scripts/validate-flowmapping.ps1`.
  See `data-flow-mapping.md`.
- `<project_name>_technical_architecture_README.md` - technical README (see `readme-template.md`).
- `<project_name>_technical_architecture_document.docx` - single-file DAT (see `dat-document.md`), built with
  `assets/scripts/build-dat.ps1` and validated with `assets/scripts/validate-dat.ps1`.
- `<project_name>_technical_architecture_frameworks.drawio` - the separate Frameworks diagram
  (`Versions` page first, then a `Frameworks` page with the layered technical stack). Same
  `.drawio` format, encoding and geometry rules as above; `<mxfile pages="2">`. Built from
  `assets/templates/FMK_Diagram_template.drawio`. See `frameworks-diagram.md`.
