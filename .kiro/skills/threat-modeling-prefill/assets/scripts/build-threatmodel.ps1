<#
  build-threatmodel.ps1 - generate the Threat Modeling (STRIDE-LM) pre-fill workbook (.xlsx)
  from a JSON model, using the bundled ThreatModelXlsx.psm1 module (no Python / Office).

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File build-threatmodel.ps1 `
      -Model "output/${project_name}/${project_name}_threat_modeling.model.json" -Out "output/${project_name}/${project_name}_threat_modeling.xlsx"
    (output location per the output-convention steering; -Out accepts any path)

  The JSON model schema is documented in references/model-schema.md. The scenario wording is
  expected to have been produced by an explicit model call (AWS Bedrock by default); this script
  only renders the structured result into a valid workbook. Every scenario is a CANDIDATE to be
  validated by the security team.
#>
param(
  [Parameter(Mandatory=$true)] [string]$Model,
  [Parameter(Mandatory=$true)] [string]$Out
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'ThreatModelXlsx.psm1') -Force

if (-not (Test-Path $Model)) { throw "Model file not found: $Model" }
$raw = Get-Content -Path $Model -Raw -Encoding UTF8
$tmModel = $raw | ConvertFrom-Json

$path = New-ThreatModelXlsx -Model $tmModel -OutFile $Out

if (-not (Test-Path $Out)) { throw "Threat model generation reported success but no file was produced at: $Out" }
$len = (Get-Item $Out).Length
if ($len -lt 1000) { throw "Threat model file looks too small ($len bytes), generation likely failed: $Out" }
Write-Output "Threat model written: $path ($len bytes)"
