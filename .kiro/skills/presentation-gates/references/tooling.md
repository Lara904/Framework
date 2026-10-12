# Tooling — Editing the .pptx

A `.pptx` is a ZIP archive of Open XML parts. Slides are `ppt/slides/slideN.xml`; speaker
notes are `ppt/notesSlides/noteSlideN.xml`; presentation order is in
`ppt/_rels/presentation.xml.rels`. Visible text lives in `<a:t>` elements
(namespace `http://schemas.openxmlformats.org/drawingml/2006/main`).

> **The template is READ-ONLY.** Always copy it first and edit the copy. Never write to the
> bundled template `assets/templates/SIBS_Architecture_Gates_Template_V5.2.pptx`.

## Step 0 — always copy first
```powershell
Copy-Item ".kiro\skills\presentation-gates\assets\templates\SIBS_Architecture_Gates_Template_V5.2.pptx" "<Project>_Architecture_Gates_G2.pptx"
```
Then only ever open/edit the copy.

## Preferred: python-pptx (if Python is available)
If `python` + `python-pptx` are installed, prefer them (cleaner text/table editing).
```python
from pptx import Presentation
prs = Presentation("<Project>_Architecture_Gates_G2.pptx")
slide = prs.slides[8]  # 0-indexed; prs.slides[N-1] == display position N (pos 9 here)
for shape in slide.shapes:
    if shape.has_text_frame:
        for para in shape.text_frame.paragraphs:
            for run in para.runs:
                if "placeholder text" in run.text:
                    run.text = "real value"
prs.save("<Project>_Architecture_Gates_G2.pptx")
```
- Editing `run.text` (not `paragraph.text`) preserves run-level formatting.
- Tables: `shape.has_table` -> `shape.table.cell(r, c).text`.
- Speaker notes: `slide.notes_slide.notes_text_frame.text`.
- To hide a non-applicable slide instead of deleting it, set the slide `show=0` attribute in
  the slide XML (python-pptx has no direct API; use the OpenXML approach below).

## Fallback: bundled PowerShell scripts (this Windows machine has no Python)
On this machine `python`/`py` are not installed. Use the bundled scripts, which are all thin
wrappers over one shared module, `assets/scripts/PptxGates.psm1`. **Do not re-implement zip
extraction, slide-order resolution or `<a:t>` parsing inline** — call the module. It reads the
.pptx as a ZIP *in memory* (no `Expand-Archive`, skips media/fonts, ~25x faster) and centralises
the template guard, XML escaping, the slide map and the detection patterns.

Module functions (import with `Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force`):
- `Get-PptxSlides -Pptx <deck> [-IncludeNotes]` — array of `{Position, Entry, File, Text[, Notes]}`
  in true display order.
- `Set-PptxSlideReplacements -Pptx <copy> -Replacements @(@{Position;Find;Replace}, ...)` —
  apply many edits in a SINGLE zip open; returns per-item `{Applied, Reason}`. Guards the template.
- `Assert-NotTemplate`, `ConvertTo-XmlText`, `Get-SlideMap`, `Get-SlideTitle`, `Get-MissingPatterns`, `Get-MissingMarkers`.
  - `Get-SlideTitle -Text <joined a:t>` derives a short, readable title from a slide's REAL text
    (skips decorative runs); used for the checklist's `Slide N - <title>` labels so they match the
    actual deck instead of the fixed V5.2 titles.

Wrapper scripts (see `assets/scripts/README.md`):
- `inspect-slides.ps1` — dump the visible text of each slide (position -> text).
- `dump-notes.ps1` — dump slide text + speaker notes for the fill-in guidance.
- `replace-text.ps1` — fill fields on a .pptx copy. Single (`-Position/-Find/-Replace`) or
  **batch** (`-Batch fills.csv|fills.json`, all fields in one pass). Handles XML escaping;
  matches escaped form first, then literal.
- `find-missing.ps1` — generate the gates README (by gate, by slide). See
  `gates-readme.md`.

Prefer `-Batch` (or one `Set-PptxSlideReplacements` call) when filling a whole gate: it opens
and rewrites the zip once instead of once per field.

Limitation: PowerPoint may split a single visible string across multiple `<a:t>` runs (when
part of the text has different formatting). If a placeholder is not found even though it is
visible, it is likely split across runs. In that case, open the slide XML and edit the specific
`<a:t>` runs directly, or use python-pptx (which exposes text at the run level) if available.

