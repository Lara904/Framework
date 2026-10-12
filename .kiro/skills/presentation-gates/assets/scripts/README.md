# Helper scripts

PowerShell helpers for editing the Architecture Gates deck on machines without Python /
python-pptx (as on this Windows machine). See `../../references/tooling.md` for the full
workflow. All scripts treat the template as read-only.

## Shared module (the engine)
`PptxGates.psm1` is the single source of truth for all low-level actions. The four scripts
below are thin wrappers over it, so the logic is factored in one place:
- reads .pptx as a ZIP **in memory** (no `Expand-Archive`, skips media/fonts) - ~25x faster;
- resolves the true slide display order (`sldIdLst` -> r:id -> rels; position N == slideN.xml);
- extracts `<a:t>` text (and speaker notes);
- the read-only template guard and XML entity escaping;
- the slide map (position -> title + gate tags) and the missing-data detection patterns.

Exported functions (import with
`Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force`):
`Get-PptxSlides` (`-IncludeNotes`), `Get-PptxSlideRuns`, `Set-PptxSlideReplacements`,
`Set-PptxSlideRuns`, `Add-PptxImageToSlide`, `Assert-NotTemplate`, `ConvertTo-XmlText`,
`Set-PptxSlideBanner`, `Set-PptxHyperlink`, `Get-SyncedSharePointUrl`, `Get-SlideMap`,
`Get-MissingPatterns`, `Get-MissingMarkers`, `Test-PptxIntegrity`, `Test-GateSlidesPresent`.

Inserting an image: `Add-PptxImageToSlide -Pptx <copy> -Position <n> -ImagePath <png/jpeg>
-EmuX -EmuY -EmuCx -EmuCy [-Name]` adds the media part + slide relationship + `<p:pic>` shape
via the same OPC-safe Create rewrite. Slide canvas is 9144000 x 5143500 EMU (16:9). PNG/JPEG
content-types are already declared in this template. A `.drawio` file is NOT an image - export
it to PNG first, then insert the PNG.

Replacing an image: `Remove-PptxImagesFromSlide -Pptx <copy> -Position <n>` strips the slide's
TOP-LEVEL `<p:pic>` shapes, their image relationships, and any media part no longer referenced by
another slide. Then call `Add-PptxImageToSlide` again with the new picture. **It deliberately does
NOT touch pictures inside an OLE object's `<mc:AlternateContent>` fallback** (embedded OLE objects
render as `<p:oleObj>` + a preview `<p:pic>`): stripping that fallback picture leaves a
schema-invalid `<p:oleObj>` and PowerPoint refuses to open the file (the package/container still
looks valid). If you must remove such an OLE icon, delete the whole `<p:graphicFrame>` and its
orphaned relationships instead. `Test-PptxIntegrity` now flags an OLE fallback missing its picture
(check 3b).

Removing the yellow highlight: `Remove-PptxHighlight -Pptx <copy> -Positions 11,12,15` strips
`<a:highlight>` from those slides. Replacing a run's text keeps its yellow highlight, so run
this on validated slides so no template highlight remains. It works **run by run** and
AUTOMATICALLY SKIPS light/white-colored text runs (theme `bg1`/`bg2`/`lt1`/`lt2`, or near-white
`srgbClr` >= 220/220/220): those labels use the highlight for contrast, so removing it would
leave them white-on-white and illegible (as happened on slide 10). Pass `-Force` to override and
strip highlight from light text too. The function reports removed vs. skipped counts per slide.

Deriving a SharePoint URL WITHOUT asking the user: `Get-SyncedSharePointUrl -Path <file>` returns
the web URL of a local file that sits inside a OneDrive-synced document library. Windows OneDrive
records each synced library's local mount point and its URL namespace under
`HKCU:\Software\SyncEngines\Providers\OneDrive` (MountPoint -> UrlNamespace); the helper picks the
most specific mount that prefixes the file path and appends the URL-encoded relative path. Returns
`$null` if the file is purely local (not synced) - only then ask the user for the link.

External hyperlinks (SharePoint): `Set-PptxHyperlink -Pptx <copy> -Links @(@{Position=40;RunIndex=2;Url=(Get-SyncedSharePointUrl '.\DAT.docx')})`
makes a text run clickable by adding an external relationship (`TargetMode="External"`) to the
slide `.rels` and an `<a:hlinkClick>` into the run's `<a:rPr>`. Use it to attach the SharePoint
URL of a deliverable to its reference run (the filename/"Link to ..." text). Idempotent (retargets
an existing link); pass `@{...;Clear=$true}` to remove a link. Batch many links in one call; run
indices are the 0-based `Get-PptxSlideRuns` indices. OPC-safe (Create rewrite).

