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
        # Comments/Valorization (col 12) - added because nothing previously surfaced this column
        # to the review step: a real project's decisions file commented only 22 of 102 relevant
        # NFRs, and the gap went unnoticed because export-nfr.ps1's "re-dump to confirm" (SKILL.md
        # quick workflow step 5) never showed Comments, even though $script:COL.Comments = 12 was
        # already defined - the column map existed, reading it did not.
        Comments     = ('' + $ws.Cells.Item($r, $script:COL.Comments).Value2)
        Row          = $r
      }
    }
    return $rows
  } finally { Close-ExcelApp -xl $xl -wb $wb }
}

# Explain/preview helper when Excel is available (the macro remains authoritative whenever
# Excel COM can run - never substitute this for the macro just because it is convenient).
# When Excel is NOT available, New-NfrWorkbookHeadless uses this as the one authorised
# computation path for Relevant (see the "HEADLESS (no-COM) path" section below).
# Checked against the real, filled Forensic-tooling workbook (DICT 3333, 133 NFRs): 131/133
# match the model's own macro output exactly. The 2 exceptions (NFR-6004a, NFR-6507a) carry a
# DICT trigger on MORE THAN ONE criterion in the same row; the real macro's exact rule for a
# multi-criterion row could not be reverse-engineered from the data available (flipping this
# logic to a conjunction fixes those 2 but then breaks their "b"-suffixed sibling rows, which
# the macro matches on a single-criterion basis) - so this remains a documented, narrow gap,
# not a reason to distrust the other 131 results. See Test-NfrRelevant's inline comment.
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
  # Disjunction across DICT tokens on one row (original logic - kept after investigation, see
  # below): a row is DICT-relevant if ANY one of its criterion/level tokens matches the
  # project's level for that criterion.
  #
  # KNOWN DIVERGENCE (found 2026-11 running this against the full real 133-NFR repository,
  # headless path, DICT 3333): NFR-6004a (D123+I123+C12+SOX) and NFR-6507a (D23+I12+T34) are
  # reported "Not relevant" by the model's own macro even though this OR-logic matches them
  # "Yes" (D=3 and I=3 each individually satisfy their respective ranges). Flipping the logic
  # to a conjunction (all flagged criteria must match) fixes those two but then breaks their
  # own "b" sibling rows (NFR-6004b, NFR-6507b), which the macro marks "Yes" precisely where
  # only ONE of their flagged criteria matches - so neither a pure AND nor a pure OR rule holds
  # uniformly across both halves of an a/b pair, and the real VBA macro's exact rule for a
  # multi-criterion row could not be reverse-engineered from the data available here (no access
  # to the macro's source). Net result with plain OR-logic: 131/133 NFRs match the real macro's
  # Relevant column on the one real project checked - both mismatches are "a"-suffixed,
  # multi-criterion rows. Any NFR reference ending in a letter (a/b/c...) that also carries a
  # flag on MORE THAN ONE DICT criterion should be spot-checked by hand before finalizing
  # Status, rather than trusted blindly - see Write-NfrHeadlessNotice.
  if ($DICTflags.Trim() -ne '') {
    foreach ($tok in ($DICTflags -split ',')) {
      $tok = $tok.Trim(); if ($tok -eq '') { continue }
      $hasTrigger = $true
      $crit = $tok.Substring(0,1)
      $levels = $tok.Substring(1).ToCharArray() | ForEach-Object { [int][string]$_ }
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

# ============================================================================================
# HEADLESS (no-COM) path - resolves the blocker found running this skill inside Kiro: Kiro's
# own sandbox (like every Linux PowerShell host) has no Excel, so `New-Object -ComObject
# Excel.Application` always fails there - `-ComObject` is not even a recognised parameter on
# PowerShell 7 for Linux/macOS (COM is a Windows-only interop mechanism). Every real
# `new-nfr-workbook.ps1` run on Kiro therefore hit the macroError branch and produced only a
# half-filled workbook (system parameters written, Relevant/Status/Comments left blank -
# exactly the "NFR Excel blocked, README produced instead" outcome logged in
# Suivi_Avancement_ARB_Readiness). This section reproduces, without Excel, exactly what the
# model's own macros do - never a different or looser calculation:
#   - Relevant: `Test-NfrRelevant` reproduces `RequirementsFilter`'s rule - it was previously
#     "explain-only" (for answering questions, never for filling a deliverable); promoted here
#     to the one additional authorised computation path, used ONLY when Excel COM is
#     unavailable. Matched 131/133 NFRs of the one real project checked end-to-end (2026-11) -
#     see Test-NfrRelevant's own docstring for the 2 known-divergent multi-criterion rows this
#     could NOT fully reverse-engineer without the macro's VBA source. The deliverable/README
#     must say so plainly (see Write-NfrHeadlessNotice) - a documented, bounded trade-off, not
#     a silent substitution and not an overclaimed "0 mismatch".
#   - ShowHideRequirements: reproduced by setting `hidden="1"` on a Not-relevant row's <row>
#     element - the same visual effect (filtered rows hidden, not deleted).
#   - Every other part of the .xlsm (styles, charts, the VBA project, the Synthesis formulas)
#     is copied byte-for-byte from the template; only Synthesis!I8:I11 and the NFR repository's
#     per-row Relevant/Status/Comments/LastUpdate cells are rewritten. Formulas are left
#     untouched - Excel/LibreOffice recalculates them from the new values on open (fullCalcOnLoad
#     is set defensively, see New-NfrWorkbookHeadless).

function Test-ExcelComAvailable {
  <# True only on Windows with Excel actually installed - never assume, always check. #>
  if (-not $IsWindows) { return $false }
  try { $null = New-Object -ComObject Excel.Application -ErrorAction Stop; $null.Quit(); return $true }
  catch { return $false }
}

function Get-XlsxColLetterNfr {
  param([Parameter(Mandatory)][int]$Index)  # 1-based
  $letters = ''
  while ($Index -gt 0) {
    $rem = ($Index - 1) % 26
    $letters = [char](65 + $rem) + $letters
    $Index = [math]::Floor(($Index - 1) / 26)
  }
  return $letters
}

function Get-XlsxSharedStringsNfr {
  <# Read sharedStrings.xml of an xlsx/xlsm into a 0-based string array (rich-text <r> runs
     concatenated, matching how Excel displays a shared string). #>
  param([Parameter(Mandatory)][string]$XlsxPath)
  $full = Resolve-FullPath $XlsxPath
  $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
  try {
    $entry = $zip.GetEntry('xl/sharedStrings.xml')
    if (-not $entry) { return @() }
    $stream = $entry.Open(); $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
    $xml = $reader.ReadToEnd(); $reader.Close()
    $doc = New-Object System.Xml.XmlDocument; $doc.LoadXml($xml)
    $ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
    $ns.AddNamespace('s', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($si in $doc.SelectNodes('//s:sst/s:si', $ns)) {
      $parts = @($si.SelectNodes('.//s:t', $ns) | ForEach-Object { $_.InnerText })
      $out.Add(($parts -join ''))
    }
    return $out.ToArray()
  } finally { $zip.Dispose() }
}

function Read-XlsxSheetXmlEntry {
  param([Parameter(Mandatory)][string]$XlsxPath, [Parameter(Mandatory)][string]$EntryName)
  $full = Resolve-FullPath $XlsxPath
  $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
  try {
    $entry = $zip.GetEntry($EntryName)
    if (-not $entry) { throw "Part not found in workbook: $EntryName" }
    $stream = $entry.Open(); $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
    $txt = $reader.ReadToEnd(); $reader.Close(); return $txt
  } finally { $zip.Dispose() }
}

function Get-XlsxCellTextNfr {
  <# Resolve one cell's display text from a sheet's raw XML (handles t="s" shared-string,
     t="inlineStr", a bare numeric <v>, and an empty/self-closing cell -> ''). #>
  param([Parameter(Mandatory)][string]$SheetXml, [Parameter(Mandatory)][string]$CellRef, [string[]]$SharedStrings = @())
  $m = [regex]::Match($SheetXml, '<c r="' + [regex]::Escape($CellRef) + '"((?:\s+[a-zA-Z0-9:]+="[^"]*")*)\s*(?:/>|>(.*?)</c>)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { return '' }
  $attrs = $m.Groups[1].Value
  $inner = $m.Groups[2].Value
  if ($inner -eq '') { return '' }
  if ($attrs -match 't="s"') {
    $vm = [regex]::Match($inner, '<v>(\d+)</v>')
    if ($vm.Success -and $SharedStrings.Count -gt [int]$vm.Groups[1].Value) { return $SharedStrings[[int]$vm.Groups[1].Value] }
    return ''
  }
  if ($attrs -match 't="inlineStr"') {
    $tm = [regex]::Match($inner, '<t[^>]*>(.*?)</t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($tm.Success) { return [System.Net.WebUtility]::HtmlDecode($tm.Groups[1].Value) }
    return ''
  }
  $vm = [regex]::Match($inner, '<v>(.*?)</v>')
  if ($vm.Success) { return $vm.Groups[1].Value }
  return ''
}

function Read-NfrRepositoryXml {
  <#
    No-COM equivalent of Read-NfrRepository: reads the same columns (Reference, DICT trigger
    flags, RTO/DataPrivacy/SOX triggers, Group) directly from the "NFR repository" sheet's raw
    XML + sharedStrings.xml. Returns the same object shape, so Set-NfrWorkbookHeadless and
    Test-NfrRelevant consume it exactly like the COM path's rows - one code path for the
    filter logic, two ways of reading the inputs.
  #>
  param([Parameter(Mandatory)][string]$WorkbookPath)
  $full = Resolve-FullPath $WorkbookPath
  if (-not (Test-Path $full)) { throw "Workbook not found: $full" }
  $sheetEntry = Resolve-NfrRepositorySheetEntry -XlsxPath $full
  $sheetXml = Read-XlsxSheetXmlEntry -XlsxPath $full -EntryName $sheetEntry
  $shared = Get-XlsxSharedStringsNfr -XlsxPath $full
  $rowMatches = [regex]::Matches($sheetXml, '<row r="(\d+)"[^>]*>(.*?)</row>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  $rows = @()
  foreach ($rm in $rowMatches) {
    $rowNum = [int]$rm.Groups[1].Value
    if ($rowNum -lt $script:DATA_START) { continue }
    $rowXml = $rm.Value
    $ref = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ("B$rowNum") -SharedStrings $shared).Trim()
    if ($ref -notmatch '^NFR') { continue }
    $flags = @()
    foreach ($crit in @(@('D',23),@('I',27),@('C',31),@('T',35))) {
      $lv = @()
      for ($i = 0; $i -lt 4; $i++) {
        $colLetter = Get-XlsxColLetterNfr -Index ($crit[1] + $i)
        $v = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ("$colLetter$rowNum") -SharedStrings $shared).Trim()
        if ($v -ne '') { $lv += ($i + 1) }
      }
      if ($lv.Count -gt 0) { $flags += ($crit[0] + ($lv -join '')) }
    }
    $rows += [pscustomobject]@{
      Reference   = $ref
      Title       = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.Title) + $rowNum) -SharedStrings $shared)
      Group       = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.Group) + $rowNum) -SharedStrings $shared)
      DICTflags   = ($flags -join ',')
      RTO         = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.RTO) + $rowNum) -SharedStrings $shared)
      DataPrivacy = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.DataPrivacy) + $rowNum) -SharedStrings $shared)
      SOX         = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.SOX) + $rowNum) -SharedStrings $shared)
      Row         = $rowNum
    }
  }
  return $rows
}

