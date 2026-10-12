<#
  validate-threatmodel.ps1 - authoritative check that a generated Threat Modeling .xlsx is a
  valid OPC package Excel will open without "repair". Validates at the WINDOWS/OPC layer, not
  just XML well-formedness.

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File validate-threatmodel.ps1 -Xlsx "<project>_threat_modeling.xlsx"

  Exits non-zero on failure. Prints "THREAT MODEL VALIDATION OK: <path>" and exit 0 on success.
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

# 2) Every part well-formed XML; workbook.xml must declare at least one sheet
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
        if ($e.FullName -eq 'xl/workbook.xml' -and $content -notmatch '<sheet ') {
          $fail += "xl/workbook.xml declares no sheet"
        }
      }
    }
  } finally { $zip.Dispose() }
} catch {
  $fail += "Could not read archive: $($_.Exception.Message)"
}

if ($fail.Count -gt 0) {
  Write-Output "THREAT MODEL VALIDATION FAILED:"
  $fail | ForEach-Object { Write-Output " - $_" }
  exit 1
}
Write-Output "THREAT MODEL VALIDATION OK: $Xlsx"
exit 0
