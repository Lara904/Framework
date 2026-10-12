# replace-text.ps1
# Replace placeholder text inside a .pptx COPY. Two modes:
#   Single:  -Position <n> -Find "<placeholder>" -Replace "<value>"
#   Batch:   -Batch <file.csv|file.json>   (many fields, applied in ONE zip open)
#
# CSV columns:  Position,Find,Replace       JSON: [ {"Position":9,"Find":"...","Replace":"..."} ]
#
# - Handles XML entity escaping (&, <, >), matches escaped form first then literal.
# - Resolves true display order (position N == slideN.xml) via the shared module.
# - Refuses to edit the read-only template (copy it to a new name first).
param(
    [Parameter(Mandatory = $true)][string]$Pptx,
    [int]$Position,
    [string]$Find,
    [string]$Replace,
    [string]$Batch
)

Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force

# Build the replacement set from either batch file or single-item parameters.
$items = @()
if ($Batch) {
    if (-not (Test-Path $Batch)) { throw "Batch file not found: $Batch" }
    if ($Batch -match '\.json$') {
        $items = Get-Content $Batch -Raw | ConvertFrom-Json
    }
    else {
        $items = Import-Csv $Batch
    }
    $items = $items | ForEach-Object { @{ Position = [int]$_.Position; Find = [string]$_.Find; Replace = [string]$_.Replace } }
}
else {
    if (-not $PSBoundParameters.ContainsKey('Position') -or -not $PSBoundParameters.ContainsKey('Find')) {
        throw "Provide either -Batch <file> or all of -Position/-Find/-Replace."
    }
    $items = @(@{ Position = $Position; Find = $Find; Replace = $Replace })
}

$results = @(Set-PptxSlideReplacements -Pptx $Pptx -Replacements $items)

foreach ($r in $results) {
    if ($r.Applied) {
        Write-Output ("OK   slide POS {0}: '{1}' ({2})" -f $r.Position, $r.Find, $r.Reason)
    }
    else {
        Write-Warning ("SKIP slide POS {0}: '{1}' - {2}" -f $r.Position, $r.Find, $r.Reason)
    }
}
$applied = @($results | Where-Object { $_.Applied }).Count
Write-Output "Applied $applied of $($results.Count) replacement(s)."
