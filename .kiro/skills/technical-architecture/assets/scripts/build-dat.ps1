<#
  build-dat.ps1 - generate a single-file Technical Architecture Document (DAT) as .docx
  from a JSON model, using the bundled DatDocx.psm1 module (no Python / Office needed).

  Usage:
    powershell -ExecutionPolicy Bypass -File build-dat.ps1 -Model "output/${project_name}/${project_name}_technical_architecture_document.model.json" -Out "output/${project_name}/${project_name}_technical_architecture_document.docx"
    (output location per the output-convention steering; -Out accepts any path)

  The JSON model schema is documented in references/dat-document.md. In short
  (values below are an example, fictional - replace with the real application's):
    {
      "title": "Technical Architecture Document",
      "subtitle": "My Application",
      "author": "Kiro",
      "date": "2026-07-17",
      "revisions": [ { "date": "...", "revision": "1.0", "object": "...", "author": "..." } ],
      "body": [
        { "type": "h1", "text": "Introduction" },
        { "type": "p",  "text": "..." },
        { "type": "bullets", "items": ["a", "b"] },
        { "type": "table", "header": ["Col1","Col2"], "rows": [["x","y"]] },
        { "type": "pagebreak" }
      ]
    }
#>
param(
  [Parameter(Mandatory=$true)] [string]$Model,
  [Parameter(Mandatory=$true)] [string]$Out
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'DatDocx.psm1') -Force

if (-not (Test-Path $Model)) { throw "Model file not found: $Model" }
$raw = Get-Content -Path $Model -Raw -Encoding UTF8
$datModel = $raw | ConvertFrom-Json

$path = New-DatDocx -Model $datModel -OutFile $Out

# Fail loudly rather than silently: confirm the .docx was actually written.
if (-not (Test-Path $Out)) { throw "DAT generation reported success but no file was produced at: $Out" }
$len = (Get-Item $Out).Length
if ($len -lt 1000) { throw "DAT file looks too small ($len bytes), generation likely failed: $Out" }
Write-Output "DAT written: $path ($len bytes)"
