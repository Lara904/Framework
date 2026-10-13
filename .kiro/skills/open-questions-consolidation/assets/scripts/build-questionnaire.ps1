<#
  build-questionnaire.ps1 - scans every *_README.md already produced for a project in
  output/${project_name}/, pulls out each "Open questions" / "Missing information" /
  "Assumptions (to validate)" bullet, routes it to a role (PGA / MOA / DPO / Security / Finance /
  Cloud-Infra / EA) - using an explicit "- **Ask:** <Role>" tag when present, else the keyword
  fallback in references/role-routing.json - and writes ONE consolidated, addressed questionnaire
  so the project owner (or whoever) can see at a glance who needs to answer what, instead of
  digging through 8 separate READMEs. This does NOT send anything anywhere; the delivery channel
  (SFS Assist, a dedicated app, email...) is a separate, not-yet-decided concern - see
  references/open-questions-convention.md (steering) for why.

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File build-questionnaire.ps1 `
      -ProjectDir "output/<project_name>" -Project "<project_name>" `
      -Out "output/<project_name>/<project_name>_Open_Questions_Questionnaire.md"

  Exits non-zero only on a hard error (bad path). Zero open items is a normal, reportable outcome,
  not a failure - the questionnaire is then written saying so for every role.
#>
param(
  [Parameter(Mandatory=$true)] [string]$ProjectDir,
  [Parameter(Mandatory=$true)] [string]$Project,
  [Parameter(Mandatory=$true)] [string]$Out
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ProjectDir)) { Write-Error "Project folder not found: $ProjectDir"; exit 2 }

$routingPath = Join-Path $PSScriptRoot '..\..\references\role-routing.json'
if (-not (Test-Path $routingPath)) { Write-Error "role-routing.json not found at $routingPath"; exit 2 }
$routing = Get-Content $routingPath -Raw | ConvertFrom-Json
$knownRoles = @($routing.roles)
$defaultRole = $routing.defaultRole

# 1) Collect every *_README.md under the project folder. (The questionnaire itself is named
#    "*_Open_Questions_Questionnaire.md", never "*_README.md", so it never self-matches.)
$readmes = Get-ChildItem -Path $ProjectDir -Filter '*_README.md' -File -Recurse

$sectionHeaderRx = '^#{1,3}\s*(\d+[\.\)]\s*)?(Open questions|Missing( information)?|Assumptions)\b'
$nextHeaderRx    = '^#{1,3}\s'
$bulletRx        = '^\s*-\s*(\[[ xX]\]\s*)?(.+?)\s*$'
$askTagRx        = '-\s*\*\*Ask:\*\*\s*([A-Za-z,\-\s]+)\s*$'

# items: list of @{ Role=...; Text=...; Source=<readme basename> }
$items = New-Object System.Collections.Generic.List[object]

foreach ($rm in $readmes) {
  $lines = Get-Content $rm.FullName
  $inSection = $false
  $source = $rm.BaseName -replace '_README$', ''
  foreach ($line in $lines) {
    if ($line -match $sectionHeaderRx) { $inSection = $true; continue }
    if ($inSection -and $line -match $nextHeaderRx) { $inSection = $false; continue }
    if (-not $inSection) { continue }
    if ($line -notmatch $bulletRx) { continue }
    $text = $Matches[2]
    if ([string]::IsNullOrWhiteSpace($text)) { continue }
    if ($text -match '^[\-=\s]*$') { continue }  # skip stray "---" / "===" separator lines

    $roles = @()
    if ($text -match $askTagRx) {
      $tagged = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
      foreach ($t in $tagged) { if ($knownRoles -contains $t) { $roles += $t } }
      $text = ($text -replace $askTagRx, '').Trim().TrimEnd('-', ' ')
    }
    if ($roles.Count -eq 0) {
      $lower = $text.ToLowerInvariant()
      foreach ($rule in $routing.rules) {
        $hit = $false
        foreach ($kw in $rule.keywords) {
          # Word-boundary match, not a plain substring: a short acronym like "dpo" must not
          # fire on "endPOints". [regex]::Escape handles keywords with '/' etc. safely.
          $pattern = '\b' + [regex]::Escape($kw) + '\b'
          if ($lower -match $pattern) { $hit = $true; break }
        }
        if ($hit) { $roles += $rule.role; break }
      }
      if ($roles.Count -eq 0) { $roles += $defaultRole }
    }
    foreach ($r in $roles) {
      $items.Add([pscustomobject]@{ Role = $r; Text = $text; Source = $source })
    }
  }
}

