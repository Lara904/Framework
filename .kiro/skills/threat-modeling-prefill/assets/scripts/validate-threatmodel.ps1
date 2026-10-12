<#
  validate-threatmodel.ps1 - authoritative check that a generated Threat Modeling .xlsx is a
  valid OPC package Excel will open without "repair" (Windows/OPC layer), AND that its scoring
  content agrees with the REAL SFS scale in references/prefill-logic.json (added after a real
  delivered workbook used an invented 1-4/1-16 scale and an invented 0-3 "effectiveness" score
  that had no basis in the real tool - see references/prefill-logic.json's "scales" section).

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File validate-threatmodel.ps1 -Xlsx "<project>_threat_modeling.xlsx"

  Exits non-zero on failure. Prints "THREAT MODEL VALIDATION OK: <path>" and exit 0 on success.
#>
param(
  [Parameter(Mandatory=$true)] [string]$Xlsx
)

$ErrorActionPreference = 'Stop'
$fail = @()
$validRiskLevels = @('very low', 'low', 'average', 'above average', 'high', 'extreme')

if (-not (Test-Path $Xlsx)) { Write-Error "File not found: $Xlsx"; exit 2 }

# 1) OPC package must open (the authoritative "would Excel repair this?" test)
try {
  Add-Type -AssemblyName WindowsBase
  $pkg = [System.IO.Packaging.Package]::Open((Resolve-Path $Xlsx).Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
  $partCount = ($pkg.GetParts() | Measure-Object).Count
  $pkg.Close()
  Write-Output "OPC package opens cleanly ($partCount parts)."
} catch {
  $fail += "OPC package failed to open (Excel would offer to repair): $($_.Exception.Message)"
}

# 2) Every part well-formed XML; workbook.xml must declare at least one sheet.
#    While reading the archive, also pull the "Threat Scenarios" sheet (sheet2.xml) text so step 3
#    can check the scoring content against the real scale without a second archive pass.
$sheet2Text = $null
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Xlsx).Path)
  try {
    foreach ($e in $zip.Entries) {
      if ($e.FullName -like '*.xml' -or $e.FullName -like '*.rels') {
        $sr = New-Object System.IO.StreamReader($e.Open())
        $content = $sr.ReadToEnd(); $sr.Close()
        try { [xml]$content | Out-Null }
        catch { $fail += "Malformed XML part: $($e.FullName)" }
        if ($e.FullName -eq 'xl/workbook.xml' -and $content -notmatch '<sheet ') {
          $fail += "xl/workbook.xml declares no sheet"
        }
        if ($e.FullName -eq 'xl/worksheets/sheet2.xml') { $sheet2Text = $content }
      }
    }
  } finally { $zip.Dispose() }
} catch {
  $fail += "Could not read archive: $($_.Exception.Message)"
}

# 3) Scoring content must use the REAL SFS scale, not the old invented one.
#    Cells are addressed by their own "r" attribute (e.g. r="F15"), so this does not rely on a
#    fixed column count per row - a blank cell (New-XlsxCell omits it entirely when StyleId=0)
#    does not shift later columns out of position the way a flat cell-order read would.
if ($null -ne $sheet2Text) {
  $header = [regex]::Matches($sheet2Text, '<c r="A(\d+)"[^>]*><is><t[^>]*>ID</t></is></c>')
  if ($header.Count -gt 0) {
    $headerRow = [int]$header[0].Groups[1].Value
    # Map every lettered cell on every row after the header: col -> row -> text
    $cellRx = [regex]::Matches($sheet2Text, '<c r="([A-Z]+)(\d+)"[^>]*><is><t[^>]*>(.*?)</t></is></c>')
    $byRow = @{}
    foreach ($m in $cellRx) {
      $col = $m.Groups[1].Value; $row = [int]$m.Groups[2].Value; $txt = $m.Groups[3].Value
      if ($row -le $headerRow) { continue }
      if (-not $byRow.ContainsKey($row)) { $byRow[$row] = @{} }
      $byRow[$row][$col] = $txt
    }
    $rowNums = @($byRow.Keys | Sort-Object)
    foreach ($row in $rowNums) {
      $r = $byRow[$row]
      $id = if ($r.ContainsKey('A')) { $r['A'] } else { "row $row" }
      $occ = if ($r.ContainsKey('F')) { $r['F'] } else { $null }
      $imp = if ($r.ContainsKey('G')) { $r['G'] } else { $null }
      $risk = if ($r.ContainsKey('H')) { $r['H'] } else { $null }
      if ($occ -and $occ -notmatch '^[123]$' -and $occ -ne 'TBC') {
        $fail += "Scenario $id (row $row): Occurrence '$occ' is not in the real 1-3 scale (see prefill-logic.json) - looks like a leftover 1-4 value or an invented score."
      }
      if ($imp -and $imp -notmatch '^[123]$' -and $imp -ne 'TBC') {
        $fail += "Scenario $id (row $row): Impact '$imp' is not in the real 1-3 scale (see prefill-logic.json) - looks like a leftover 1-4 value or an invented score."
      }
      if ($risk -and $risk -ne 'TBC' -and ($validRiskLevels -notcontains $risk.Trim().ToLower())) {
        $fail += "Scenario $id (row $row): Risk level '$risk' is not one of the real matrix labels (very low / low / average / above average / high / extreme) - looks like an old numeric band (e.g. 'High (12)')."
      }
    }
    if ($rowNums.Count -eq 0) { Write-Output "Threat Scenarios sheet has a header but no scenario rows yet." }
    else { Write-Output "Checked $($rowNums.Count) scenario row(s) against the real occurrence/impact/risk-level scale." }
  } else {
    Write-Output "Threat Scenarios sheet not yet populated (no header row found) - nothing to score-check."
  }
}

if ($fail.Count -gt 0) {
  Write-Output "THREAT MODEL VALIDATION FAILED:"
  $fail | ForEach-Object { Write-Output " - $_" }
  exit 1
}
Write-Output "THREAT MODEL VALIDATION OK: $Xlsx"
exit 0
