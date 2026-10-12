<#
.SYNOPSIS
  Produce a project NFR deliverable (.xlsm/.xlsx) from the reference model, by copying the
  bundled template and filling the system parameters + per-NFR decisions.

.DESCRIPTION
  The reference model is NEVER modified. This script copies it to -Out, writes the four
  system parameters on the "Synthesis" sheet (DICT / RTO / SOX / Data privacy), then fills the
  NFR repository.

  IMPORTANT - the "Relevant" column is computed ONLY by the model's own filter macro. This mirrors
  the human process: after writing the system parameters the script runs the model's filter macro
  ('RequirementsFilter') and its row-hiding macro ('ShowHideRequirements') via COM (Application.Run
  with AutomationSecurity=Low). No other calculation method is permitted. If the macro cannot run,
  the script saves the workbook with the parameters filled and STOPS with an instruction for the
  user to open Excel, run the filter macro manually, save, and come back for the NFR analysis.
  You never hand-set Relevant; the project's judgement is expressed only through Status + Comment.

  Decisions come from a delimited file (-Decisions), one row per NFR, with a header line:
      Reference<TAB>Status<TAB>Comment
  Accepts TAB, ';' or ',' as delimiter (auto-detected from the header line). A legacy
  "Relevant" column is accepted but IGNORED (Relevant is always computed).
  Status = Proposed | Accepted | Implemented | Verified | Not relevant | Not feasible
  For a computed-relevant NFR (Relevant = Yes), set the project Status. For a computed-NOT-relevant
  NFR the script sets Status = "Not relevant" automatically; any decision Status you give for such
  a row is ignored (a filtered-out NFR is Not relevant by definition). Only comments are applied
  to every listed row.

.PARAMETER Template
  Path to the reference workbook. Defaults to the bundled template next to this script.

.PARAMETER Out
  Output path of the filled deliverable (e.g. output/${project_name}/${project_name}_NFR.xlsm). Required.

.PARAMETER Decisions
  Path to the decisions file (see DESCRIPTION). Optional: if omitted, only the system
  parameters are written and every NFR keeps its default (Relevant "To be defined").

.PARAMETER Dict   4-digit DICT string, e.g. "1111" or "2221".
.PARAMETER Rto    RTO class 1..8, or 9 = not involved.
.PARAMETER Sox    "Yes" / "No".
.PARAMETER DataPrivacy  Data privacy risk level: No / A / B / C / D.
.PARAMETER AppName      Functional application name (Synthesis sheet).
.PARAMETER NoHideFiltered  By default the script hides the filtered-out (Not relevant) NFR rows,
  reproducing the model's "Display parameters" behaviour so the deliverable shows only the
  relevant requirements. Use this switch to keep every row visible.

.EXAMPLE
  .\new-nfr-workbook.ps1 -Out ..\..\..\..\output\${project_name}\${project_name}_NFR.xlsm `
     -Dict 1111 -Rto 9 -Sox No -DataPrivacy No -AppName "<application name>" `
     -Decisions .\decisions.tsv
  (write the workbook to output/${project_name}/ per the output-convention steering)
#>
[CmdletBinding()]
param(
  [string]$Template,
  [Parameter(Mandatory)][string]$Out,
  [string]$Decisions,
  [Parameter(Mandatory)][string]$Dict,
  [Parameter(Mandatory)][string]$Rto,
  [Parameter(Mandatory)][string]$Sox,
  [Parameter(Mandatory)][string]$DataPrivacy,
  [string]$AppName,
  [switch]$NoHideFiltered
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'NfrRepo.psm1') -Force

if (-not $Template) {
  $Template = Join-Path $PSScriptRoot '..\templates\DP-MD18-EN_Non-Functional_Requirements.xlsm'
}
$Template = Resolve-FullPath $Template
if (-not (Test-Path $Template)) { throw "Template not found: $Template" }
$OutFull = Resolve-FullPath $Out

