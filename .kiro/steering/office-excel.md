---
inclusion: fileMatch
fileMatchPattern: '*.xlsx'
---

# Reading & Writing Excel (.xlsx) on this machine

## Environment constraints (verified)
- This is **Windows / PowerShell (cmd-style shell)**.
- **Python is NOT available** (`python`, `python3` resolve to the Microsoft Store stub and fail). Do **not** rely on `openpyxl`, `pandas`, etc.
- **Node.js is NOT available**. Do not rely on `xlsx`/`exceljs`.
- **Microsoft Excel IS installed** and **COM automation works** (`New-Object -ComObject Excel.Application`). This is the default tool for `.xlsx`.
- The `ImportExcel` PowerShell module is not guaranteed present; prefer Excel COM.

## Golden rules
1. **Never overwrite a user's file blindly.** Open existing files **read-only** first to inspect, and **append** rather than rewrite when the user has edited them.
2. **Write the automation to a temp `.ps1` script** in `.temp_ai/office-excel/` and run it with `powershell -NoProfile -ExecutionPolicy Bypass -File .\.temp_ai\office-excel\_run.ps1`. Do **not** try to cram multi-line COM logic into a single `-Command` string, and never write the temp script to the project root.
3. **Delete the temp script** once it has run successfully.
4. **Always release COM objects and quit Excel**, otherwise orphan `EXCEL.EXE` processes accumulate and can lock the file.
5. After writing, **re-open read-only to verify** row/column counts and key values.
6. Keep `$excel.Visible = $false` and `$excel.DisplayAlerts = $false`.

## Reading (inspect read-only)
Open with read-only flag so you never risk mutating the source:
```powershell
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false; $excel.DisplayAlerts = $false
$p = Join-Path (Get-Location) 'Deliverables\file.xlsx'
$wb = $excel.Workbooks.Open($p, 0, $true)   # 3rd arg $true = ReadOnly
foreach ($ws in $wb.Worksheets) {
    $u = $ws.UsedRange
    Write-Output ("sheet '{0}' rows={1} cols={2}" -f $ws.Name, $u.Rows.Count, $u.Columns.Count)
}
$wb.Close($false); $excel.Quit(); [GC]::Collect()
```
- Read a cell value with `$ws.Cells.Item($row, $col).Value2` (1-indexed, row/col).
- `UsedRange.Row` / `UsedRange.Column` give the top-left offset if data does not start at A1.

## Writing (create new)
Batch data via a 2D array assignment for speed (avoid cell-by-cell for large sets):
```powershell
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false; $excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1); $ws.Name = 'Data'

$headers = @('ID','Name','Value')
for ($c=0; $c -lt $headers.Count; $c++) { $ws.Cells.Item(1,$c+1) = $headers[$c] }

$rows = @( @('A','foo','1'), @('B','bar','2') )
$n = $rows.Count; $m = $headers.Count
$arr = New-Object 'object[,]' $n, $m
for ($r=0; $r -lt $n; $r++) { for ($c=0; $c -lt $m; $c++) { $arr[$r,$c] = [string]$rows[$r][$c] } }
$rng = $ws.Range($ws.Cells.Item(2,1), $ws.Cells.Item(1+$n, $m))
$rng.Value2 = $arr

$wb.SaveAs((Join-Path (Get-Location) 'Deliverables\out.xlsx'), 51)   # 51 = xlOpenXMLWorkbook (.xlsx)
$wb.Close($true); $excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
```

## Editing an existing file WITHOUT losing user changes
- Open **writable** (`Open($p)`), locate the insertion point dynamically (do not assume fixed row numbers — the user may have added rows/columns), then **append columns/rows**.
- To add columns to the right: compute `$startCol = $ws.UsedRange.Column + $ws.UsedRange.Columns.Count`.
- To insert rows before a total row: find the total row, then `$ws.Rows.Item($row).Insert()` for each new row, then fill.
- Save in place with `$wb.Save()` then `$wb.Close($true)`.

## Formatting cheatsheet
- Colors are **BGR** integers, not RGB. e.g. navy `#002D72` → `7495202`; white font → `16777215`.
- Header style: `$rng.Font.Bold = $true`, `$rng.Interior.Color = <bgr>`, `$rng.Font.Color = 16777215`.
- Wrap + top align: `$used.WrapText = $true`; `$used.VerticalAlignment = -4160` (xlTop).
- Borders: `$used.Borders.LineStyle = 1`.
- Autofit then cap width: `[void]$used.Columns.AutoFit()`, then loop columns and set `ColumnWidth = 55` where it exceeds a cap.
- Freeze header row: `$ws.Application.ActiveWindow.SplitRow = 1; $ws.Application.ActiveWindow.FreezePanes = $true`.

