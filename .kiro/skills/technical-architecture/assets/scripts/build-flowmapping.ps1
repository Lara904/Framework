<#
  build-flowmapping.ps1 - generate the Data Flow Mapping workbook as .xlsx from a JSON
  model, using the bundled FlowMappingXlsx.psm1 module (no Python / Office needed).

  Usage:
    powershell -ExecutionPolicy Bypass -File build-flowmapping.ps1 -Model "output/${project_name}/${project_name}_technical_architecture_dataflow_mapping.model.json" -Out "output/${project_name}/${project_name}_technical_architecture_dataflow_mapping.xlsx"
    (output location per the output-convention steering; -Out accepts any path)

  The JSON model schema is documented in references/data-flow-mapping.md.
#>
param(
  [Parameter(Mandatory=$true)] [string]$Model,
  [Parameter(Mandatory=$true)] [string]$Out
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'FlowMappingXlsx.psm1') -Force

if (-not (Test-Path $Model)) { throw "Model file not found: $Model" }
$raw = Get-Content -Path $Model -Raw -Encoding UTF8
$fmModel = $raw | ConvertFrom-Json

$path = New-FlowMappingXlsx -Model $fmModel -OutFile $Out

# Fail loudly rather than silently: confirm the .xlsx was actually written.
if (-not (Test-Path $Out)) { throw "Flow mapping generation reported success but no file was produced at: $Out" }
$len = (Get-Item $Out).Length
if ($len -lt 1000) { throw "Flow mapping file looks too small ($len bytes), generation likely failed: $Out" }
Write-Output "Flow mapping written: $path ($len bytes)"