# 2) Render: one section per known role, in a fixed order, even if empty.
$L = New-Object System.Collections.Generic.List[string]
$today = Get-Date -Format 'yyyy-MM-dd'
$L.Add("# $Project - Consolidated Open-Questions Questionnaire")
$L.Add('')
$L.Add("Generated: $today   Source: every *_README.md in this folder (regenerate after any change)")
$L.Add('')
$L.Add('> This is the single list of everything the tool could not complete on its own, addressed')
$L.Add('> by who needs to answer it. It replaces digging through each deliverable''s own "Open')
$L.Add('> questions" section. How this reaches its recipient (SFS Assist, a dedicated app, email,')
$L.Add('> a ticket...) is not decided yet - this file is the content, ready for any of them.')
$L.Add('')

$total = $items.Count
$byRole = @{}
foreach ($r in $knownRoles) { $byRole[$r] = @($items | Where-Object { $_.Role -eq $r }) }

$L.Add('## Summary')
$L.Add('| Role | Open items |')
$L.Add('|------|------------|')
foreach ($r in $knownRoles) { $L.Add("| $r | $($byRole[$r].Count) |") }
$L.Add("| **Total** | **$total** |")
$L.Add('')

foreach ($r in $knownRoles) {
  $roleTitle = switch ($r) {
    'PGA'         { 'PGA / Project owner (chef de projet)' }
    'MOA'         { 'MOA (business owner)' }
    'DPO'         { 'DPO (personal data / GDPR)' }
    'Security'    { 'SFES Cybersecurity team' }
    'Finance'     { 'Finance' }
    'Cloud-Infra' { 'Cloud / Infra team' }
    'EA'          { 'Enterprise Architect' }
    default       { $r }
  }
  $L.Add("## $roleTitle")
  $list = $byRole[$r]
  if ($list.Count -eq 0) {
    $L.Add('No open question for this role right now.')
  } else {
    foreach ($it in $list) {
      $L.Add("- [ ] $($it.Text) *(blocks: $($it.Source))*")
    }
  }
  $L.Add('')
}

$L.Add('## Change history')
$existingHistory = @()
if (Test-Path $Out) {
  $old = Get-Content $Out
  $inHist = $false
  foreach ($line in $old) {
    if ($line -match '^##\s*Change history') { $inHist = $true; continue }
    if ($inHist -and $line -match '^\|') { $existingHistory += $line }
    elseif ($inHist -and $line -match '^#') { break }
  }
}
$L.Add('| Date | Open items | Detail |')
$L.Add('|------|------------|--------|')
foreach ($row in $existingHistory) {
  if ($row -match '^\|\s*Date\s*\|') { continue }
  if ($row -match '^\|[\s\-]*\|[\s\-]*\|[\s\-]*\|') { continue }
  $L.Add($row)
}
$L.Add("| $today | $total | Regenerated from $($readmes.Count) README(s) in $ProjectDir |")

$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$outFullPath = [System.IO.Path]::GetFullPath($Out)
[System.IO.File]::WriteAllText($outFullPath, ($L -join "`r`n"), $utf8NoBom)

Write-Output "QUESTIONNAIRE BUILT: $Out ($total open item(s) across $($readmes.Count) README(s))"
foreach ($r in $knownRoles) { Write-Output "  $r : $($byRole[$r].Count)" }
exit 0
