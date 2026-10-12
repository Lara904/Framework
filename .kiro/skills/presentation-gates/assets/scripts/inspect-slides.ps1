# inspect-slides.ps1
# Dump the visible text of each slide of a .pptx (position -> text), in true display order.
# Usage: powershell -ExecutionPolicy Bypass -File inspect-slides.ps1 -Pptx "deck.pptx" [-MaxChars 300]
param(
    [Parameter(Mandatory = $true)][string]$Pptx,
    [int]$MaxChars = 300
)

Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force

Get-PptxSlides -Pptx $Pptx | ForEach-Object {
    $t = $_.Text
    if ($MaxChars -gt 0 -and $t.Length -gt $MaxChars) { $t = $t.Substring(0, $MaxChars) + '...' }
    "POS $($_.Position) ($($_.File)): $t"
}
