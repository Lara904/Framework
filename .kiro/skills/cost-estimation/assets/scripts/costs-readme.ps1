# costs-readme.ps1
# Render the costs README from a JSON model, compute the column totals, and report what is still
# missing (every null). Self-contained; UTF-8 without BOM; ASCII-safe output.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File costs-readme.ps1 -Model "output/${project_name}/${project_name}_costs_model.json" [-Out "output/${project_name}/${project_name}_costs_README.md"] [-Seed]
#   (output location per the output-convention steering; -Out/-Model accept any path)
#   -Seed : if the model file does not exist, create a blank template model then render.
param(
    [Parameter(Mandatory = $true)][string]$Model,
    [string]$Out = '',
    [switch]$Seed
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Resolve-OutPath([string]$p) { if ([System.IO.Path]::IsPathRooted($p)) { $p } else { Join-Path (Get-Location).Path $p } }

$modelPath = Resolve-OutPath $Model
if ($Out -eq '') {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($modelPath) -replace '_costs_model$', ''
    $Out = Join-Path ([System.IO.Path]::GetDirectoryName($modelPath)) ($base + '_costs_README.md')
}
$outPath = Resolve-OutPath $Out

# --- Seed a blank model if requested and missing ------------------------------------------------
if (-not (Test-Path $modelPath)) {
    if (-not $Seed) { throw "Model not found: $modelPath (use -Seed to create a blank one)." }
    $proj = ([System.IO.Path]::GetFileNameWithoutExtension($modelPath) -replace '_costs_model$', '')
    $blank = [ordered]@{
        project      = $proj
        gate         = 'TBD'
        startQuarter = 'Q1'
        currency     = 'EUR'
        fx           = [ordered]@{ usdToEur = $null; asOf = $null }
        cloud        = [ordered]@{ calculatorLink = $null; services = @() }
        it           = [ordered]@{ internalDailyRate = $null; supplierDailyRate = $null; backlogLink = $null; items = @() }
        investments  = [ordered]@{ hardware = @(); licenses = @() }
        global       = [ordered]@{
            IT          = [ordered]@{ Q1 = $null; Q2 = $null; Q3 = $null; Q4 = $null; Y2 = $null }
            Cloud       = [ordered]@{ Q1 = $null; Q2 = $null; Q3 = $null; Q4 = $null; Y2 = $null }
            Investments = [ordered]@{ Q1 = $null; Q2 = $null; Q3 = $null; Q4 = $null; Y2 = $null }
        }
    }
    [System.IO.File]::WriteAllText($modelPath, ($blank | ConvertTo-Json -Depth 8), $utf8)
    Write-Output "Seeded blank model: $modelPath"
}

$m = Get-Content -Raw -LiteralPath $modelPath | ConvertFrom-Json

$missing = New-Object System.Collections.Generic.List[string]
function Cell($v) { if ($null -eq $v -or "$v" -eq '') { 'TBD' } else { "$v" } }
function Num($v) { if ($null -eq $v) { $null } else { [double]$v } }

$cols = 'Q1', 'Q2', 'Q3', 'Q4', 'Y2'
$rows = 'IT', 'Cloud', 'Investments'
$rowLabel = @{ IT = 'IT costs (incl. outsourcing)'; Cloud = 'Cloud consumption'; Investments = 'Investments (hardware + license)' }

# Totals per column
$total = @{}
foreach ($c in $cols) {
    $sum = 0.0; $anyKnown = $false; $anyMissing = $false
    foreach ($r in $rows) {
        $v = Num $m.global.$r.$c
        if ($null -eq $v) { $anyMissing = $true; $missing.Add("global $r $c amount") } else { $sum += $v; $anyKnown = $true }
    }
    $total[$c] = if ($anyKnown -and -not $anyMissing) { [math]::Round($sum, 1) } elseif ($anyKnown) { "$([math]::Round($sum,1))*" } else { $null }
}

$L = New-Object System.Collections.Generic.List[string]
$L.Add("# Costs README - $($m.project)")
$L.Add('')
$fxTxt = if ($m.fx.usdToEur) { "USD->EUR $($m.fx.usdToEur) as of $(Cell $m.fx.asOf)" } else { 'FX: TBD' }
$L.Add("Source model: $([System.IO.Path]::GetFileName($modelPath))   Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')   Gate: $(Cell $m.gate)   Currency: k EUR ($fxTxt)")
$L.Add('')
$L.Add('All global-view amounts in k EUR. Year 1 by quarter (Q1-Q4), Year 2 = next-year recurrent.')
$L.Add('An asterisk (*) on a total means some component is still TBD. Never invent - fill the JSON model.')
$L.Add('')

# 1. Global view
$L.Add('## 1. Global view (k EUR) - feeds deck slide 59 (and 22)')
$L.Add('')
$L.Add('| Cost type | Q1 | Q2 | Q3 | Q4 | Y2 recurrent |')
$L.Add('|-----------|----|----|----|----|--------------|')
foreach ($r in $rows) {
    $L.Add(('| {0} | {1} | {2} | {3} | {4} | {5} |' -f $rowLabel[$r], (Cell $m.global.$r.Q1), (Cell $m.global.$r.Q2), (Cell $m.global.$r.Q3), (Cell $m.global.$r.Q4), (Cell $m.global.$r.Y2)))
}
$L.Add(('| **Total cost** | {0} | {1} | {2} | {3} | {4} |' -f (Cell $total.Q1), (Cell $total.Q2), (Cell $total.Q3), (Cell $total.Q4), (Cell $total.Y2)))
$L.Add('')

# 2. Cloud detail
$L.Add('## 2. Cloud - AWS Calculator detail (feeds deck slide 58 / 23)')
$L.Add('')
if (-not $m.cloud.calculatorLink) { $missing.Add('AWS Calculator shared link') }
$L.Add("Shared AWS Calculator link: $(Cell $m.cloud.calculatorLink)")
$L.Add('')
$L.Add('| Region | Service | Monthly | Annual | Currency | Configuration summary |')
$L.Add('|--------|---------|---------|--------|----------|-----------------------|')
if (@($m.cloud.services).Count -eq 0) {
    $L.Add('| _no service listed yet_ |  |  |  |  |  |')
    $missing.Add('cloud services list (none entered)')
}
else {
    foreach ($s in $m.cloud.services) {
        if ($null -eq $s.monthly) { $missing.Add("cloud service '$($s.service)' monthly cost") }
        $L.Add(('| {0} | {1} | {2} | {3} | {4} | {5} |' -f (Cell $s.region), (Cell $s.service), (Cell $s.monthly), (Cell $s.annual), (Cell $s.currency), (Cell $s.config)))
    }
}
$L.Add('')

# 3. IT costs
$L.Add('## 3. IT costs (development / piloting / delivery, internal + outsourcing)')
$L.Add('')
if ($null -eq $m.it.internalDailyRate) { $missing.Add('IT internal daily rate (k EUR/JH)') }
if ($null -eq $m.it.supplierDailyRate) { $missing.Add('IT supplier daily rate (k EUR/JH)') }
$L.Add("Daily rates: internal $(Cell $m.it.internalDailyRate) k EUR/JH, supplier $(Cell $m.it.supplierDailyRate) k EUR/JH   Backlog: $(Cell $m.it.backlogLink)")
$L.Add('')
$L.Add('| Item | Internal JH | Outsourced JH | k EUR |')
$L.Add('|------|-------------|---------------|-------|')
$ir = Num $m.it.internalDailyRate; $sr = Num $m.it.supplierDailyRate
if (@($m.it.items).Count -eq 0) { $L.Add('| _no IT item yet_ |  |  |  |'); $missing.Add('IT backlog / effort items (none entered)') }
foreach ($it in $m.it.items) {
    $ij = Num $it.internalJH; $oj = Num $it.outsourcedJH
    $k = $null
    if ($null -ne $ij -and $null -ne $ir) { $k = ($ij * $ir) } 
    if ($null -ne $oj -and $null -ne $sr) { $k = ([double]$k + ($oj * $sr)) }
    $kTxt = if ($null -ne $k -and (($null -ne $ij) -or ($null -ne $oj))) { [math]::Round([double]$k, 1) } else { 'TBD' }
    if ($null -eq $ij -and $null -eq $oj) { $missing.Add("IT item '$($it.label)' effort (JH)") }
    $L.Add(('| {0} | {1} | {2} | {3} |' -f (Cell $it.label), (Cell $it.internalJH), (Cell $it.outsourcedJH), $kTxt))
}
$L.Add('')

# 4. Investments
$L.Add('## 4. Investments')
$L.Add('')
$hw = @($m.investments.hardware); $lic = @($m.investments.licenses)
$L.Add(('Hardware: {0}' -f $(if ($hw.Count -eq 0) { 'none listed (confirm N/A if cloud-only)' } else { ($hw | ForEach-Object { "$($_.item) = $(Cell $_.totalKEUR) k EUR" }) -join '; ' })))
$L.Add('')
$L.Add(('Software licenses: {0}' -f $(if ($lic.Count -eq 0) { 'none listed (confirm all open-source / covered by cloud)' } else { ($lic | ForEach-Object { "$($_.product) = $(Cell $_.totalKEUR) k EUR" }) -join '; ' })))
$L.Add('')

# 5. Missing
$L.Add('## 5. Open questions / Missing')
$L.Add('')
if ($missing.Count -eq 0) { $L.Add('_Cost picture complete - all values provided (validate with finance / MOA)._') }
else { foreach ($x in $missing) { $L.Add("- [ ] $x") } }
$L.Add('')

$y1 = 0.0; $y1known = $true
foreach ($c in 'Q1', 'Q2', 'Q3', 'Q4') { $v = $total[$c]; if ($v -is [double]) { $y1 += $v } else { $y1known = $false } }
$y1Txt = if ($y1known) { [math]::Round($y1, 1) } else { 'TBD' }
$y2Txt = Cell $total.Y2
$L.Add('---')
$L.Add("Totals: Year-1 = $y1Txt k EUR | Year-2 recurrent = $y2Txt k EUR | Open items: $($missing.Count)")

[System.IO.File]::WriteAllText($outPath, ($L -join "`r`n"), $utf8)
Write-Output "Wrote costs README to $outPath (open items: $($missing.Count))."
