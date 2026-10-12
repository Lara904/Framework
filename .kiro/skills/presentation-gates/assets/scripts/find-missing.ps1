# find-missing.ps1
# Scan an Architecture Gates deck and emit a "gates checklist" structured BY GATE, where each
# gate lists its missing slide data AND its required annex deliverables.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File find-missing.ps1 -Pptx "output/${project_name}/${project_name}_Architecture_Gates_G<n>.pptx" [-Gate all|1|2|3|4] [-Out "output/${project_name}/${project_name}_Architecture_Gates_README.md"]
#   (output location per the output-convention steering; -Out/-Pptx accept any path)
#
# Detection is heuristic (see references/gates-readme.md). Slide map, deliverables and
# detection patterns all come from the shared PptxGates module. Deliverable statuses are PERSISTED
# (read back from the existing -Out file), so user-tracked progress survives regenerations.
param(
    [Parameter(Mandatory = $true)][string]$Pptx,
    [ValidateSet('all', '1', '2', '3', '4')][string]$Gate = 'all',
    [string]$Out = ''
)

Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force

# Read the deck ONCE; reuse for marker detection, deliverable resolution and real titles.
$allSlides = @(Get-PptxSlides -Pptx $Pptx)

# ONE numbering base for the whole README = the deck's REAL display order (sldIdLst positions,
# via Get-PptxSlides). The V5.2 SlideMap NEVER drives a displayed position: the "Slides to review"
# list is a single flat list in real display order (not split by gate), and the per-gate split is
# kept ONLY for annex deliverables, whose position is resolved by role against the real deck
# (Resolve-DeliverableSlide). So a given slide shows the SAME number everywhere.

# position -> REAL slide title (derived from the actual deck text).
$titleByPos = @{}
foreach ($s in $allSlides) {
    $t = Get-SlideTitle -Text $s.Text
    if ($t -eq '') { $t = "Slide $($s.Position)" }   # last resort (no fixed V5.2 title lookup)
    $titleByPos[$s.Position] = $t
}
function Get-PosTitle([int]$p) {
    if ($titleByPos.ContainsKey($p)) { return $titleByPos[$p] }
    return "Slide $p"
}

# position -> found markers (visible slides only; hidden = deliberately out of scope).
# $hidden holds REAL display positions (from the deck), not V5.2 numbers.
$findings = @{}
$hidden = @()
foreach ($s in $allSlides) {
    if (-not $s.Visible) { $hidden += $s.Position; continue }
    $markers = Get-MissingMarkers -Text $s.Text
    if ($markers.Count -gt 0) { $findings[$s.Position] = $markers }
}

# --- Persisted deliverable status: read prior statuses from the existing -Out file -----------
$outPath = ''
if ($Out -ne '') {
    $outPath = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location).Path $Out }
}
$priorStatus = @{}
if ($outPath -ne '' -and (Test-Path $outPath)) {
    foreach ($ln in (Get-Content $outPath)) {
        # Trailing position label may be "_(slide N)_" or the unresolved "_(slide N?)_" form, and
        # (from an earlier bug) may appear more than once; strip any number of either so the
        # captured Status never absorbs a label and labels do not accumulate on regeneration.
        $m = [regex]::Match($ln, '^\s*-\s*\[( |x|X)\]\s*(.+?)\s*\((?:G1|G2|G3|G4)(?:,\s*(?:G1|G2|G3|G4))*\)\s*-\s*status:\s*(.+?)\s*(?:_\(slide\s*\d+\??\)_\s*)*$')
        if ($m.Success) {
            $priorStatus[$m.Groups[2].Value.Trim()] = @{ Checked = ($m.Groups[1].Value -match 'x|X'); Status = $m.Groups[3].Value.Trim() }
        }
    }
}

$gateOrder = if ($Gate -eq 'all') { @('G1', 'G2', 'G3', 'G4') } else { @("G$Gate") }
$sectionTitle = @{
    'G1' = 'Gate 1 - Demand Gate'
    'G2' = 'Gate 2 - Initial Gate'
    'G3' = 'Gate 3 - After Design Gate'
    'G4' = 'Gate 4 - Before Go-Live Gate'
}

$deliverables = Get-Deliverables

# Resolve each deliverable's REAL position (by SlideRole) and whether its link is posted, against
# the actual deck - robust to decks that add/reorder slides vs the standard V5.2 numbering.
$resolved = @{}
foreach ($d in $deliverables) {
    $resolved[$d.Id] = Resolve-DeliverableSlide -Deliverable $d -Slides $allSlides
}

