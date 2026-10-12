<#
  NfrRepo.psm1 - shared helpers for the nfr-requirements skill.

  The Stellantis NFR repository is an .xlsm workbook (DP-MD18-EN). This machine has no
  Python / openpyxl and no ImportExcel module, but it DOES have Excel installed, so we
  drive Excel through COM. All primitives live here; the thin wrapper scripts reuse them.

  Sheet / cell map (discovered from the reference model, keep in sync if the template changes):
    Sheet "Synthesis" - system parameters (the filter inputs):
      I8  = Data privacy risk level (No / A / B / C / D)
      I9  = DICT (4 digits D I C T, e.g. "2221" or "1111")
      I10 = RTO  (1..8, or 9 = not involved)
      I11 = SOX  (Yes / No)
    Sheet "NFR repository" - one row per NFR, headers on row 3, data from row 4:
      col 2  = Reference (NFR-xxxx)          col 8  = Relevant (editable)
      col 3  = Title                         col 9  = Status   (editable)
      col 4  = Cases of dispensation         col 10 = Last update (editable)
      col 5  = Description                    col 12 = Comments / Valorization (editable)
      col 23..38 = DICT trigger flags D1..D4,I1..I4,C1..C4,T1..T4 ("X" when set)
      col 39 = RTO trigger   col 40 = Data privacy trigger   col 41 = SOX trigger
      col 42 = Group         col 43 = Weight
  Only columns 8, 9, 10, 12 are meant to be edited by a project.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:REPO_SHEET = 'NFR repository'
$script:SYN_SHEET  = 'Synthesis'
$script:COL = @{
  Reference = 2;  Title = 3;  Dispensation = 4;  Description = 5;
  Deliverables = 6; CheckMeans = 7; Relevant = 8; Status = 9;
  LastUpdate = 10; LastControl = 11; Comments = 12;
  RTO = 39; DataPrivacy = 40; SOX = 41; Group = 42; Weight = 43
}
$script:HEADER_ROW = 3
$script:DATA_START = 4

function New-ExcelApp {
  $xl = New-Object -ComObject Excel.Application
  $xl.Visible = $false
  $xl.DisplayAlerts = $false
  $xl.ScreenUpdating = $false
  return $xl
}

function Close-ExcelApp {
  param($xl, $wb, [switch]$Save)
  if ($wb) { $wb.Close($Save.IsPresent) }
  if ($xl) { $xl.Quit() }
  if ($wb) { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) }
  if ($xl) { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) }
  [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
}

