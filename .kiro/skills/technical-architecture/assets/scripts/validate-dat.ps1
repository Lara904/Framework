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
        # 2b) Every <w:tbl> must carry a <w:tblGrid> (ECMA-376 17.4.49: mandatory child).
        # Well-formed XML and a clean OPC-package open (checks 1 and 2 above) do NOT
        # catch this: Word silently repairs a missing tblGrid on open instead of
        # erroring, and strict readers (python-docx, Pandoc, ...) throw InvalidXmlError.
        # This exact defect shipped undetected for every table New-DatTable produced
        # (all 15 tables in a typical DAT) before tblGrid support was added to that
        # function - keep this check so a future regression fails CI instead of
        # reaching a Gate reviewer's Word.
        if ($e.FullName -eq 'word/document.xml') {
          $tblMatches = [regex]::Matches($content, '<w:tbl>.*?</w:tbl>', 'Singleline')
          $missingGrid = 0
          foreach ($m in $tblMatches) { if ($m.Value -notmatch '<w:tblGrid>') { $missingGrid++ } }
          if ($missingGrid -gt 0) {
            $fail += "$missingGrid of $($tblMatches.Count) <w:tbl> element(s) in word/document.xml are missing the mandatory <w:tblGrid> child"
          }
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