## SaveAs format codes
- `51` = `.xlsx` (xlOpenXMLWorkbook)
- `52` = `.xlsm` (macro-enabled)
- `56` = `.xls` (legacy)

## Common pitfalls
- Do **not** use `&` as a separator in PowerShell; use `;`. Replace `&&` with `;`.
- Cells are `Item($row, $col)` — **row first**. Off-by-one errors are common; sheet indices and cells are **1-based**.
- If a script errors midway, an orphan Excel process may hold the file open. Kill with `Get-Process EXCEL -ErrorAction SilentlyContinue | Stop-Process -Force` before retrying.
- Keep inline `-Command` usage to trivial one-liners; anything with loops/quotes goes in a `.ps1` file.

## When the user already has the file open (locked file)

This is different from an orphan `EXCEL.EXE` process. If the **user** has the workbook open, you must **never** kill their Excel — that would lose their unsaved work. Handle it gracefully instead.

### Symptoms
- `Workbooks.Open($p)` (writable) returns a **read-only** copy silently, or Excel shows a "file in use" dialog (which hangs a headless script).
- `$wb.Save()` / `SaveAs()` throws `0x800A03EC` or "cannot save because the file is locked / in use by another user".
- A lock file `~$<name>.xlsx` exists next to the file.

### Pre-flight: detect the lock BEFORE doing work
```powershell
function Test-FileLocked($path) {
    if (-not (Test-Path $path)) { return $false }
    try {
        $fs = [System.IO.File]::Open($path, 'Open', 'ReadWrite', 'None')
        $fs.Close(); return $false          # got exclusive access -> not locked
    } catch { return $true }                 # locked by another process
}

$p = Join-Path (Get-Location) 'Deliverables\file.xlsx'
if (Test-FileLocked $p) {
    Write-Output "LOCKED: the file is open in Excel. Read-only inspection is possible; writing is not."
    # -> proceed read-only, OR stop and ask the user to close it (see rules below)
}
```
Note the presence of a lock file as a secondary signal:
```powershell
$lock = Join-Path (Split-Path $p) ("~$" + (Split-Path $p -Leaf))
if (Test-Path $lock) { Write-Output "Lock file present: $lock" }
```

### Rules
1. **Reading is usually fine even when open** — open read-only (`Open($p,0,$true)`) to inspect. This works while the user edits.
2. **Writing to a user-open file will fail.** Do **not** silently write to a temp copy and pretend it succeeded — the user would not see the change. Instead:
   - **Stop and tell the user**: "The file `X` is currently open in Excel. Please save & close it so I can write to it, or tell me to write to a new file `X (updated).xlsx` instead."
   - Only proceed automatically if the user pre-authorised writing to an alternate file.
3. **Never** `Stop-Process` on an Excel that holds unsaved user data. `Stop-Process EXCEL` is only for **orphan** processes that YOU created and failed to close — and even then, confirm none of the user's workbooks are open.
4. **Set a headless guard** so a "file in use" dialog cannot hang the script:
   ```powershell
   $excel.DisplayAlerts = $false
   $excel.AskToUpdateLinks = $false
   $excel.EnableEvents = $false
   # Open read-only + not-notify so it never prompts:
   # Open(Filename, UpdateLinks, ReadOnly, Format, Password, WriteResPassword, IgnoreReadOnlyRecommended, ...)
   $wb = $excel.Workbooks.Open($p, 0, $true, [Type]::Missing, [Type]::Missing, [Type]::Missing, $true)
   ```
5. **Verify write success**: after `Save()`, confirm `$wb.ReadOnly -eq $false`. If `$wb.ReadOnly` is `$true`, you opened a locked file — abort and inform the user rather than losing the edit.
6. **Fallback pattern**: when writing is required but the file is locked, write to `"<name> (updated).xlsx"` and clearly report that the original was locked so the user can reconcile.

### Detecting read-only-because-locked after open
```powershell
$wb = $excel.Workbooks.Open($p)
if ($wb.ReadOnly) {
    $wb.Close($false); $excel.Quit()
    throw "File is open elsewhere (opened read-only). Ask the user to close it before writing."
}
```