function Resolve-NfrRepositorySheetEntry {
  <# Find which xl/worksheets/sheetN.xml is the "NFR repository" sheet, by walking
     workbook.xml (sheet name -> r:id) and workbook.xml.rels (r:id -> target), rather than
     assuming a fixed sheetN - the template's internal numbering is an implementation detail
     that a newer template revision could reorder. #>
  param([Parameter(Mandatory)][string]$XlsxPath)
  $wbXml = Read-XlsxSheetXmlEntry -XlsxPath $XlsxPath -EntryName 'xl/workbook.xml'
  $relsXml = Read-XlsxSheetXmlEntry -XlsxPath $XlsxPath -EntryName 'xl/_rels/workbook.xml.rels'
  $sm = [regex]::Match($wbXml, '<sheet name="' + [regex]::Escape($script:REPO_SHEET) + '"[^/]*r:id="(rId\d+)"')
  if (-not $sm.Success) { throw "Sheet '$script:REPO_SHEET' not found in workbook.xml." }
  $rid = $sm.Groups[1].Value
  $rm = [regex]::Match($relsXml, '<Relationship Id="' + [regex]::Escape($rid) + '"[^>]*Target="([^"]+)"')
  if (-not $rm.Success) { throw "Relationship '$rid' not found in workbook.xml.rels." }
  return ('xl/' + $rm.Groups[1].Value)
}

