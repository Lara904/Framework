<#
.SYNOPSIS
  Dump the NFR repository of a workbook (the reference model or a filled deliverable) to a
  TSV file and print a short summary. Read-only: never modifies the workbook.

.PARAMETER Workbook
  Path to the .xlsm/.xlsx to read. Defaults to the bundled reference template.

.PARAMETER Out
  Path of the TSV to write. Defaults to "<Workbook>_dump.tsv" next to the workbook.

.EXAMPLE
  .\export-nfr.ps1 -Workbook ..\..\..\..\output\${project_name}\${project_name}_NFR.xlsm -Out review.tsv
  (the workbook lives in output/${project_name}/ per the output-convention steering)
#>
[CmdletBinding()]
param(
  [string]$Workbook,
  [string]$Out
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'NfrRepo.psm1') -Force

if (-not $Workbook) {
  $Workbook = Join-Path $PSScriptRoot '..\templates\DP-MD18-EN_Non-Functional_Requirements.xlsm'
}
$Workbook = Resolve-FullPath $Workbook
if (-not $Out) { $Out = [System.IO.Path]::ChangeExtension($Workbook, $null).TrimEnd('.') + '_dump.tsv' }
$Out = Resolve-FullPath $Out

# Auto-detect COM (same test new-nfr-workbook.ps1 uses) instead of calling the COM-only
# Read-NfrRepository unconditionally: that threw immediately on every non-Windows host ("A
# parameter cannot be found that matches parameter name 'ComObject'"), so a workbook built by
# the headless write path could never be reviewed on the same host that built it.
if (Test-ExcelComAvailable) {
  $rows = Read-NfrRepository -WorkbookPath $Workbook
} else {
  Write-Warning "No Excel COM available on this host - reading via the headless (no-Excel) XML path (Read-NfrRepositoryXml)."
  $rows = Read-NfrRepositoryXml -WorkbookPath $Workbook
}
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("Reference`tRelevant`tStatus`tGroup`tDICTflags`tRTO`tDataPrivacy`tSOX`tComments`tTitle")
foreach ($r in $rows) {
  $title = $r.Title -replace "`r?`n",' '
  $comments = $r.Comments -replace "`r?`n",' '
  [void]$sb.AppendLine(("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}" -f `
    $r.Reference,$r.Relevant,$r.Status,$r.Group,$r.DICTflags,$r.RTO,$r.DataPrivacy,$r.SOX,$comments,$title))
}
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Write-Host ("Wrote {0} ({1} NFRs)." -f $Out, $rows.Count)
Write-Host "--- Status summary ---"
$rows | Group-Object Status | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count) }
Write-Host "--- Relevant summary ---"
$rows | Group-Object Relevant | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count) }

# Blank-comment check (SKILL.md rule 6/10): a relevant NFR left at Proposed/Accepted with an
# EMPTY Comments cell is invisible to the README's Missing-information table unless that table
# also treats "empty" as missing, not only a literal TBC/TBD string - surface it here so it is
# never discovered only once the README is already written.
$relevantNoComment = @($rows | Where-Object { $_.Relevant -eq 'Yes' -and [string]::IsNullOrWhiteSpace($_.Comments) })
Write-Host "--- Relevant NFRs with an EMPTY Comments cell (must get a line in the README's Missing information table) ---"
if ($relevantNoComment.Count -eq 0) {
  Write-Host "  None - every relevant NFR has a comment."
} else {
  Write-Host ("  {0} of {1} relevant NFRs have no comment:" -f $relevantNoComment.Count, (@($rows | Where-Object { $_.Relevant -eq 'Yes' }).Count))
  $relevantNoComment | ForEach-Object { Write-Host ("    {0} ({1})" -f $_.Reference, $_.Status) }
}
