<#
  build-fad.ps1 - generate a single-file Functional Architecture Dossier (FAD) as .docx
  from a JSON model, using the bundled FadDocx.psm1 module (no Python / Office needed).

  Usage:
    powershell -ExecutionPolicy Bypass -File build-fad.ps1 -Model "output/${project_name}/${project_name}_functional_architecture_document.model.json" -Out "output/${project_name}/${project_name}_functional_architecture_document.docx"
    (output location per the output-convention steering; -Out accepts any path)

  The JSON model schema is documented in references/fad-document.md. In short:
    {
      "title": "Functional Architecture Dossier",
      "subtitle": "<Project name>",
      "author": "<name>",
      "date": "YYYY-MM-DD",
      "version": "1.0",
      "objectOfDocument": "...",
      "audience": "...",
      "relatedDocuments": [ { "title": "Validated statement of needs", "reference": "..." } ],
      "revisions": [ { "version": "1.0", "date": "...", "chapters": "All", "motives": "Creation", "authors": "..." } ],
      "body": [
        { "type": "h1", "text": "The scope of the transformation project" },
        { "type": "h2", "text": "Positioning of project plan" },
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
Import-Module (Join-Path $PSScriptRoot 'FadDocx.psm1') -Force

if (-not (Test-Path $Model)) { throw "Model file not found: $Model" }
$raw = Get-Content -Path $Model -Raw -Encoding UTF8
$fadModel = $raw | ConvertFrom-Json

$path = New-FadDocx -Model $fadModel -OutFile $Out

# Fail loudly rather than silently: confirm the .docx was actually written.
if (-not (Test-Path $Out)) { throw "FAD generation reported success but no file was produced at: $Out" }
$len = (Get-Item $Out).Length
if ($len -lt 1000) { throw "FAD file looks too small ($len bytes), generation likely failed: $Out" }
Write-Output "FAD written: $path ($len bytes)"