Status corner banners: `Set-PptxSlideBanner -Pptx <copy> -Positions 11,12 -Status validate|complete|clear`
adds a colour-coded corner band (a `<p:sp>` named `GateStatusBanner`) top-right of each slide to
flag review state at a glance: `validate` = ORANGE "TO VALIDATE" (content filled, awaiting
stakeholder sign-off), `complete` = RED "TO COMPLETE" (data still missing / TODO), `clear` =
remove the banner (slide finalised). It is IDEMPOTENT - it strips any prior `GateStatusBanner` it
added before adding the new one - so re-running just updates the colour/label. Optional `-Label`
overrides the default text. OPC-safe (Create rewrite; never re-serializes slide XML).

Hiding non-applicable slides: `Set-PptxSlideVisibility -Pptx <copy> -Positions 33,34,35
-Visible $false` sets `show="0"` on the `<p:sld>` root. The slides stay in the file (positions,
slide map and run indices UNCHANGED) but are skipped in the slideshow / gate review - this is
the template's "remove or hide non-applicable sections" behaviour. Prefer this over physically
deleting slides, which would renumber positions and break the slide map / checklist. `Get-PptxSlides`
exposes a `Visible` flag, and `find-missing.ps1` automatically excludes hidden slides (and lists
them under a "Hidden (non-applicable)" note).

Compatibility rules (important - two distinct traps that both cause "repair on open"):
1. Editing is **byte-level string replacement** on raw part text. Never re-serialize slide XML
   (`XmlDocument.Save`/`[xml]`) - it reflows the part (encoding decl, `" />"`) and triggers repair.
2. Writing back uses a **Create-mode package rewrite** (`Set-PptxParts`): open source read-only,
   create a NEW zip copying entries verbatim, swap only edited parts. NEVER
   `ZipArchiveMode.Update` - it rewrites the central directory so PowerPoint reports "damaged
   data" and repairs, EVEN WITH NO EDITS. `Test-PptxIntegrity` opens the file via the OPC API
   (`System.IO.Packaging`) to catch exactly this.

You can call the module directly for ad-hoc work, e.g.:
```powershell
Import-Module .\PptxGates.psm1 -Force
Get-PptxSlides -Pptx deck.pptx | Where-Object Text -match 'SLA'
```

## Wrappers
- `inspect-slides.ps1 -Pptx <deck.pptx> [-MaxChars 300]`
  Dump the visible text of each slide as `POS <n> (slideX.xml): <text>`.

- `dump-notes.ps1 -Pptx <deck.pptx> [-Out slides_dump.txt]`
  Dump slide text + speaker notes per slide (the fill-in guidance) to a text file.

- `replace-text.ps1 -Pptx <copy.pptx> ...`  (refuses to run against the template)
  - Single: `-Position <n> -Find "<placeholder>" -Replace "<value>"`
  - Batch:  `-Batch <fills.csv|fills.json>` - many fields applied in ONE zip open.
    CSV columns `Position,Find,Replace`; JSON array of `{Position,Find,Replace}`.
  Handles XML entity escaping (`&`, `<`, `>`); matches escaped form first, then literal.

- `find-missing.ps1 -Pptx <deck.pptx> [-Gate all|1|2|3|4] [-Out checklist.md]`
  Generate the gates README: empty fields and leftover guidance, grouped by gate
  and ordered by slide. See `../../references/gates-readme.md`.

- `set-banners.ps1 -Pptx <copy.pptx> ...`  (refuses to run against the template)
  Add the colour-coded status corner banners.
  - Explicit: `-Status validate|complete|clear -Positions 11,12,15 [-Label "..."]`
  - Auto:     `-Auto [-Gate all|1|2|3|4] [-Validated 11,12,14] [-MinText 200]`
    Scans in-scope visible slides: RED "TO COMPLETE" when the missing-data heuristic finds
    leftover placeholders OR the slide is an empty stub (visible text < `-MinText` chars);
    ORANGE "TO VALIDATE" when it has substantial content and no missing markers; and CLEARS the
    banner on any position listed in `-Validated` (slides you have already signed off). Re-run it
    after each editing pass to keep the banners in sync with the deck's state.

- `validate-deck.ps1 -Pptx <deck.pptx> [-Gate 1|2|3|4|all] [-Reference <template.pptx>]`
  Verify the deck is sound BEFORE the user opens it: well-formed parts, consistent slide counts
  (Content_Types vs physical parts vs sldIdLst), no `" />"` re-serialization artifact, and all
  required gate slides present. Exit 0 = OK, 1 = problems. Run this on every generated deck.

## Workflow
1. `inspect-slides.ps1` on the template copy to find the slide position to edit.
2. `dump-notes.ps1` if you need the yellow-guidance / speaker-note context for a slide.
3. `replace-text.ps1` against your working COPY to fill fields (prefer `-Batch` for a gate).
4. `validate-deck.ps1` on the copy — must pass (no repair risk, no missing gate slides).
5. Re-run `inspect-slides.ps1` on the copy to verify values landed.
6. `find-missing.ps1` on the copy to produce the by-gate / by-slide missing-data checklist.
