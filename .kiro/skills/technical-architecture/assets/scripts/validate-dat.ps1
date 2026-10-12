<#
  validate-dat.ps1 - authoritative check that a generated DAT .docx is a valid OPC
  package Word will open without "repair". Mirrors the presentation-gates validation
  philosophy: validate at the WINDOWS/OPC layer, not just XML well-formedness.

  Usage:
    powershell -ExecutionPolicy Bypass -File validate-dat.ps1 -Docx "<project>_technical_architecture_document.docx"

  Exits non-zero on failure.
#>
param(
  [Parameter(Mandatory=$true)] [string]$Docx
)

$ErrorActionPreference = 'Stop'
$fail = @()

if (-not (Test-Path $Docx)) { Write-Error "File not found: $Docx"; exit 2 }

# 1) OPC package must open (the authoritative "would Word repair this?" test)
try {
  Add-Type -AssemblyName WindowsBase
  $pkg = [System.IO.Packaging.Package]::Open((Resolve-Path $Docx).Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
  $partCount = ($pkg.GetParts() | Measure-Object).Count
  $pkg.Close()
  Write-Output "OPC package opens cleanly ($partCount parts)."
} catch {
  $fail += "OPC package failed to open (Word would offer to repair): $($_.Exception.Message)"
}

# 2) Every part must be well-formed XML; document.xml must contain a body
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Docx).Path)
  try {
    foreach ($e in $zip.Entries) {
      if ($e.FullName -like '*.xml' -or $e.FullName -like '*.rels') {
        $sr = New-Object System.IO.StreamReader($e.Open())
        $content = $sr.ReadToEnd(); $sr.Close()
        try { [xml]$content | Out-Null }
        catch { $fail += "Malformed XML part: $($e.FullName)" }
        if ($e.FullName -eq 'word/document.xml' -and $content -notmatch '<w:body>') {
          $fail += "word/document.xml has no <w:body>"
        }
      }
    }
  } finally { $zip.Dispose() }
} catch {
  $fail += "Could not read archive: $($_.Exception.Message)"
}

if ($fail.Count -gt 0) {
  Write-Output "DAT VALIDATION FAILED:"
  $fail | ForEach-Object { Write-Output " - $_" }
  exit 1
}
Write-Output "DAT VALIDATION OK: $Docx"
exit 0
