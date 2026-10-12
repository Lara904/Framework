---
inclusion: fileMatch
fileMatchPattern: '*.docx'
---

# Reading & Writing Word (.docx) on this machine

## Environment constraints (verified)
- **Windows / PowerShell**. **No Python** (`python-docx` unavailable), **no Node.js**.
- **Microsoft Word is installed** and **COM automation works** (`New-Object -ComObject Word.Application`). This is the default tool for `.docx`.

## Golden rules
1. Inspect existing documents **read-only** before editing; **append** rather than rewrite user-edited files.
2. Put multi-line COM logic in a temp `.ps1` in `.temp_ai/office-word/`, run with `powershell -NoProfile -ExecutionPolicy Bypass -File .\.temp_ai\office-word\_run.ps1`, then delete it. Never write the temp script to the project root.
3. **Always release COM objects and quit Word** to avoid orphan `WINWORD.EXE` processes locking the file.
4. Keep `$word.Visible = $false`.
5. Re-open read-only to verify after writing.

## Reading text (read-only)
```powershell
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$p = Join-Path (Get-Location) 'Deliverables\file.docx'
$doc = $word.Documents.Open($p, [ref]$false, [ref]$true)  # ReadOnly = 3rd arg $true
Write-Output $doc.Content.Text                              # full body text
Write-Output ("paragraphs: " + $doc.Paragraphs.Count)
$doc.Close($false); $word.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
```
- Iterate `$doc.Paragraphs` and read `$p.Range.Text` / `$p.Style` for structure.
- Iterate `$doc.Tables`, then `$table.Cell($r,$c).Range.Text` (trailing cell markers `\r\a` should be trimmed).

## Writing (create new)
Use named styles and typed content rather than raw strings for clean structure:
```powershell
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()
$sel = $word.Selection

$sel.Style = "Title";    $sel.TypeText("My Document"); $sel.TypeParagraph()
$sel.Style = "Heading 1";$sel.TypeText("Section 1");   $sel.TypeParagraph()
$sel.Style = "Normal";   $sel.TypeText("Body text goes here."); $sel.TypeParagraph()

# bullet list
$sel.Range.ListFormat.ApplyBulletDefault()
$sel.TypeText("First point"); $sel.TypeParagraph()
$sel.TypeText("Second point"); $sel.TypeParagraph()
$sel.Range.ListFormat.RemoveNumbers()

$doc.SaveAs([ref](Join-Path (Get-Location) 'Deliverables\out.docx'), [ref]16)  # 16 = wdFormatXMLDocument (.docx)
$doc.Close($true); $word.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
```

## Tables
```powershell
$range = $doc.Content
$range.Collapse(0)  # 0 = wdCollapseEnd
$rows = 3; $cols = 2
$table = $doc.Tables.Add($range, $rows, $cols)
$table.Borders.Enable = $true
$table.Cell(1,1).Range.Text = "Header A"
$table.Cell(1,2).Range.Text = "Header B"
```
- Style the header row: `$table.Rows.Item(1).Range.Font.Bold = $true`.
- Access cells with `$table.Cell($row,$col)` (1-based).

## Appending to an existing document (non-destructive)
```powershell
$doc = $word.Documents.Open($p)                 # writable
$end = $doc.Content
$end.Collapse(0)                                # move to end (wdCollapseEnd)
$end.InsertParagraphAfter()
$end.InsertAfter("New appended section")
$doc.Save(); $doc.Close($true)
```

## SaveAs format codes
- `16` = `.docx` (wdFormatXMLDocument)
- `12` = `.docx` also works in some builds (wdFormatDocumentDefault)
- `17` = `.pdf` (export)
- `0`  = `.doc` (legacy)

## Common pitfalls
- Many Word COM methods need arguments **by reference**: `[ref]$false`, `[ref]16`, `[ref](path)`.
- Collapse direction constants: `wdCollapseEnd = 0`, `wdCollapseStart = 1`.
- Trim `\r`, `\a`, `\x07` (cell/row markers) from extracted table text.
- Kill orphans before retrying: `Get-Process WINWORD -ErrorAction SilentlyContinue | Stop-Process -Force`.
- Use `;` not `&` between PowerShell statements.

## When the user already has the file open (locked file)

Different from an orphan `WINWORD.EXE`. If the **user** has the document open, never kill their Word — you would lose unsaved work.

### Symptoms
- `Documents.Open($p)` returns a read-only copy, or Word shows a "file in use" dialog that hangs a headless script.
- `$doc.Save()` throws a lock/permission error.
- A lock file `~$<name>.docx` exists next to the file.

### Pre-flight: detect the lock BEFORE doing work
```powershell
function Test-FileLocked($path) {
    if (-not (Test-Path $path)) { return $false }
    try { $fs = [System.IO.File]::Open($path,'Open','ReadWrite','None'); $fs.Close(); return $false }
    catch { return $true }
}
$p = Join-Path (Get-Location) 'Deliverables\file.docx'
if (Test-FileLocked $p) { Write-Output "LOCKED: open in Word. Read-only OK; writing will fail." }
```

### Rules
1. **Reading is fine even when open** — open read-only: `$word.Documents.Open($p, [ref]$false, [ref]$true)`.
2. **Writing to a user-open file will fail.** Do not silently write a temp copy and claim success. Instead **stop and ask** the user to close it, or write to `"<name> (updated).docx"` if they pre-authorised an alternate file.
3. **Never** `Stop-Process WINWORD` when it may hold the user's unsaved work; that command is only for orphan instances YOU created.
4. **Headless guard** so no dialog hangs the script:
   ```powershell
   $word.DisplayAlerts = 0            # wdAlertsNone
   $word.Options.ConfirmConversions = $false
   # Open(FileName, ConfirmConversions, ReadOnly, AddToRecentFiles, ...)
   $doc = $word.Documents.Open($p, [ref]$false, [ref]$true, [ref]$false)
   ```
5. **Verify write success**: after opening writable, check `$doc.ReadOnly`. If `$true`, the file is open elsewhere — abort and inform the user instead of losing the edit.
   ```powershell
   $doc = $word.Documents.Open($p)
   if ($doc.ReadOnly) { $doc.Close($false); $word.Quit(); throw "Open elsewhere; ask user to close before writing." }
   ```
