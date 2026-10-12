---
inclusion: fileMatch
fileMatchPattern: '*.pptx'
---

# Reading & Writing PowerPoint (.pptx) on this machine

## Environment constraints (verified)
- **Windows / PowerShell**. **No Python** (`python-pptx` unavailable), **no Node.js**.
- **Microsoft PowerPoint is installed** and **COM automation works** (`New-Object -ComObject PowerPoint.Application`). This is the default tool for `.pptx`.

## Golden rules
1. Inspect existing decks **read-only** before editing; **append** slides rather than rewrite user-edited files.
2. Put multi-line COM logic in a temp `.ps1` in `.temp_ai/office-powerpoint/`, run with `powershell -NoProfile -ExecutionPolicy Bypass -File .\.temp_ai\office-powerpoint\_run.ps1`, then delete it. Never write the temp script to the project root.
3. **Always release COM objects and quit PowerPoint** to avoid orphan `POWERPNT.EXE` processes.
4. PowerPoint COM often **cannot run fully hidden**: `$ppt.Visible` may need to be `$true` (`[Microsoft.Office.Core.MsoTriState]::msoTrue` = 1). Setting `Visible = $false` can throw. Prefer opening with `WithWindow = $false` on `Open` if you must stay headless.
5. Re-open read-only to verify slide/shape counts after writing.

## Reading text (read-only)
```powershell
$ppt = New-Object -ComObject PowerPoint.Application
$p = Join-Path (Get-Location) 'Deliverables\deck.pptx'
# Open(path, ReadOnly, Untitled, WithWindow)
$pres = $ppt.Presentations.Open($p, $true, $false, $false)
foreach ($slide in $pres.Slides) {
    Write-Output ("--- slide {0} ---" -f $slide.SlideIndex)
    foreach ($shape in $slide.Shapes) {
        if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
            Write-Output $shape.TextFrame.TextRange.Text
        }
    }
}
$pres.Close(); $ppt.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
```

## Writing (create new)
```powershell
$ppt = New-Object -ComObject PowerPoint.Application
$pres = $ppt.Presentations.Add($false)   # WithWindow = $false

# Layout enum ppSlideLayout: 1 = ppLayoutTitle, 2 = ppLayoutText, 12 = ppLayoutBlank
$slide = $pres.Slides.Add(1, 1)          # index 1, ppLayoutTitle
$slide.Shapes.Item(1).TextFrame.TextRange.Text = "Deck Title"
$slide.Shapes.Item(2).TextFrame.TextRange.Text = "Subtitle / author"

$slide2 = $pres.Slides.Add(2, 2)         # ppLayoutText (title + content)
$slide2.Shapes.Item(1).TextFrame.TextRange.Text = "Agenda"
$body = $slide2.Shapes.Item(2).TextFrame.TextRange
$body.Text = "First point`rSecond point`rThird point"   # `r separates bullets

$pres.SaveAs((Join-Path (Get-Location) 'Deliverables\out.pptx'), 24)  # 24 = ppSaveAsOpenXMLPresentation (.pptx)
$pres.Close(); $ppt.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
```

## Adding a free-form text box (precise placement)
```powershell
# AddTextbox(orientation, left, top, width, height) ; orientation 1 = msoTextOrientationHorizontal
$tb = $slide.Shapes.AddTextbox(1, 40, 40, 600, 80)
$tb.TextFrame.TextRange.Text = "Custom placed text"
$tb.TextFrame.TextRange.Font.Size = 18
$tb.TextFrame.TextRange.Font.Bold = $true
```
- Position/size are in **points** (72 pt = 1 inch). Standard 16:9 slide is 960 x 540 pt (13.33" x 7.5").
- Font color is RGB via `.Font.Color.RGB` (this is **RGB**, unlike Excel's Interior BGR).

## Appending slides to an existing deck (non-destructive)
```powershell
$pres = $ppt.Presentations.Open($p, $false, $false, $false)   # writable, no window
$idx = $pres.Slides.Count + 1
$slide = $pres.Slides.Add($idx, 2)
$slide.Shapes.Item(1).TextFrame.TextRange.Text = "New Slide"
$pres.Save(); $pres.Close()
```

## Useful enum values
- Layout (`ppSlideLayout`): `1` Title, `2` Title+Text, `7` Title+Content, `12` Blank.
- SaveAs (`ppSaveAsFileType`): `24` `.pptx`, `25` `.pptm` (macro), `32` `.pdf`, `1` `.ppt` (legacy).
- Text orientation: `1` = horizontal.

## Common pitfalls
- Do not assume you can hide the app. If `Visible=$false` throws, open presentations with `WithWindow=$false` instead and skip setting `Visible`.
- Bullets are separated by `` `r `` (carriage return) inside a single `TextRange.Text`, not `` `n ``.
- Shape indices are **1-based**; a layout's placeholders (title/body) are usually `Item(1)` and `Item(2)` but verify with `$slide.Shapes.Count`.
- Kill orphans before retrying: `Get-Process POWERPNT -ErrorAction SilentlyContinue | Stop-Process -Force`.
- Colors here are **RGB**, whereas Excel COM uses **BGR** — do not copy color integers between the two.
- Use `;` not `&` between PowerShell statements.

## When the user already has the file open (locked file)

Different from an orphan `POWERPNT.EXE`. If the **user** has the deck open, never kill their PowerPoint — you would lose unsaved work.

### Symptoms
- `Presentations.Open(...)` opens read-only or shows a "file in use" dialog that hangs a headless script.
- `$pres.Save()` throws a lock/permission error.
- A lock file `~$<name>.pptx` exists next to the file.

### Pre-flight: detect the lock BEFORE doing work
```powershell
function Test-FileLocked($path) {
    if (-not (Test-Path $path)) { return $false }
    try { $fs = [System.IO.File]::Open($path,'Open','ReadWrite','None'); $fs.Close(); return $false }
    catch { return $true }
}
$p = Join-Path (Get-Location) 'Deliverables\deck.pptx'
if (Test-FileLocked $p) { Write-Output "LOCKED: open in PowerPoint. Read-only OK; writing will fail." }
```

### Rules
1. **Reading is fine even when open** — open read-only: `Presentations.Open($p, $true, $false, $false)` (ReadOnly=$true, WithWindow=$false).
2. **Writing to a user-open deck will fail.** Do not silently write a temp copy and claim success. **Stop and ask** the user to close it, or save to `"<name> (updated).pptx"` if they pre-authorised an alternate file.
3. **Never** `Stop-Process POWERPNT` when it may hold the user's unsaved work; reserve that only for orphan instances YOU created.
4. **PowerPoint has no reliable read-only flag on the presentation object.** Detect the lock with the `Test-FileLocked` pre-flight above BEFORE attempting to open writable, since PowerPoint is more likely than Excel/Word to surface a blocking dialog.
5. If a `Save()` throws, catch it, close without saving, and report to the user — do not retry in a loop.
   ```powershell
   try { $pres.Save() }
   catch { $pres.Close(); $ppt.Quit(); throw "Deck is open elsewhere; ask user to close before writing." }
   ```
