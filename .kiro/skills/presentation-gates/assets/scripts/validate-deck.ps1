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
#   - CONTENT gates (added after a real delivered deck shipped both defects):
#       * no genuine leftover highlight on a visible, non-SKIP slide (Get-PptxLeftoverHighlightCount)
#       * no leftover template INSTRUCTION text ("Insert here...", "add here the link...", an
#         unremoved "Example" row, etc. - Get-HardFailMarkers) on a visible, non-SKIP slide.
#     TBD/TODO/Yes-No-to-decide and similar are NOT checked here (SKILL.md rule 8 allows them
#     as a deliberate marker for a genuinely unknown value) - only find-missing.ps1 reports those,
#     as an informational checklist, not a build failure.
#   - the "Reference & examples" section (positions 71-75: divider, Subject Matter Experts,
#     Flow mapping guideline, and the two "- EXAMPLE" slides) must be HIDDEN (show="0") in the
#     final delivered deck. This section is tagged SKIP (never filled, never checked for leftover
#     text/highlight above - see line 60), which is correct for a WORKING copy but means nothing
#     else in this script ever looks at it either: a real delivered deck shipped with its EXAMPLE
#     As-Is/To-Be diagram and macro-schedule timeline fully visible to the ARB because rule 5
#     ("hide non-applicable slides per the Applicability slide") only covers domain-applicability,
#     not this always-irrelevant, author-facing reference material. SKILL.md rule 5 has been
#     extended (5c) to require hiding 71-75 before delivery; this check enforces it so a missed
#     step fails the build instead of reaching a Gate reviewer.
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
Write-Output "== Content (leftover highlight / template instruction text) =="
$slideMap = Get-SlideMap
$slides = @(Get-PptxSlides -Pptx $Pptx -IncludeNotes:$false)
$hlHits = @()
$markerHits = @()
foreach ($s in $slides) {
    if (-not $s.Visible) { continue }
    $tags = @(Get-SlideGateTags -Slide $s -SlideMap $slideMap)
    if ($tags -contains 'SKIP') { continue }   # front matter, dividers, reference/example slides
    $sxml = Get-PptxSlideXml -Pptx $Pptx -Position $s.Position
    $hl = Get-PptxLeftoverHighlightCount -SlideXml $sxml
    if ($hl -gt 0) { $hlHits += [pscustomobject]@{ Position = $s.Position; Count = $hl }; $fail = $true }
    $hf = @(Get-HardFailMarkers -Text $s.Text)
    if ($hf.Count -gt 0) { $markerHits += [pscustomobject]@{ Position = $s.Position; Markers = $hf }; $fail = $true }
}
if ($hlHits.Count -eq 0 -and $markerHits.Count -eq 0) {
    Write-Output "No leftover highlight and no leftover template instruction text on in-scope slides."
}
else {
    foreach ($h in $hlHits) { Write-Output ("ERROR: Slide {0} still has {1} leftover highlighted run(s) - run Remove-PptxHighlight before delivery." -f $h.Position, $h.Count) }
    foreach ($m in $markerHits) { Write-Output ("ERROR: Slide {0} still has leftover template instruction text: {1}" -f $m.Position, ($m.Markers -join ', ')) }
}

Write-Output ""
Write-Output "== Reference & examples section (positions 71-75) must be hidden =="
$refSectionVisible = @()
foreach ($s in $slides) {
    if ($s.Position -ge 71 -and $s.Position -le 75 -and $s.Visible) {
        $refSectionVisible += $s.Position
    }
}
if ($refSectionVisible.Count -eq 0) {
    Write-Output "Reference & examples section (71-75) is hidden. OK."
}
else {
    $fail = $true
    Write-Output ("ERROR: Reference & examples slide(s) still VISIBLE in the delivered deck: {0} - hide with Set-PptxSlideVisibility -Positions {0} -Visible `$false before delivery (SKILL.md rule 5c)." -f ($refSectionVisible -join ','))
}

Write-Output ""
if ($fail) { Write-Output "RESULT: PROBLEMS FOUND"; exit 1 } else { Write-Output "RESULT: OK"; exit 0 }
