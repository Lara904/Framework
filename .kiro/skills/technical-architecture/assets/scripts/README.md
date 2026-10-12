# DAT and Flow Mapping generation scripts

These scripts generate two deliverables, without Python or Microsoft Office:
- the single-file **Technical Architecture Document (DAT)** as a valid Word `.docx`, and
- the **Data Flow Mapping** workbook as a valid Excel `.xlsx`.

They mirror the OPC-safe philosophy used by the `presentation-gates` skill (never use
`ZipArchiveMode.Update`; build a brand-new archive with `ZipArchiveMode.Create`, UTF-8 without
BOM).

## Files (DAT)
- `DatDocx.psm1` - the module. Builds a valid `.docx` OPC package from a JSON model.
  Public functions: `New-DatDocx -Model <obj|json> -OutFile <path>`, `ConvertTo-XmlText`.
- `build-dat.ps1` - thin wrapper: reads a JSON model file and writes the `.docx`.
- `validate-dat.ps1` - authoritative check that the `.docx` opens as an OPC package
  (the "would Word repair this?" test) and that every part is well-formed XML.

## Files (Data Flow Mapping)
- `FlowMappingXlsx.psm1` - the module. Builds a valid `.xlsx` OPC package (Cover +
  Functional Flow Pattern + Technical Flow Pattern sheets) from a JSON model.
  Public function: `New-FlowMappingXlsx -Model <obj|json> -OutFile <path>`.
- `build-flowmapping.ps1` - thin wrapper: reads a JSON model file and writes the `.xlsx`.
- `validate-flowmapping.ps1` - authoritative check that the `.xlsx` opens as an OPC package
  (the "would Excel repair this?" test) and that every part is well-formed XML.

### Usage (Data Flow Mapping)
```powershell
# generate the flow mapping from a JSON model (schema in references/data-flow-mapping.md)
powershell -ExecutionPolicy Bypass -File .kiro/skills/technical-architecture/assets/scripts/build-flowmapping.ps1 `
  -Model "<project>_technical_architecture_dataflow_mapping.model.json" -Out "<project>_technical_architecture_dataflow_mapping.xlsx"

# validate before delivery (must exit 0)
powershell -ExecutionPolicy Bypass -File .kiro/skills/technical-architecture/assets/scripts/validate-flowmapping.ps1 `
  -Xlsx "<project>_technical_architecture_dataflow_mapping.xlsx"
```

## Usage
```powershell
# 1) generate the DAT from a JSON model (see references/dat-document.md for the schema)
powershell -ExecutionPolicy Bypass -File .kiro/skills/technical-architecture/assets/scripts/build-dat.ps1 `
  -Model "<project>_technical_architecture_document.model.json" -Out "<project>_technical_architecture_document.docx"

# 2) validate before delivery (must exit 0)
powershell -ExecutionPolicy Bypass -File .kiro/skills/technical-architecture/assets/scripts/validate-dat.ps1 `
  -Docx "<project>_technical_architecture_document.docx"
```

## JSON model (summary)
See `references/dat-document.md` for the full schema and the recommended DAT outline.
Minimal shape:
```json
{
  "title": "Technical Architecture Document",
  "subtitle": "<App name>",
  "author": "<name>",
  "date": "YYYY-MM-DD",
  "revisions": [ { "date": "YYYY-MM-DD", "revision": "1.0", "object": "...", "author": "..." } ],
  "body": [
    { "type": "h1", "text": "Introduction" },
    { "type": "p",  "text": "..." },
    { "type": "bullets", "items": ["...", "..."] },
    { "type": "table", "header": ["Col1", "Col2"], "rows": [["a", "b"]] },
    { "type": "pagebreak" }
  ]
}
```
Supported `body` node `type` values: `h1`, `h2`, `h3`, `h4`, `p`, `bullets`, `table`, `pagebreak`.

## Rules
- The DAT is a SINGLE `.docx` file (merge the main architecture document and the AWS complement
  into one).
- The DAT is written in **English**, like all deliverables.
- The generator is self-contained: no external template or example file is required.
- Always run `validate-dat.ps1` before handing the document over.
- Do not re-serialize an existing `.docx` with `[xml].Save()`; regenerate from the JSON model.
