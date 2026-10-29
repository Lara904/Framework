<#
  build-questionnaire.ps1 - scans every *_README.md already produced for a project in
  output/${project_name}/, pulls out each "Open questions" / "Missing information" /
  "Assumptions (to validate)" / "Arbitrary default choices" bullet or table row, routes it to a
  role (PGA / MOA / DPO / Security / Finance /
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

$sectionHeaderRx = '^#{1,3}\s*(\d+[\.\)]\s*)?(Open questions|Missing( information)?|Assumptions|Arbitrary default)\b'
$arbitraryHeaderRx = '^#{1,3}\s*(\d+[\.\)]\s*)?Arbitrary default\b'
$nextHeaderRx    = '^#{1,3}\s'
$bulletRx        = '^\s*-\s*(\[[ xX]\]\s*)?(.+?)\s*$'
$tableRowRx      = '^\s*\|(.+)\|\s*$'
$tableSepCellRx  = '^:?-{2,}:?$'
$askTagRx        = '-\s*\*\*Ask:\*\*\s*([A-Za-z,\-\s]+)\s*$'

function Resolve-Roles($text, $knownRoles, $routing, $defaultRole) {
  # Returns @{ Roles = <array>; Text = <cleaned text> }. Explicit "- **Ask:** <Role>" tag wins
  # over the keyword fallback; a short acronym like "dpo" must not fire on "endPOints", hence the
  # word-boundary match below rather than a plain substring.
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
        $pattern = '\b' + [regex]::Escape($kw) + '\b'
        if ($lower -match $pattern) { $hit = $true; break }
      }
      if ($hit) { $roles += $rule.role; break }
    }
    if ($roles.Count -eq 0) { $roles += $defaultRole }
  }
  return [pscustomobject]@{ Roles = $roles; Text = $text }
}

# items: list of @{ Role=...; Text=...; Source=<readme basename> }
$items = New-Object System.Collections.Generic.List[object]

