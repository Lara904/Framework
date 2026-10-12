# validate-deck.ps1
# Verify a generated deck is sound BEFORE the user opens it, so PowerPoint never needs to
# "repair" it (repair can silently drop edited slides - e.g. a filled slide 10 disappearing).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File validate-deck.ps1 -Pptx "deck.pptx" [-Gate 1|2|3|4|all] [-Reference <template.pptx>]
#
# Checks (via the shared PptxGates module):
#   - the OPC package opens (System.IO.Packaging) - authoritative "would PowerPoint repair?"
#   - every XML/rels part is well-formed
#   - physical slide parts == Content_Types overrides == sldIdLst entries
#   - no ' />' re-serialization artifact (XmlDocument.Save round-trip -> repair trigger)
#   - all slides required for the gate are present (structure, not content)
# Exit code 0 = OK, 1 = problems found.
param(
    [Parameter(Mandatory = $true)][string]$Pptx,
    [ValidateSet('1', '2', '3', '4', 'all')][string]$Gate = 'all',
    [string]$Reference
)

Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force

$fail = $false

$integ = if ($Reference) { Test-PptxIntegrity -Pptx $Pptx -ReferencePptx $Reference } else { Test-PptxIntegrity -Pptx $Pptx }
Write-Output "== Integrity =="
Write-Output ("Slides: {0} | Content_Types overrides: {1} | sldIdLst: {2}" -f $integ.SlideParts, $integ.ContentTypeOverrides, $integ.SldIdEntries)
if ($integ.Errors.Count) { $fail = $true; $integ.Errors | ForEach-Object { Write-Output ("ERROR: " + $_) } }
if ($integ.Warnings.Count) { $integ.Warnings | ForEach-Object { Write-Output ("WARN:  " + $_) } }
if (-not $integ.Errors.Count -and -not $integ.Warnings.Count) { Write-Output "No integrity issues." }

Write-Output ""
Write-Output ("== Required slides present (Gate $Gate) ==")
$struct = Test-GateSlidesPresent -Pptx $Pptx -Gate $Gate
if ($struct.Ok) {
    Write-Output ("All required slides present ({0} slides total)." -f $struct.Total)
}
else {
    $fail = $true
    Write-Output "MISSING required slides:"
    $struct.Missing | ForEach-Object { Write-Output ("  - Slide {0} - {1}" -f $_.Position, $_.Title) }
}

Write-Output ""
if ($fail) { Write-Output "RESULT: PROBLEMS FOUND"; exit 1 } else { Write-Output "RESULT: OK"; exit 0 }
