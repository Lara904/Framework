# FAD (Functional Architecture Dossier) generation scripts

These scripts generate the single-file **Functional Architecture Dossier (FAD)** as a
valid Word `.docx`, without Python or Microsoft Office. The FAD follows the official
Stellantis template **DP-MD76-EN - Functional Architecture Dossier**.

They mirror the OPC-safe philosophy used by the `technical-architecture` (DAT) and
`presentation-gates` skills (never use `ZipArchiveMode.Update`; build a brand-new
archive with `ZipArchiveMode.Create`, UTF-8 without BOM).

## Files
- `FadDocx.psm1` - the module. **Clones the bundled template**
  `../templates/Functional_Architecture_Dossier_template.docx` and injects the body, so the
  output keeps the template's real look (Stellantis logo header, Times New Roman `Titre1..Titre4`
  headings with automatic numbering, framed title `Encadr`, theme, footers). It copies every
  template part verbatim and only regenerates `word/document.xml`'s `<w:body>` from the JSON model.
  Public functions: `New-FadDocx -Model <obj|json> -OutFile <path> [-TemplatePath <path>]`,
  `ConvertTo-XmlText`. Front-of-document: framed cover ("Functional Architecture Dossier"),
  synthesis block (Object of the document / Audience / Links toward related documentation /
  Revisions index), TOC field, then the numbered body (1, 1.1, 1.1.1 ...).
- `build-fad.ps1` - thin wrapper: reads a JSON model file and writes the `.docx`.
- `validate-fad.ps1` - authoritative check that the `.docx` opens as an OPC package
  (the "would Word repair this?" test) and that every part is well-formed XML.

## Usage
```powershell
# 1) generate the FAD from a JSON model (see references/fad-document.md for the schema)
powershell -ExecutionPolicy Bypass -File .kiro/skills/functional-architecture/assets/scripts/build-fad.ps1 `
  -Model "<project>_functional_architecture_document.model.json" -Out "<project>_functional_architecture_document.docx"

# 2) validate before delivery (must exit 0)
powershell -ExecutionPolicy Bypass -File .kiro/skills/functional-architecture/assets/scripts/validate-fad.ps1 `
  -Docx "<project>_functional_architecture_document.docx"
```

## JSON model (summary)
See `references/fad-document.md` for the full schema and the mandatory FAD outline.
Minimal shape:
```json
{
  "title": "Functional Architecture Dossier",
  "subtitle": "<Project name>",
  "author": "<name>",
  "date": "YYYY-MM-DD",
  "version": "1.0",
  "objectOfDocument": "This document presents the functional architecture ...",
  "audience": "TCC, functional architects, project team",
  "relatedDocuments": [ { "title": "Validated statement of needs", "reference": "..." } ],
  "revisions": [ { "version": "1.0", "date": "YYYY-MM-DD", "chapters": "All", "motives": "Initial creation", "authors": "<name>" } ],
  "body": [
    { "type": "h1", "text": "The scope of the transformation project" },
    { "type": "p",  "text": "..." },
    { "type": "bullets", "items": ["...", "..."] },
    { "type": "table", "header": ["Col1", "Col2"], "rows": [["a", "b"]] },
    { "type": "pagebreak" }
  ]
}
```
Supported `body` node `type` values: `h1`, `h2`, `h3`, `h4`, `p`, `bullets`, `table`, `pagebreak`.

## Invocation (IMPORTANT)
Call `build-fad.ps1` and `validate-fad.ps1` **directly** with `-File` and their arguments, as
shown above. Do **NOT** wrap them in a `_run.ps1` helper that re-imports `FadDocx.psm1` via a
relative path: resolving the module from inside a wrapper can fail **silently** (exit 0, no file
produced). `build-fad.ps1` now checks that the `.docx` was actually written and throws otherwise,
but the safe habit is to invoke these two scripts directly and confirm `validate-fad.ps1` prints
`FAD VALIDATION OK` (exit 0).

## Rules
- The FAD is a SINGLE `.docx` file that reproduces the DP-MD76-EN template outline (see
  `references/fad-document.md`). Keep the headings even when a section is light (mark
  "Not applicable" / "TBC" rather than dropping a heading).
- The FAD is written in **English**, like all deliverables.
- The generator clones the bundled template `assets/templates/Functional_Architecture_Dossier_template.docx`
  at runtime (it is bundled inside the skill, so the skill remains self-contained - no project file
  is needed). Treat the bundled template as **read-only** source of truth; never modify it.
- Always run `validate-fad.ps1` before handing the document over.
- Do not re-serialize an existing `.docx` with `[xml].Save()`; regenerate from the JSON model.