function Set-XlsxCellTextInSheet {
  <# Replace one cell's value in a sheet's XML text, preserving its existing style ("s=...")
     attribute, writing the new value as t="inlineStr" (safe regardless of whether the cell
     was previously empty, numeric, formula-cached or a shared-string reference) and XML-
     escaping the text. Returns the updated sheet XML. Throws if the cell element is not
     found (a template whose column layout changed under us, rather than silently no-op-ing). #>
  param([Parameter(Mandatory)][string]$SheetXml, [Parameter(Mandatory)][string]$CellRef, [Parameter(Mandatory)][AllowEmptyString()][string]$Text)
  $pattern = '<c r="' + [regex]::Escape($CellRef) + '"((?:\s+[a-zA-Z0-9:]+="[^"]*")*)\s*(?:/>|>.*?</c>)'
  $m = [regex]::Match($SheetXml, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { throw "Cell $CellRef not found - template layout may have changed." }
  $styleAttr = ''
  $sm = [regex]::Match($m.Groups[1].Value, '\ss="(\d+)"')
  if ($sm.Success) { $styleAttr = ' s="' + $sm.Groups[1].Value + '"' }
  $esc = $Text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
  if ($esc -eq '') {
    $replacement = '<c r="' + $CellRef + '"' + $styleAttr + '/>'
  } else {
    $replacement = '<c r="' + $CellRef + '"' + $styleAttr + ' t="inlineStr"><is><t xml:space="preserve">' + $esc + '</t></is></c>'
  }
  return $SheetXml.Substring(0, $m.Index) + $replacement + $SheetXml.Substring($m.Index + $m.Length)
}

function Set-XlsxRowHidden {
  <# Set/clear hidden="1" on a <row r="N" ...> element, matching ShowHideRequirements'
     effect of hiding Not-relevant rows without deleting them. #>
  param([Parameter(Mandatory)][string]$SheetXml, [Parameter(Mandatory)][int]$RowNum, [Parameter(Mandatory)][bool]$Hidden)
  $pattern = '<row r="' + $RowNum + '"([^>]*)>'
  $m = [regex]::Match($SheetXml, $pattern)
  if (-not $m.Success) { return $SheetXml }
  $attrs = $m.Groups[1].Value
  $attrs = $attrs -replace '\s+hidden="[01]"', ''
  if ($Hidden) { $attrs += ' hidden="1"' }
  $replacement = '<row r="' + $RowNum + '"' + $attrs + '>'
  return $SheetXml.Substring(0, $m.Index) + $replacement + $SheetXml.Substring($m.Index + $m.Length)
}

function New-NfrWorkbookHeadless {
  <#
    No-COM path for new-nfr-workbook.ps1: produces the same filled .xlsm (system parameters +
    computed Relevant + project Status/Comments + hidden Not-relevant rows) without Excel,
    using Test-NfrRelevant (see the module-level note above) instead of the VBA macro.
    Returns [pscustomobject]@{ RelevantYes; RelevantNo; WithStatus; Unknown[] }.
  #>
  param(
    [Parameter(Mandatory)][string]$Template,
    [Parameter(Mandatory)][string]$OutFile,
    [Parameter(Mandatory)][hashtable]$Dict,       # @{D=;I=;C=;T=} from ConvertFrom-Dict
    [Parameter(Mandatory)][int]$Rto,
    [Parameter(Mandatory)][bool]$Sox,
    [Parameter(Mandatory)][bool]$DataPrivacy,
    [string]$DictString, [string]$RtoString, [string]$SoxString, [string]$DataPrivacyString, [string]$AppName,
    [hashtable]$DecisionMap = @{},
    [switch]$HideFiltered
  )
  $tplFull = Resolve-FullPath $Template
  $sheetEntry = Resolve-NfrRepositorySheetEntry -XlsxPath $tplFull
  $synEntry = Resolve-NfrSynthesisSheetEntry -XlsxPath $tplFull
  $shared = Get-XlsxSharedStringsNfr -XlsxPath $tplFull

  $repoXml = Read-XlsxSheetXmlEntry -XlsxPath $tplFull -EntryName $sheetEntry
  $synXml = Read-XlsxSheetXmlEntry -XlsxPath $tplFull -EntryName $synEntry
  $wbXml = Read-XlsxSheetXmlEntry -XlsxPath $tplFull -EntryName 'xl/workbook.xml'

  # Synthesis: system parameters (same cells the COM path writes - F4/I8/I9/I10/I11).
  if ($AppName)            { $synXml = Set-XlsxCellTextInSheet -SheetXml $synXml -CellRef 'F4'  -Text $AppName }
  if ($DataPrivacyString)  { $synXml = Set-XlsxCellTextInSheet -SheetXml $synXml -CellRef 'I8'  -Text $DataPrivacyString }
  if ($DictString)         { $synXml = Set-XlsxCellTextInSheet -SheetXml $synXml -CellRef 'I9'  -Text $DictString }
  if ($RtoString)          { $synXml = Set-XlsxCellTextInSheet -SheetXml $synXml -CellRef 'I10' -Text $RtoString }
  if ($SoxString)          { $synXml = Set-XlsxCellTextInSheet -SheetXml $synXml -CellRef 'I11' -Text $SoxString }

  $rowMatches = [regex]::Matches($repoXml, '<row r="(\d+)"[^>]*>(.*?)</row>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  $today = (Get-Date).ToString('dd/MM/yyyy')
  $relevantYes = 0; $relevantNo = 0; $withStatus = 0
  $seen = @{}
  foreach ($rm in $rowMatches) {
    $rowNum = [int]$rm.Groups[1].Value
    if ($rowNum -lt $script:DATA_START) { continue }
    $rowXml = $rm.Value
    $ref = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ("B$rowNum") -SharedStrings $shared).Trim()
    if ($ref -notmatch '^NFR') { continue }
    $seen[$ref] = $true

    $flags = @()
    foreach ($crit in @(@('D',23),@('I',27),@('C',31),@('T',35))) {
      $lv = @()
      for ($i = 0; $i -lt 4; $i++) {
        $colLetter = Get-XlsxColLetterNfr -Index ($crit[1] + $i)
        $v = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ("$colLetter$rowNum") -SharedStrings $shared).Trim()
        if ($v -ne '') { $lv += ($i + 1) }
      }
      if ($lv.Count -gt 0) { $flags += ($crit[0] + ($lv -join '')) }
    }
    $rtoTrig = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.RTO) + $rowNum) -SharedStrings $shared).Trim()
    $dpTrig  = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.DataPrivacy) + $rowNum) -SharedStrings $shared).Trim()
    $soxTrig = (Get-XlsxCellTextNfr -SheetXml $rowXml -CellRef ((Get-XlsxColLetterNfr -Index $script:COL.SOX) + $rowNum) -SharedStrings $shared).Trim()

    $relevant = Test-NfrRelevant -D $Dict.D -I $Dict.I -C $Dict.C -T $Dict.T -Rto $Rto -Sox $Sox -DataPrivacy $DataPrivacy `
      -DICTflags ($flags -join ',') -RtoTrigger $rtoTrig -DpTrigger $dpTrig -SoxTrigger $soxTrig

    $d = if ($DecisionMap.ContainsKey($ref)) { $DecisionMap[$ref] } else { $null }
    $relCol = (Get-XlsxColLetterNfr -Index $script:COL.Relevant) + $rowNum
    $staCol = (Get-XlsxColLetterNfr -Index $script:COL.Status) + $rowNum
    $comCol = (Get-XlsxColLetterNfr -Index $script:COL.Comments) + $rowNum
    $updCol = (Get-XlsxColLetterNfr -Index $script:COL.LastUpdate) + $rowNum

    $repoXml = Set-XlsxCellTextInSheet -SheetXml $repoXml -CellRef $relCol -Text $relevant
    if ($relevant -eq 'No') {
      $repoXml = Set-XlsxCellTextInSheet -SheetXml $repoXml -CellRef $staCol -Text 'Not relevant'
      if ($d -and $d.Comment) { $repoXml = Set-XlsxCellTextInSheet -SheetXml $repoXml -CellRef $comCol -Text $d.Comment }
      $relevantNo++
      if ($HideFiltered) { $repoXml = Set-XlsxRowHidden -SheetXml $repoXml -RowNum $rowNum -Hidden $true }
    } else {
      if ($d -and $d.Status)  { $repoXml = Set-XlsxCellTextInSheet -SheetXml $repoXml -CellRef $staCol -Text $d.Status; $withStatus++ }
      if ($d -and $d.Comment) { $repoXml = Set-XlsxCellTextInSheet -SheetXml $repoXml -CellRef $comCol -Text $d.Comment }
      $relevantYes++
    }
    $repoXml = Set-XlsxCellTextInSheet -SheetXml $repoXml -CellRef $updCol -Text $today
  }
  $unknown = @($DecisionMap.Keys | Where-Object { -not $seen.ContainsKey($_) })

  # Force a full recalculation on open, since formulas elsewhere in the workbook (Synthesis
  # charts, hidden helper columns) depend on the cells just rewritten above.
  if ($wbXml -match '<calcPr[^/]*/>') {
    $wbXml = [regex]::Replace($wbXml, '<calcPr([^/]*)/>', { param($mm) if ($mm.Value -match 'fullCalcOnLoad') { $mm.Value } else { '<calcPr' + $mm.Groups[1].Value + ' fullCalcOnLoad="1"/>' } })
  } else {
    $wbXml = $wbXml -replace '</workbook>', '<calcPr fullCalcOnLoad="1"/></workbook>'
  }

  # Re-zip: copy every template part byte-for-byte except the 3 rewritten text parts
  # (preserves styles, charts, the VBA project, theme, everything - same technique as
  # RightMatrixXlsx.psm1 for the access-right-matrix skill).
  $outFull = Resolve-FullPath $OutFile
  $outDir = Split-Path $outFull -Parent
  if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
  if (Test-Path $outFull) { Remove-Item $outFull -Force }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  $srcZip = [System.IO.Compression.ZipFile]::OpenRead($tplFull)
  try {
    $fs = [System.IO.File]::Open($outFull, [System.IO.FileMode]::Create)
    try {
      $destZip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
      try {
        foreach ($e in $srcZip.Entries) {
          $newEntry = $destZip.CreateEntry($e.FullName, [System.IO.Compression.CompressionLevel]::Optimal)
          $es = $newEntry.Open()
          if ($e.FullName -eq $sheetEntry) { $bytes = $utf8.GetBytes($repoXml) }
          elseif ($e.FullName -eq $synEntry) { $bytes = $utf8.GetBytes($synXml) }
          elseif ($e.FullName -eq 'xl/workbook.xml') { $bytes = $utf8.GetBytes($wbXml) }
          else {
            $ins = $e.Open()
            $ms = New-Object System.IO.MemoryStream
            $ins.CopyTo($ms)
            $bytes = $ms.ToArray()
            $ins.Close()
          }
          $es.Write($bytes, 0, $bytes.Length)
          $es.Close()
        }
      } finally { $destZip.Dispose() }
    } finally { $fs.Dispose() }
  } finally { $srcZip.Dispose() }

  return [pscustomobject]@{ RelevantYes = $relevantYes; RelevantNo = $relevantNo; WithStatus = $withStatus; Unknown = $unknown }
}

function Resolve-NfrSynthesisSheetEntry {
  param([Parameter(Mandatory)][string]$XlsxPath)
  $wbXml = Read-XlsxSheetXmlEntry -XlsxPath $XlsxPath -EntryName 'xl/workbook.xml'
  $relsXml = Read-XlsxSheetXmlEntry -XlsxPath $XlsxPath -EntryName 'xl/_rels/workbook.xml.rels'
  $sm = [regex]::Match($wbXml, '<sheet name="' + [regex]::Escape($script:SYN_SHEET) + '"[^/]*r:id="(rId\d+)"')
  if (-not $sm.Success) { throw "Sheet '$script:SYN_SHEET' not found in workbook.xml." }
  $rid = $sm.Groups[1].Value
  $rm = [regex]::Match($relsXml, '<Relationship Id="' + [regex]::Escape($rid) + '"[^>]*Target="([^"]+)"')
  if (-not $rm.Success) { throw "Relationship '$rid' not found in workbook.xml.rels." }
  return ('xl/' + $rm.Groups[1].Value)
}

function Write-NfrHeadlessNotice {
  <# One-line notice to put in the project's nfr_requirements_README.md whenever the
     headless path was used, per the trade-off documented above - never silent. #>
  "Generated WITHOUT Excel (Test-NfrRelevant headless path, matched 131/133 NFRs of the real project checked end-to-end - see NfrRepo.psm1) because no Excel COM was available in this environment. Spot-check, before finalizing Status, any NFR reference ending in a letter (a/b/c...) that also carries a DICT trigger on more than one criterion (D/I/C/T) - these are the one known class of divergence from the model's own macro. If Excel later becomes available, regenerate once with the macro path to confirm."
}

Export-ModuleMember -Function New-ExcelApp, Close-ExcelApp, Resolve-FullPath,
  Get-NfrRow, Read-NfrRepository, Test-NfrRelevant, ConvertFrom-Dict, `
  Test-ExcelComAvailable, Read-NfrRepositoryXml, New-NfrWorkbookHeadless, Write-NfrHeadlessNotice `
  -Variable REPO_SHEET, SYN_SHEET, COL, HEADER_ROW, DATA_START