Slide ordering (IMPORTANT): the true display order is defined by `<p:sldIdLst>` in
`ppt/presentation.xml` (each `<p:sldId r:id="rIdN"/>` resolved via
`ppt/_rels/presentation.xml.rels`), NOT by the raw order of entries in the rels file. For
this template, once resolved, display position N maps cleanly to `ppt/slides/slideN.xml`
(position 1 = `slide1.xml` cover, ... position 75 = `slide75.xml`). The bundled scripts
resolve this correctly, so always trust `inspect-slides.ps1` positions.

## Compatibility: NEVER re-serialize slide XML (avoids "repair on open")
The #1 cause of a deck that PowerPoint offers to "repair" - and that then appears to have
**missing slides** - is re-serializing slide parts. When a slide is loaded into a
`System.Xml.XmlDocument` (or `[xml]`) and saved back, .NET reflows the whole part (e.g. writes
`<... />` with a space instead of the authoring tool's `<.../>`, and may touch namespaces and
the XML declaration). PowerPoint treats the reflowed part as damaged, repairs the file, and can
drop the edited slide in the process. Rules:

- **Do NOT** edit slide XML with `XmlDocument`/`[xml]` + `.Save()`, `Format-Xml`, or any
  pretty-printer. Use **byte-level string replacement** on the raw part text
  (`Set-PptxSlideReplacements` does exactly this; `Get-SlideTextFromXml` only READS).
- Touch only the bytes of the runs that change; every other part (media, fonts, rels, unedited
  slides) stays bit-for-bit identical to the template.

### NEVER use ZipArchiveMode.Update (this is the real repair cause)
`[System.IO.Compression.ZipFile]::Open(path, Update)` rewrites the archive's central directory
in a way that Open Packaging Conventions (OPC) consumers - i.e. PowerPoint - reject as
"contains damaged data", **even if you make no edits at all**. This triggers repair on open and
can drop slides. It also passes naive checks (the parts are still well-formed XML), which is why
it is easy to miss.

Correct approach (implemented by `Set-PptxParts`, used by both edit functions):
- open the source package **read-only** (`OpenRead`);
- create a **brand-new** archive (`ZipArchiveMode.Create`), copying every entry verbatim in its
  original order, swapping bytes only for edited parts;
- replace the original with the new file.

This keeps unedited parts byte-identical AND produces a container OPC opens cleanly. Do not
extract-then-rezip a whole folder either (that reorders parts / changes `[Content_Types].xml`).

## Validate before delivery (mandatory)
Always run `validate-deck.ps1` on the generated copy before handing it over:
```
powershell -ExecutionPolicy Bypass -File assets/scripts/validate-deck.ps1 -Pptx "<deck>.pptx" -Gate <n>
```
It fails (non-zero exit) if:
- the **OPC package fails to open** (`System.IO.Packaging.Package.Open`) - this is the
  authoritative "would PowerPoint repair this?" test and the one that catches
  `ZipArchiveMode.Update` container damage;
- any part is malformed XML;
- slide counts are inconsistent (`Content_Types` overrides vs physical parts vs `sldIdLst`);
- a re-serialization artifact (`" />"`) is present;
- a slide required for the gate is missing.

Module equivalents: `Test-PptxIntegrity` (includes the OPC open test) and `Test-GateSlidesPresent`.
Always run this on the WINDOWS/OPC layer - a deck can have perfectly well-formed XML in every
part and still be "damaged" at the package level.

## File encoding rules (avoid mojibake)
- Save XML as UTF-8 **without BOM**.
- Prefer ASCII in cell text. Avoid em dashes, en dashes, curly quotes and bullet glyphs; they
  frequently render as mojibake when round-tripped. Use `-` and straight quotes.
- Keep the euro symbol only if the template already uses it in that cell; otherwise write `EUR`.
- Do not touch relationship files, media, theme, masters or layouts — only slide `<a:t>` text
  and, when hiding a slide, its `show` attribute.

## Validation after editing
- Run `validate-deck.ps1` (see above) - this is the authoritative check.
- Re-dump the edited slides (`inspect-slides.ps1`) to confirm the placeholder is gone and the
  new value is present.
- Generate the missing-data checklist (`find-missing.ps1`) for remaining gaps.
- If `validate-deck.ps1` reports a `" />"` artifact, the deck was edited with a re-serializing
  method - regenerate it from a fresh template copy using `Set-PptxSlideReplacements`.