# --- 1. Copy the template to a LOCAL working file ----------------------------------------
# Important: Excel COM Save() is silently discarded when the file lives in a synced folder
# (OneDrive/SharePoint). Always edit a copy under $env:TEMP, then move it to the destination.
$outDir = Split-Path $OutFull -Parent
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$ext = [System.IO.Path]::GetExtension($OutFull)
if (-not $ext) { $ext = '.xlsm' }
$work = Join-Path $env:TEMP ("nfr_build_" + [System.Guid]::NewGuid().ToString('N') + $ext)
Copy-Item $Template $work -Force
Write-Host "Working copy: $work"

# --- 2. Parse decisions ------------------------------------------------------------------
# NB: PowerShell variable names are case-insensitive, so this map must NOT be named
# $decisions (it would collide with the -Decisions parameter).
$decisionMap = @{}
if ($Decisions) {
  $dPath = Resolve-FullPath $Decisions
  if (-not (Test-Path $dPath)) { throw "Decisions file not found: $dPath" }
  $lines = Get-Content -LiteralPath $dPath -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
  if ($lines.Count -lt 1) { throw "Decisions file is empty." }
  $header = $lines[0]
  $delim = if ($header -match "`t") { "`t" } elseif ($header -match ';') { ';' } else { ',' }
  $cols = $header.Split($delim) | ForEach-Object { $_.Trim().ToLower() }
  $iRef = [array]::IndexOf($cols,'reference'); if ($iRef -lt 0) { $iRef = 0 }
  $iSta = [array]::IndexOf($cols,'status')
  $iCom = [array]::IndexOf($cols,'comment'); if ($iCom -lt 0) { $iCom = [array]::IndexOf($cols,'comments') }
  # A legacy "relevant" column is tolerated but ignored (Relevant is always computed).
  for ($i=1; $i -lt $lines.Count; $i++) {
    $p = $lines[$i].Split($delim)
    $ref = $p[$iRef].Trim()
    if ($ref -eq '') { continue }
    $decisionMap[$ref] = [pscustomobject]@{
      Status   = if ($iSta -ge 0 -and $iSta -lt $p.Count) { $p[$iSta].Trim() } else { '' }
      Comment  = if ($iCom -ge 0 -and $iCom -lt $p.Count) { $p[$iCom].Trim() } else { '' }
    }
  }
  Write-Host ("Parsed {0} decision(s)." -f $decisionMap.Count)
}

# Validate the DICT format early (so we fail before opening Excel if it is malformed).
[void](ConvertFrom-Dict $Dict)

