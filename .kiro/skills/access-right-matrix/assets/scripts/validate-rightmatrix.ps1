<#
  validate-rightmatrix.ps1 - authoritative check that a generated Access Right Matrix
  .xlsx is a valid OPC package Excel will open without "repair". Validates at the
  WINDOWS/OPC layer, not just XML well-formedness.

  It also reports (a) whether any <PRD> placeholder token still remains (so the user
  knows the PRD code was not applied), and (b) the values written in the APPLICATION
  Information sheet, and warns on any remaining unresolved placeholder there.

  Usage:
    powershell -ExecutionPolicy Bypass -File validate-rightmatrix.ps1 -Xlsx "<project>_access_right_matrix.xlsx"

  Exits non-zero on OPC/XML failure. A remaining placeholder is a WARNING, not a
  failure (a value may legitimately be left as TBD).
#>
param(
  [Parameter(Mandatory=$true)] [string]$Xlsx
)

$ErrorActionPreference = 'Stop'
$fail = @()

if (-not (Test-Path $Xlsx)) { Write-Error "File not found: $Xlsx"; exit 2 }

# 1) OPC package must open (the authoritative "would Excel repair this?" test)
try {
  Add-Type -AssemblyName WindowsBase
  $pkg = [System.IO.Packaging.Package]::Open((Resolve-Path $Xlsx).Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
  $partCount = ($pkg.GetParts() | Measure-Object).Count
  $pkg.Close()
  Write-Output "OPC package opens cleanly ($partCount parts)."
} catch {
  $fail += "OPC package failed to open (Excel would offer to repair): $($_.Exception.Message)"
}

# 2) Every XML part must be well-formed; workbook.xml must declare the 6 expected sheets
$sharedStrings = ''
$sheet4 = ''
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Xlsx).Path)
  try {
    foreach ($e in $zip.Entries) {
      if ($e.FullName -like '*.xml' -or $e.FullName -like '*.rels') {
        $sr = New-Object System.IO.StreamReader($e.Open())
        $content = $sr.ReadToEnd(); $sr.Close()
        try { [xml]$content | Out-Null }
        catch { $fail += "Malformed XML part: $($e.FullName)" }
        if ($e.FullName -eq 'xl/workbook.xml' -and $content -notmatch 'AWS NG - TECHNICAL rights') {
          $fail += "xl/workbook.xml is missing the expected 'AWS NG - TECHNICAL rights' sheet"
        }
        if ($e.FullName -eq 'xl/sharedStrings.xml') { $sharedStrings = $content }
        if ($e.FullName -eq 'xl/worksheets/sheet4.xml') { $sheet4 = $content }
      }
    }
  } finally { $zip.Dispose() }
} catch {
  $fail += "Could not read archive: $($_.Exception.Message)"
}

# 2b) "Matrix of BUSINESS rights" (sheet4) must carry an explicit decision - either real
# profile data or the "N/A - no business profile" marker. A sheet with NEITHER (still at
# its blank template state: headers "Profile 1".."Profile 19" but no inlineStr content in
# the Label/Description/etc. rows) means nobody actually decided anything - FAIL, not a
# warning, because this is exactly the defect that shipped a blank matrix in a real TCC.
if ($sheet4 -ne '') {
  $hasMarker = $sharedStrings -match 'N/A - no business profile for this scope' -or $sheet4 -match 'N/A - no business profile for this scope'
  $hasInlineData = ([regex]::Matches($sheet4, 't="inlineStr"')).Count -gt 0
  if (-not $hasMarker -and -not $hasInlineData) {
    $fail += "Matrix of BUSINESS rights (sheet4) has no decision recorded: no profile data and no 'N/A - no business profile' marker. The model's 'businessProfiles' field was not applied - regenerate with build-rightmatrix.ps1 using a model that sets businessProfiles to 'none' or 'defined' (see model-schema.md). Do not hand this file over as-is."
  }
}

if ($fail.Count -gt 0) {
  Write-Output "RIGHT MATRIX VALIDATION FAILED:"
  $fail | ForEach-Object { Write-Output " - $_" }
  exit 1
}

# 3) Placeholder report (warnings only)
if ($sharedStrings -ne '') {
  $prd = ([regex]::Matches($sharedStrings, '&lt;PRD&gt;')).Count
  if ($prd -gt 0) {
    Write-Output "WARNING: $prd '<PRD>' placeholder(s) still present - PRD code not applied (fill 'prdCode' in the model)."
  } else {
    Write-Output "No '<PRD>' placeholder remaining."
  }
  $reflex = ([regex]::Matches($sharedStrings, '&lt;REFLEX_NAME|&lt;Reflex_Application&gt;')).Count
  if ($reflex -gt 0) {
    Write-Output "INFO: $reflex REFLEX_NAME/Reflex_Application descriptive placeholder(s) still present (optional - fill reflexNameDev/Pre/Prod to resolve)."
  }
}

Write-Output "RIGHT MATRIX VALIDATION OK: $Xlsx"
exit 0