foreach ($rm in $readmes) {
  $lines = Get-Content $rm.FullName
  $inSection = $false
  # Per-table state: a table is HEADER row, then a |---|---| separator row, then data rows.
  # Reset whenever we (re)enter a section, since a section holds at most one table.
  $sawTableHeader = $false
  $pastTableSep = $false
  $isArbitrarySection = $false
  $headerCells = @()
  $source = $rm.BaseName -replace '_README$', ''

  # A bullet item may wrap onto indented continuation lines (common when a question plus its
  # "- **Ask:** <Role>" tag is long). A past real README did exactly this, and the role tag -
  # placed on the wrapped line - was silently dropped because each physical line was resolved in
  # isolation: the continuation line matched neither $bulletRx nor $tableRowRx, so it was just
  # skipped, and the bullet's first-line-only text fell through to keyword routing (or the PGA
  # default) instead of honoring its explicit tag. $pendingBulletText buffers a bullet across its
  # continuation lines so the full text - tag included - is resolved as one unit, regardless of
  # how the source README wrapped it.
  $pendingBulletText = $null
  function Flush-PendingBullet {
    if ($null -eq $script:pendingBulletText) { return }
    $t = $script:pendingBulletText.Trim()
    $script:pendingBulletText = $null
    if ([string]::IsNullOrWhiteSpace($t)) { return }
    if ($t -match '^[\-=\s]*$') { return }  # skip stray "---" / "===" separator lines
    $resolved = Resolve-Roles $t $knownRoles $routing $defaultRole
    foreach ($r in $resolved.Roles) {
      $script:items.Add([pscustomobject]@{ Role = $r; Text = $resolved.Text; Source = $script:source })
    }
  }

  foreach ($line in $lines) {
    if ($line -match $sectionHeaderRx) {
      Flush-PendingBullet
      $inSection = $true; $sawTableHeader = $false; $pastTableSep = $false
      $isArbitrarySection = [bool]($line -match $arbitraryHeaderRx)
      continue
    }
    if ($inSection -and $line -match $nextHeaderRx) { Flush-PendingBullet; $inSection = $false; continue }
    if (-not $inSection) { continue }

    # Markdown table row inside the section (e.g. the "Missing information (to be provided)"
    # table, whose owner column carries the "- **Ask:** <Role>" tag): parse cells, skip the
    # header row and the |---|---| separator row, then treat each data row as one item.
    if ($line -match $tableRowRx) {
      Flush-PendingBullet
      $cells = $Matches[1] -split '\|' | ForEach-Object { $_.Trim() }
      $nonEmpty = @($cells | Where-Object { $_ -ne '' })
      $isSepRow = $nonEmpty.Count -gt 0 -and (@($nonEmpty | Where-Object { $_ -notmatch $tableSepCellRx }).Count -eq 0)
      if ($isSepRow) { $pastTableSep = $true; continue }
      if (-not $sawTableHeader) { $sawTableHeader = $true; $headerCells = $cells; continue }  # this is the header row
      if (-not $pastTableSep) { continue }  # malformed table (no separator yet) - be safe, skip

      # Item text: the longest cell that isn't the Ask-tag cell and isn't a bare id (# / M1 / 1).
      $candidates = $cells | Where-Object { $_ -notmatch '\*\*Ask:\*\*' -and $_ -notmatch '^#?[A-Za-z]?\d*$' -and $_ -ne '' }
      if ($candidates.Count -eq 0) { continue }
      if ($isArbitrarySection) {
        # Arbitrary-default tables vary in width (5 to 7 columns), so pick by HEADER rather than
        # position: column 1 (right after the # id) is always the item/NFR description, and
        # whichever header contains "default" holds the chosen placeholder - those two together
        # are what the role needs, not whatever cell happens to be longest (often "Reasoning").
        $descCell = if ($cells.Count -gt 1) { $cells[1] } else { $null }
        $defaultColIdx = -1
        for ($i = 0; $i -lt $headerCells.Count; $i++) { if ($headerCells[$i] -match '(?i)default') { $defaultColIdx = $i; break } }
        $defaultCell = if ($defaultColIdx -ge 0 -and $defaultColIdx -lt $cells.Count) { $cells[$defaultColIdx] } else { $null }
        if ($descCell -and $defaultCell -and $descCell -ne $defaultCell) {
          $itemText = "$descCell - default chosen: $defaultCell"
        } elseif ($descCell) {
          $itemText = $descCell
        } else {
          $itemText = ($candidates | Sort-Object { $_.Length } -Descending | Select-Object -First 1)
        }
      } else {
        $itemText = ($candidates | Sort-Object { $_.Length } -Descending | Select-Object -First 1)
      }
      # The Ask tag can be in any cell (usually the last/"Owner" column), not necessarily itemText's.
      $askCell = $cells | Where-Object { $_ -match $askTagRx } | Select-Object -First 1
      $textForRouting = if ($askCell) { "$itemText $askCell" } else { $itemText }

      $resolved = Resolve-Roles $textForRouting $knownRoles $routing $defaultRole
      $renderedText = if ($isArbitrarySection) { "[Confirm default] $itemText" } else { $itemText }
      foreach ($r in $resolved.Roles) {
        $items.Add([pscustomobject]@{ Role = $r; Text = $renderedText; Source = $source })
      }
      continue
    }

    if ($line -match $bulletRx) {
      Flush-PendingBullet
      $text = $Matches[2]
      if ([string]::IsNullOrWhiteSpace($text)) { continue }
      $pendingBulletText = $text
      continue
    }

    # Not a header/table/new-bullet line: if we're mid-bullet AND this line is itself indented
    # (the established wrapping convention - a continuation is written with leading whitespace,
    # e.g. "  (details) - **Ask:** Role"), fold it into the pending bullet instead of silently
    # dropping it. A blank line, or a non-indented stray line (a "---" rule, a trailing "Totals:"
    # paragraph after the section's last bullet, etc.), ends the bullet instead - it is NOT a
    # continuation, so it is flushed and left out, exactly as such lines were already ignored
    # before this buffering existed. Column-0 text should never silently extend someone else's
    # bullet.
    if ($null -ne $pendingBulletText) {
      if ($line -match '^\s+\S') { $pendingBulletText = $pendingBulletText + ' ' + $line.Trim() }
      else { Flush-PendingBullet }
    }
  }
  Flush-PendingBullet
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
