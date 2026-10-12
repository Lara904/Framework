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

$rows = Read-NfrRepository -WorkbookPath $Workbook
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("Reference`tRelevant`tStatus`tGroup`tDICTflags`tRTO`tDataPrivacy`tSOX`tTitle")
foreach ($r in $rows) {
  $title = $r.Title -replace "`r?`n",' '
  [void]$sb.AppendLine(("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}" -f `
    $r.Reference,$r.Relevant,$r.Status,$r.Group,$r.DICTflags,$r.RTO,$r.DataPrivacy,$r.SOX,$title))
}
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Write-Host ("Wrote {0} ({1} NFRs)." -f $Out, $rows.Count)
Write-Host "--- Status summary ---"
$rows | Group-Object Status | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count) }
Write-Host "--- Relevant summary ---"
$rows | Group-Object Relevant | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count) }
