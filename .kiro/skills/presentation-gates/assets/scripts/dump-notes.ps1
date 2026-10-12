# dump-notes.ps1
# Dump slide text + speaker notes for each slide of a .pptx (fill-in guidance), display order.
# Usage: powershell -ExecutionPolicy Bypass -File dump-notes.ps1 -Pptx "deck.pptx" [-Out "dump.txt"]
param(
    [Parameter(Mandatory = $true)][string]$Pptx,
    [string]$Out = 'slides_dump.txt'
)

Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force

$lines = New-Object System.Collections.Generic.List[string]
foreach ($s in Get-PptxSlides -Pptx $Pptx -IncludeNotes) {
    $lines.Add('=======================================================')
    $lines.Add("POS $($s.Position)  ($($s.File))")
    $lines.Add('--- SLIDE TEXT ---')
    $lines.Add($s.Text)
    if ($s.Notes) {
        $lines.Add('--- SPEAKER NOTES ---')
        $lines.Add($s.Notes)
    }
}

$outPath = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location).Path $Out }
[System.IO.File]::WriteAllText($outPath, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Wrote $outPath"