# Resolve a path to a full path even if it does not exist yet.
function Resolve-FullPath {
  param([Parameter(Mandatory)][string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  return (Join-Path (Get-Location).Path $Path)
}

# Return the row index of an NFR reference (exact match on col 2), or 0 if not found.
function Get-NfrRow {
  param($ws, [Parameter(Mandatory)][string]$Reference)
  $last = $ws.UsedRange.Rows.Count
  for ($r = $script:DATA_START; $r -le $last; $r++) {
    $ref = '' + $ws.Cells.Item($r, $script:COL.Reference).Value2
    if ($ref.Trim() -eq $Reference.Trim()) { return $r }
  }
  return 0
}

# Read every NFR row into objects. Section header rows (no NFR- prefix) are skipped.
function Read-NfrRepository {
  param([Parameter(Mandatory)][string]$WorkbookPath)
  $full = Resolve-FullPath $WorkbookPath
  if (-not (Test-Path $full)) { throw "Workbook not found: $full" }
  $xl = New-ExcelApp
  $wb = $xl.Workbooks.Open($full, $false, $true)   # read-only
  try {
    $ws = $wb.Worksheets.Item($script:REPO_SHEET)
    $last = $ws.UsedRange.Rows.Count
    $rows = @()
    for ($r = $script:DATA_START; $r -le $last; $r++) {
      $ref = '' + $ws.Cells.Item($r, $script:COL.Reference).Value2
      if ($ref -notmatch '^NFR') { continue }
      $flags = @()
      foreach ($crit in @(@('D',23),@('I',27),@('C',31),@('T',35))) {
        $lv = @()
        for ($i=0; $i -lt 4; $i++) {
          $v = '' + $ws.Cells.Item($r, $crit[1]+$i).Value2
          if ($v.Trim() -ne '') { $lv += ($i+1) }
        }
        if ($lv.Count -gt 0) { $flags += ($crit[0] + ($lv -join '')) }
      }
      $rows += [pscustomobject]@{
        Reference    = $ref
        Title        = ('' + $ws.Cells.Item($r, $script:COL.Title).Value2)
        Dispensation = ('' + $ws.Cells.Item($r, $script:COL.Dispensation).Value2)
        Description  = ('' + $ws.Cells.Item($r, $script:COL.Description).Value2)
        Group        = ('' + $ws.Cells.Item($r, $script:COL.Group).Value2)
        DICTflags    = ($flags -join ',')
        RTO          = ('' + $ws.Cells.Item($r, $script:COL.RTO).Value2)
        DataPrivacy  = ('' + $ws.Cells.Item($r, $script:COL.DataPrivacy).Value2)
        SOX          = ('' + $ws.Cells.Item($r, $script:COL.SOX).Value2)
        Relevant     = ('' + $ws.Cells.Item($r, $script:COL.Relevant).Value2)
        Status       = ('' + $ws.Cells.Item($r, $script:COL.Status).Value2)
        Row          = $r
      }
    }
    return $rows
  } finally { Close-ExcelApp -xl $xl -wb $wb }
}

# Explain/preview helper ONLY - it describes how the referential filter behaves so you can answer
# questions ("why is this NFR relevant at C=3?"). It is NOT used to fill a deliverable: the
# authoritative Relevant column is always produced by the model's own macro (RequirementsFilter),
# the only authorised calculation method. This helper was validated to match that macro exactly
# (0 mismatch on a human-filled reference at DICT 1111/RTO 9), but never substitute it for the
# macro when generating the workbook.
#
# RULE the macro applies (for explanation):
#   - An NFR with NO trigger (generic) is always Relevant = Yes.
#   - An NFR with triggers is Relevant = Yes if AT LEAST ONE trigger matches the context:
#       * DICT flag "<crit><levels>" (e.g. C34, D1234) matches when the system's level for that
#         criterion is listed (e.g. C=3 matches C34; C=1 does NOT match C34 but matches C1234).
#       * RTO=<n> matches when the system RTO class equals n.
#       * DP matches when the system processes personal data.
#       * SOX matches when the system is in SOX scope.
#   - Otherwise Relevant = No.
# The project's applicability judgement ("no batch", "no IP service", ...) is NOT this column:
# it is expressed via Status (Yes + "Not relevant" + comment), never by forcing Relevant.
function Test-NfrRelevant {
  param(
    [Parameter(Mandatory)][int]$D,
    [Parameter(Mandatory)][int]$I,
    [Parameter(Mandatory)][int]$C,
    [Parameter(Mandatory)][int]$T,
    [Parameter(Mandatory)][int]$Rto,
    [Parameter(Mandatory)][bool]$Sox,
    [Parameter(Mandatory)][bool]$DataPrivacy,
    [string]$DICTflags = '',
    [string]$RtoTrigger = '',
    [string]$DpTrigger = '',
    [string]$SoxTrigger = ''
  )
  $lvl = @{ D = $D; I = $I; C = $C; T = $T }
  $hasTrigger = $false
  if ($DICTflags.Trim() -ne '') {
    foreach ($tok in ($DICTflags -split ',')) {
      $tok = $tok.Trim(); if ($tok -eq '') { continue }
      $crit = $tok.Substring(0,1)
      $levels = $tok.Substring(1).ToCharArray() | ForEach-Object { [int][string]$_ }
      $hasTrigger = $true
      if ($levels -contains $lvl[$crit]) { return 'Yes' }
    }
  }
  if ($RtoTrigger.Trim() -ne '') { $hasTrigger = $true; if ([int]$RtoTrigger -eq $Rto) { return 'Yes' } }
  if ($DpTrigger.Trim()  -ne '') { $hasTrigger = $true; if ($DataPrivacy) { return 'Yes' } }
  if ($SoxTrigger.Trim() -ne '') { $hasTrigger = $true; if ($Sox) { return 'Yes' } }
  if (-not $hasTrigger) { return 'Yes' }   # generic requirement
  return 'No'
}

# Parse a 4-char DICT string like "2221" into a hashtable @{D=2;I=2;C=2;T=1}.
function ConvertFrom-Dict {
  param([Parameter(Mandatory)][string]$Dict)
  $d = ($Dict -replace '\D','')
  if ($d.Length -ne 4) { throw "DICT must be 4 digits (D I C T), got '$Dict'." }
  return @{ D = [int][string]$d[0]; I = [int][string]$d[1]; C = [int][string]$d[2]; T = [int][string]$d[3] }
}

Export-ModuleMember -Function New-ExcelApp, Close-ExcelApp, Resolve-FullPath,
  Get-NfrRow, Read-NfrRepository, Test-NfrRelevant, ConvertFrom-Dict `
  -Variable REPO_SHEET, SYN_SHEET, COL, HEADER_ROW, DATA_START
