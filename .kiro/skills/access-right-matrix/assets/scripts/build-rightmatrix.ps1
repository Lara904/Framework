<#
  build-rightmatrix.ps1 - generate the filled Access Right Matrix .xlsx from a JSON
  model, by copying the bundled reference template and editing only the target cells
  and placeholder tokens (no Python / Office needed).

  Usage:
    powershell -ExecutionPolicy Bypass -File build-rightmatrix.ps1 \
      -Model "output/${project_name}/${project_name}_access_right_matrix.model.json" \
      -Out   "output/${project_name}/${project_name}_access_right_matrix.xlsx"
    (output location per the output-convention steering; -Out accepts any path)

  Optional -Template overrides the bundled template path (default: the template under
  assets/templates next to this script). The JSON model schema is documented in
  references/model-schema.md. The template is READ-ONLY and never modified.
#>
param(
  [Parameter(Mandatory=$true)] [string]$Model,
  [Parameter(Mandatory=$true)] [string]$Out,
  [string]$Template
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'RightMatrixXlsx.psm1') -Force

if (-not $Template -or $Template -eq '') {
  $Template = Join-Path $PSScriptRoot '..\templates\SFS_right_matrix_for_ciq_and_CI_CD_AWS_NG_v2026_03.xlsx'
}
if (-not (Test-Path $Model)) { throw "Model file not found: $Model" }
if (-not (Test-Path $Template)) { throw "Template not found: $Template" }

$raw = Get-Content -Path $Model -Raw -Encoding UTF8
$rmModel = $raw | ConvertFrom-Json

$path = New-RightMatrixXlsx -Model $rmModel -TemplatePath $Template -OutFile $Out
Write-Output "Access right matrix written: $path"
