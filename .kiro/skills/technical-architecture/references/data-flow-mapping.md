# Data Flow Mapping (Excel .xlsx deliverable)

In addition to the data flow *diagram* (`.drawio`), this skill produces the **Data Flow Mapping**
as an Excel workbook (`.xlsx`) that reproduces the official Stellantis **Data flow mapping**
template (built from ARIS, the CMDB and the GDPR files). It is the tabular, exhaustive inventory
of the application's flows; the DFD is its graphical view and the DAT Flows Matrix is its
synthetic extract - all three MUST stay consistent (same flows, same C1/C2/C3/C4 values, same DCP
flags).

The workbook structure and columns are **fully specified below and reproduced by the bundled
generator** (`assets/scripts/FlowMappingXlsx.psm1`), so the skill is self-contained: the official
`Data flow mapping exemple.xlsx` is provenance only and is NOT required as an input. When a
project already has a real Data flow mapping, reuse its values; otherwise generate from the JSON
model.

File name: `<project>_technical_architecture_dataflow_mapping.xlsx` in **`output/${project_name}/`**
(see the `output-convention.md` steering).

## How it is generated (no Python / Office on this machine)
Use the bundled PowerShell generator (see `assets/scripts/README.md`):
1. Build a JSON **model** describing the mapping (schema below).
2. `build-flowmapping.ps1 -Model <model.json> -Out "<project>_technical_architecture_dataflow_mapping.xlsx"`.
3. `validate-flowmapping.ps1 -Xlsx "<...>.xlsx"` must exit 0 (OPC opens, XML well-formed).

The generator writes valid Open XML parts (workbook, worksheets, styles, rels, docProps) and zips
them OPC-safely (`ZipArchiveMode.Create`, UTF-8 without BOM). Excel opens the result without
"repair". Cell text is stored as inline strings (no sharedStrings table needed).

## Workbook structure (official template)
Three sheets, in this order (sheet 1 is named exactly **"Cover sheet"**, mirroring the reference):
1. **Cover sheet** - Purpose, Objective, Sources (a table URL | Type | Extraction Date | Sheet for
   CMDB / ARIS / GDPR), Assumptions & Rules (e.g. the DCP derivation rule), Method (the DCP-review
   reconciliation rules between GDPR and ARIS), and a Version table (Version | Type | Updated Date |
   Updated by | Owners | Update Comments).
2. **Functional Flow Pattern** - columns: Functional flow name | Type of treatment |
   Source Service/App | Destination Service/App | Frequency | Data confidentiality (C1/C2/C3/C4) |
   DCP (Yes/No) | Party (Yes/No) | Party identification (Yes/No) | Banking information (Yes/No) |
   Sensitive personnal data (Yes/No) | Type of data with DCP.
3. **Technical Flow Pattern** - columns: Functional flow name | Technical flow name | Type of flow |
   Source Service/App | Hostname Source | Destination Service/App | Hostname Destination | Frequency |
   Data confidentiality (C1/C2/C3/C4) | DCP (Yes/No) | Port | Protocol | Token supplier if API |
   Exposition End Point | APIC Product.

The bundled anonymized template `assets/templates/Data_flow_mapping_template.xlsx` reproduces this
structure (project-specific and other-project content removed; the column layout, DCP-derivation
rules and Method are kept). It is provenance/reference only - the generator does not read it.

## Classification (same scale as the DFD)
- **Data confidentiality**: official Stellantis **C1/C2/C3/C4** scale (C1 public, C2
  internal/restricted, C3 confidential/personal-GDPR, C4 secret/highly sensitive). Use `C?` when a
  value is not yet confirmed.
- **DCP** (Donnee a Caractere Personnel): personal-data flag `Yes`/`No`. Derivation rule from the
  official mapping: if both endpoints carry personal data the flow is DCP=Yes; if either does not,
  DCP=No; if the source is DCP=Yes and the destination is missing, DCP=Yes. When it cannot be
  settled, mark it "to be confirmed by an expert" - never invent it.

## JSON model schema
```json
{
  "title": "Data flow mapping",
  "subtitle": "<App name>",
  "author": "<name>",
  "date": "YYYY-MM-DD",
  "purpose": "The purpose of this spreadsheet is to give a list of dependencies between the applications of our Information System.",
  "objective": "The objective is to provide the flow map with the DCP indicator, built from the dependencies in our CMDB.",
  "sources": [
    { "type": "CMDB", "sheet": "Dependencies", "extractionDate": "YYYY-MM-DD", "url": "..." },
    { "type": "ARIS", "sheet": "Aris Repository", "extractionDate": "YYYY-MM-DD", "url": "..." },
    { "type": "GDPR", "sheet": "GDPR_global", "extractionDate": "YYYY-MM-DD", "url": "..." }
  ],
  "assumptions": [
    "By default the applications related to wholesale activity are tagged DCP=No.",
    "If the two apps carry DCP then the flow carries DCP; if one does not, the flow does not.",
    "If DCP is Yes for the source app and DCP for the destination is missing, then the flow is DCP=Yes."
  ],
  "method": [
    "If DCP=Yes in GDPR files and DCP=Yes in ARIS file then DCP reviewed = Yes.",
    "If DCP in GDPR differs from DCP in ARIS then DCP reviewed = 'to be confirmed by an expert'.",
    "If DCP in GDPR is missing then DCP reviewed = DCP in ARIS (and vice-versa).",
    "If both are missing then DCP reviewed = 'to be confirmed by an expert'."
  ],
  "versions": [
    { "version": "0.1", "type": "flow map", "updatedDate": "YYYY-MM-DD", "updatedBy": "<name>", "owners": "", "comments": "" }
  ],
  "functionalFlows": [
    { "name": "", "treatment": "", "source": "", "destination": "", "frequency": "",
      "confidentiality": "C3", "dcp": "No", "party": "No", "partyIdentification": "No",
      "bankingInformation": "No", "sensitiveData": "No", "dataType": "" }
  ],
  "technicalFlows": [
    { "functionalName": "", "name": "", "type": "", "source": "", "hostnameSource": "",
      "destination": "", "hostnameDestination": "", "frequency": "",
      "confidentiality": "C1", "dcp": "No", "port": "443", "protocol": "https",
      "tokenSupplier": "", "endpoint": "", "apicProduct": "" }
  ]
}
```

### Rules
- `title`, `author`, `date` are mandatory. `purpose`, `objective`, `sources`, `assumptions`,
  `method` and `versions` are recommended (they populate the Cover sheet like the official template).
- The functional flows carry the DCP breakdown (`dcp`, `party`, `partyIdentification`,
  `bankingInformation`, `sensitiveData`) as Yes/No, plus a free-text `dataType`.
- Every flow row uses the C1/C2/C3/C4 scale and a Yes/No DCP flag; unknowns are `C?` / "TBC".
- Keep the flows identical to the DFD (`data-flow-diagram.md`) and the DAT Flows Matrix.
- Save the model as UTF-8. Write the content in English.
- Reuse an existing official Data flow mapping's values when the project already has one; do not
  re-derive or invent flows.

## Output
- File name: `<project>_technical_architecture_dataflow_mapping.xlsx` in **`output/${project_name}/`**
  (next to the `.drawio` files, the README and the DAT - see the `output-convention.md` steering).
- The intermediate `<project>_technical_architecture_dataflow_mapping.model.json` may be kept next
  to the `.xlsx` (useful to regenerate / version the mapping) or removed.
- Always validate with `validate-flowmapping.ps1` before delivery.
