# set-banners.ps1
# Add colour-coded status corner banners to a gates deck (thin wrapper over PptxGates.psm1):
#   ORANGE "TO VALIDATE" = content filled, awaiting stakeholder validation
#   RED    "TO COMPLETE"  = data still missing / leftover guidance
#
# Two modes:
#   Explicit:  -Status validate|complete|clear -Positions 11,12,15
#   Auto:      -Auto [-Gate all|1|2|3|4] [-Validated 11,12,14] [-MinText 200]
#     For every in-scope, visible slide (SKIP/hidden are left untouched):
#       - RED "TO COMPLETE"  if the missing-data heuristic finds leftover placeholders/guidance,
#         OR the slide is an empty/stub (visible text shorter than -MinText chars);
#       - ORANGE "TO VALIDATE" if it has substantial content and no missing markers;
#       - CLEARED (no banner) if its position is listed in -Validated (already signed off).
#     -MinText (default 200) is the char threshold below which a marker-free slide is treated as
#     an empty stub (RED) rather than validated content (ORANGE) - so blank template slides are
#     not mislabelled "to validate".
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File set-banners.ps1 -Pptx "deck.pptx" -Auto -Gate all -Validated 11,12,14,15,27
#   powershell -ExecutionPolicy Bypass -File set-banners.ps1 -Pptx "deck.pptx" -Status validate -Positions 11,12
#   powershell -ExecutionPolicy Bypass -File set-banners.ps1 -Pptx "deck.pptx" -Status clear -Positions 11
param(
    [Parameter(Mandatory = $true)][string]$Pptx,
    [ValidateSet('validate', 'complete', 'clear')][string]$Status,
    [int[]]$Positions,
    [switch]$Auto,
    [ValidateSet('all', '1', '2', '3', '4')][string]$Gate = 'all',
    [int[]]$Validated = @(),
    [int]$MinText = 200,
    [string]$Label
)

Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force

if ($Auto) {
    $meta = Get-SlideMap
    $sec = if ($Gate -eq 'all') { @('G1', 'G2', 'G3', 'G4', 'GEN') } else { @("G$Gate") }

    $complete = New-Object System.Collections.Generic.List[int]   # RED - to complete
    $tovalidate = New-Object System.Collections.Generic.List[int] # ORANGE - to validate
    $validatedHit = New-Object System.Collections.Generic.List[int] # CLEARED
    foreach ($s in Get-PptxSlides -Pptx $Pptx) {
        if (-not $s.Visible) { continue }
        $tags = $meta[$s.Position].G
        if (-not $tags) { continue }
        if ($tags -contains 'SKIP') { continue }
        $inScope = ($Gate -eq 'all') -or ($tags | Where-Object { $sec -contains $_ })
        if (-not $inScope) { continue }
        if ($Validated -contains $s.Position) { $validatedHit.Add($s.Position); continue }
        $markers = Get-MissingMarkers -Text $s.Text
        $textLen = ($s.Text -replace '\s', '').Length
        if ($markers.Count -gt 0 -or $textLen -lt $MinText) { $complete.Add($s.Position) }
        else { $tovalidate.Add($s.Position) }
    }

    $res = @()
    if ($complete.Count -gt 0)     { $res += Set-PptxSlideBanner -Pptx $Pptx -Positions $complete.ToArray()     -Status complete }
    if ($tovalidate.Count -gt 0)   { $res += Set-PptxSlideBanner -Pptx $Pptx -Positions $tovalidate.ToArray()   -Status validate }
    if ($validatedHit.Count -gt 0) { $res += Set-PptxSlideBanner -Pptx $Pptx -Positions $validatedHit.ToArray() -Status clear }

    Write-Output ("Auto banners: {0} to-complete (red), {1} to-validate (orange), {2} validated (cleared)." -f $complete.Count, $tovalidate.Count, $validatedHit.Count)
    $res | Sort-Object Position | ForEach-Object { '  Slide {0}: {1}' -f $_.Position, $_.Reason }
    return
}

if (-not $Status -or -not $Positions) {
    throw "Provide either -Auto, or both -Status and -Positions."
}
$params = @{ Pptx = $Pptx; Positions = $Positions; Status = $Status }
if ($Label) { $params.Label = $Label }
$res = Set-PptxSlideBanner @params
$res | ForEach-Object { 'Slide {0}: {1}' -f $_.Position, $_.Reason }