$lines = New-Object System.Collections.Generic.List[string]
$projTitle = [System.IO.Path]::GetFileNameWithoutExtension($Pptx)
$lines.Add("# Architecture Gates README - $projTitle")
$lines.Add('')
$lines.Add("Source: $([System.IO.Path]::GetFileName($Pptx))")
$lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$lines.Add('Scope: ' + $(if ($Gate -eq 'all') { 'all gates' } else { "Gate $Gate" }))
$lines.Add('')
$lines.Add('Two parts: (a) ONE flat list of slides to review (missing data or leftover guidance -')
$lines.Add('heuristic), in the deck''s real display order; and (b) per gate, the required annex')
$lines.Add('deliverables (documents behind the "Link to ..." fields) with a persisted status. Tick a')
$lines.Add('slide once filled and de-highlighted; update a deliverable status (Not started / In')
$lines.Add('progress / Provided / N/A) and tick it when done.')
$lines.Add('')
$lines.Add('Slides are listed once, in real display order, and NOT split by gate: on a filled deck the')
$lines.Add('slide wording diverges from the template, so a per-gate bucket inferred from the title')
$lines.Add('would be guesswork. The gate dimension is kept only where it resolves reliably - the annex')
$lines.Add('deliverables (resolved by role against the real deck).')
if ($hidden.Count -gt 0) {
    $lines.Add('')
    $lines.Add('Hidden (non-applicable, excluded from scope): slides ' + (($hidden | Sort-Object) -join ', ') + '.')
}
$lines.Add('')

$totalSlideOpen = 0
$totalDelivOpen = 0

# --- (a) ONE flat "Slides to review" list, real display order (sldIdLst), never split by gate. ---
# Every number here is a real display position from Get-PptxSlides; the V5.2 SlideMap drives none.
$lines.Add('## Slides to review (real display order)')
$lines.Add('')
$slidePositions = @($allSlides | Where-Object { $findings.ContainsKey($_.Position) } |
        Sort-Object Position | ForEach-Object { $_.Position })
if ($slidePositions.Count -eq 0) {
    $lines.Add('_No missing slide data detected._')
}
else {
    foreach ($p in $slidePositions) {
        $lines.Add(('- [ ] Slide {0} - {1}  _(found: {2})_' -f $p, (Get-PosTitle $p), ($findings[$p] -join ', ')))
        $totalSlideOpen++
    }
}
$lines.Add('')

# --- (b) Annex deliverables, grouped by gate (resolved by role - the only reliable gate split). ---
foreach ($sec in $gateOrder) {
    $lines.Add('## ' + $sectionTitle[$sec] + ' - annex deliverables')
    $lines.Add('')

    # Deliverables for this gate - position resolved by role against the real deck.
    $secDeliv = @($deliverables | Where-Object { $_.Gate -contains $sec } | Sort-Object { $resolved[$_.Id].Position })
    if ($secDeliv.Count -eq 0) {
        $lines.Add('_No annex deliverable required for this gate._')
    }
    else {
        foreach ($d in $secDeliv) {
            $gateStr = ($d.Gate -join ', ')
            $r = $resolved[$d.Id]
            $prior = $priorStatus[$d.Name]
            # Default status: "Provided" when the deliverable's link is posted on the slide,
            # otherwise "Not started". A user-persisted status always wins (never downgrade a
            # value the user set), so progress tracked by hand survives regeneration.
            $defaultStatus = if ($r.LinkPosted) { 'Provided' } else { 'Not started' }
            $checked = if ($prior -and $prior.Checked) { 'x' } else { ' ' }
            $status = if ($prior) { $prior.Status } else { $defaultStatus }
            $posLabel = if ($r.Resolved) { "slide $($r.Position)" } else { "slide $($r.Position)?" }
            # count as open unless provided/checked
            $isOpen = ($checked -ne 'x') -and ($status -notmatch '^(Provided|N/A)$')
            if ($isOpen) { $totalDelivOpen++ }
            $lines.Add(('- [{0}] {1} ({2}) - status: {3}  _({4})_' -f $checked, $d.Name, $gateStr, $status, $posLabel))
        }
    }
    $lines.Add('')
}

# (No separate "General slides" section: all slides to review are already in the single flat list
# above, in real display order. The V5.2 SlideMap no longer drives any displayed slide position.)

$lines.Add('---')
$lines.Add("Open slide items: $totalSlideOpen  |  Open deliverables: $totalDelivOpen")
$output = $lines -join "`r`n"

if ($outPath -ne '') {
    Assert-NotTemplate -Path $outPath
    [System.IO.File]::WriteAllText($outPath, $output, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "Wrote checklist to $outPath ($totalSlideOpen slide items, $totalDelivOpen deliverables open)."
}
else {
    Write-Output $output
}
