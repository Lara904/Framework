# detect-deliverables.ps1
# Read-only scan of a drop folder. Classifies each file against the deliverable categories
# defined in references/categories.json (the SINGLE source of truth - this script holds NO
# category table of its own). Emits one JSON object with per-file candidates (category,
# confidence, evidence) + per-category coverage. The deliverable-detection skill agent turns
# this into the README checklist and asks the user about anything ambiguous.
#
# GUARD: never writes, moves, renames or deletes anything under -Path. Output goes to -Out
# (default: stdout) only.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File detect-deliverables.ps1 -Path "<drop folder>" [-Out result.json]
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Out
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) { throw "Scan path not found: $Path" }

$categoriesFile = Join-Path $PSScriptRoot '..\..\references\categories.json'
if (-not (Test-Path -LiteralPath $categoriesFile)) { throw "categories.json not found at $categoriesFile" }
$config = Get-Content -LiteralPath $categoriesFile -Raw | ConvertFrom-Json
$cats = $config.categories

function Get-Confidence {
    param([bool]$NameHit, [bool]$PathHit, [bool]$ExtHit)
    # High: a strong name keyword matched (optionally with ext). Medium: path/folder OR ext hit.
    # Low: nothing but a weak hint. Mirrors confidence.rule in categories.json.
    if ($NameHit) { return 'High' }
    if ($PathHit -and $ExtHit) { return 'High' }
    if ($PathHit -or $ExtHit) { return 'Medium' }
    return 'Low'
}

$files = Get-ChildItem -LiteralPath $Path -Recurse -File
$results = @()

foreach ($f in $files) {
    $rel = $f.FullName.Substring((Resolve-Path -LiteralPath $Path).Path.Length).TrimStart('\', '/')
    $nameLower = $f.Name.ToLowerInvariant()
    $pathLower = $rel.ToLowerInvariant()
    $ext = $f.Extension.ToLowerInvariant()

    $candidates = @()
    foreach ($c in $cats) {
        $nameHits = @($c.nameKeywords | Where-Object { $nameLower -like "*$($_.ToLowerInvariant())*" })
        $pathHits = @($c.pathKeywords | Where-Object { $pathLower -like "*$($_.ToLowerInvariant())*" })
        $extHit = $c.extensions -contains $ext

        if ($nameHits.Count -eq 0 -and $pathHits.Count -eq 0 -and -not $extHit) { continue }

        $evidence = @()
        if ($nameHits.Count) { $evidence += "name~'" + ($nameHits -join "','") + "'" }
        if ($pathHits.Count) { $evidence += "path~'" + ($pathHits -join "','") + "'" }
        if ($extHit) { $evidence += "ext=$ext" }

        $candidates += [ordered]@{
            categoryId    = $c.id
            consumerSkill = $c.consumerSkill
            confidence    = (Get-Confidence -NameHit:($nameHits.Count -gt 0) -PathHit:($pathHits.Count -gt 0) -ExtHit:$extHit)
            evidence      = ($evidence -join '; ')
        }
    }

    # ambiguous = 0 candidates, or no single candidate clearly ahead (>=2 at the top confidence rank)
    $rank = @{ High = 3; Medium = 2; Low = 1 }
    $top = if ($candidates.Count) { ($candidates | Sort-Object { $rank[$_.confidence] } -Descending | Select-Object -First 1).confidence } else { $null }
    $topCount = @($candidates | Where-Object { $_.confidence -eq $top }).Count
    $ambiguous = ($candidates.Count -eq 0) -or ($topCount -gt 1 -and $top -ne 'High')

    $results += [ordered]@{
        file       = $rel
        extension  = $ext
        sizeKB     = [math]::Round($f.Length / 1KB)
        candidates = $candidates
        ambiguous  = $ambiguous
    }
}

# coverage per category (best confidence seen across files)
$coverage = @()
foreach ($c in $cats) {
    $matches = @()
    foreach ($r in $results) {
        foreach ($cand in $r.candidates) {
            if ($cand.categoryId -eq $c.id) { $matches += [ordered]@{ file = $r.file; confidence = $cand.confidence } }
        }
    }
    $coverage += [ordered]@{
        categoryId    = $c.id
        label         = $c.label
        consumerSkill = $c.consumerSkill
        required      = [bool]$c.required
        found         = ($matches.Count -gt 0)
        matches       = $matches
    }
}

$output = [ordered]@{
    scannedPath      = (Resolve-Path -LiteralPath $Path).Path
    scannedAt        = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    categoriesSource = 'references/categories.json'
    fileCount        = $results.Count
    files            = $results
    coverage         = $coverage
} | ConvertTo-Json -Depth 8

if ($Out) {
    $dir = Split-Path -Parent $Out
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -LiteralPath $Out -Value $output -Encoding UTF8
    Write-Host "Wrote $Out ($($results.Count) files, $(@($coverage | Where-Object found).Count)/$($coverage.Count) categories covered)."
}
else {
    $output
}