# --- 3. Open the working copy and fill it ------------------------------------------------
$xl = New-ExcelApp
# msoAutomationSecurityLow (1): enable the workbook's macros without prompting, so we can run
# the model's own filter macro (the human process: press the filter button).
try { $xl.AutomationSecurity = 1 } catch {}
$wb = $xl.Workbooks.Open($work)
try {
  # 3a. System parameters on Synthesis
  $syn = $wb.Worksheets.Item($SYN_SHEET)
  if ($AppName)     { $syn.Cells.Item(4, 6).Value2  = $AppName }     # F4 (next to "Functional application name")
  if ($DataPrivacy) { $syn.Cells.Item(8, 9).Value2  = $DataPrivacy } # I8
  if ($Dict)        { $syn.Cells.Item(9, 9).Value2  = $Dict }        # I9
  if ($Rto)         { $syn.Cells.Item(10, 9).Value2 = $Rto }         # I10
  if ($Sox)         { $syn.Cells.Item(11, 9).Value2 = $Sox }         # I11
  Write-Host "Wrote system parameters (DICT/RTO/SOX/Data privacy)."

  # 3b. Compute Relevant with the MODEL'S OWN MACRO - the only authorised method. If the macro
  #     cannot run, we do NOT compute relevance any other way: we save the file with the system
  #     parameters written, and stop with a clear instruction for the user to run the macro
  #     manually (see the terminating error at the end of this block).
  $repo = $wb.Worksheets.Item($REPO_SHEET)
  $macroError = $null
  # The RequirementsFilter macro shows a modal VBA MsgBox (Oui/Non "Do you want to continue?")
  # that blocks Application.Run. Start a background watcher that auto-confirms it (Enter = Oui).
  $dismisser = Start-Job -FilePath (Join-Path $PSScriptRoot 'Dismiss-FilterDialog.ps1') `
    -ArgumentList 180, 'Requirements filter'
  try {
    $xl.Run('RequirementsFilter')                              # fills Relevant + Status (macro confirms via watcher)
    if (-not $NoHideFiltered) { $xl.Run('ShowHideRequirements') } # hides Not-relevant rows
    Write-Host "Filter computed by the model's macro (RequirementsFilter)."
  } catch {
    $macroError = $_.Exception.Message
  } finally {
    if ($dismisser) { Stop-Job $dismisser -ErrorAction SilentlyContinue; Remove-Job $dismisser -Force -ErrorAction SilentlyContinue }
  }

  if ($macroError) {
    # Save the parameters we already wrote so the user can just open + click the button, then quit.
    try { $wb.Save() } catch {}
    Close-ExcelApp -xl $xl -wb $wb
    $wb = $null; $xl = $null   # prevent the outer finally from double-closing released COM objects
    Start-Sleep -Milliseconds 500
    Copy-Item $work $OutFull -Force
    Remove-Item $work -Force -ErrorAction SilentlyContinue
    throw @"
The model's filter macro could not be run automatically ($macroError).
The filter macro is the ONLY authorised way to compute the Relevant column - no other
calculation method is permitted.

A workbook with the system parameters already filled has been written to:
  $OutFull

Please finish it manually in Excel:
  1. Open the workbook and check the Synthesis sheet parameters
     (DICT=$Dict, RTO=$Rto, SOX=$Sox, Data privacy=$DataPrivacy).
  2. Click the filter button (macro 'RequirementsFilter') and enable the
     'show/hide' display option ('ShowHideRequirements') if needed.
  3. Save and come back: I will then review the filtered NFRs and set the
     Status / date / comment for the relevant ones.
"@
  }

  $today = (Get-Date).ToString('dd/MM/yyyy')
  $last = $repo.UsedRange.Rows.Count
  $seen = @{}
  $relevantYes = 0; $relevantNo = 0; $withStatus = 0
  for ($r = $DATA_START; $r -le $last; $r++) {
    $ref = ('' + $repo.Cells.Item($r, $COL.Reference).Value2).Trim()
    if ($ref -notmatch '^NFR') { continue }
    $seen[$ref] = $true

    # Relevant is whatever the macro wrote - never recomputed.
    $relevant = ('' + $repo.Cells.Item($r, $COL.Relevant).Value2).Trim()

    $d = if ($decisionMap.ContainsKey($ref)) { $decisionMap[$ref] } else { $null }
    if ($relevant -eq 'No') {
      # Filtered out: Not relevant by definition. Keep a comment if the project gave one.
      $repo.Cells.Item($r, $COL.Status).Value2 = 'Not relevant'
      if ($d -and $d.Comment) { $repo.Cells.Item($r, $COL.Comments).Value2 = $d.Comment }
      $relevantNo++
    } else {
      # Relevant: apply the project's Status and comment (Relevant stays as computed).
      if ($d -and $d.Status)  { $repo.Cells.Item($r, $COL.Status).Value2 = $d.Status; $withStatus++ }
      if ($d -and $d.Comment) { $repo.Cells.Item($r, $COL.Comments).Value2 = $d.Comment }
      $relevantYes++
    }
    $repo.Cells.Item($r, $COL.LastUpdate).Value2 = $today
  }
  Write-Host ("Relevant: {0} Yes / {1} No. Project status set on {2} relevant NFR(s)." -f $relevantYes, $relevantNo, $withStatus)
  $unknown = $decisionMap.Keys | Where-Object { -not $seen.ContainsKey($_) }
  if ($unknown) { Write-Warning ("Decision references not found in the model (ignored): " + ($unknown -join ', ')) }

  $wb.Save()
  Write-Host "Saved working copy."
} finally {
  Close-ExcelApp -xl $xl -wb $wb
}

# --- 4. Move the finished file to the (possibly synced) destination ----------------------
Start-Sleep -Milliseconds 500
Copy-Item $work $OutFull -Force
Remove-Item $work -Force -ErrorAction SilentlyContinue
Write-Host "Deliverable written: $OutFull"
