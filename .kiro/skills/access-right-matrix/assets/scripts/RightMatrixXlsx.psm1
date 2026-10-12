<#
  RightMatrixXlsx.psm1 - fill the SFS "Right matrix for CIQ, CI-CD and AWS Console"
  workbook by COPYING the bundled reference template and editing ONLY the target
  cells / placeholder tokens in place, WITHOUT Python or Microsoft Office.

  Why "edit in place" instead of "rebuild from scratch": the official template is a
  rich .xlsx (an OPC package) that carries cell comments, a drawing/logo, a hidden
  "Parameters" sheet with the data-validation drop-down lists, print settings, styles
  and defined names. Rebuilding those from scratch would lose them. So we:
    1. read every part of the template ZIP into memory (bytes),
    2. rewrite only  xl/sharedStrings.xml  (token substitution: <PRD>, optional
       <REFLEX_NAME ...>) and  xl/worksheets/sheet3.xml  (APPLICATION Information
       cells C3..C7),
    3. re-zip with ZipArchiveMode.Create (NEVER Update - Update corrupts OPC packages
       and triggers "repair on open"), copying all other parts VERBATIM (byte-for-byte).

  The reference template is READ-ONLY: this module never writes back to it, only to a
  copy saved under the deliverable name.

  Public function:
    New-RightMatrixXlsx -Model <hashtable|pscustomobject> -TemplatePath <path> -OutFile <path>

  Encoding: modified parts are written UTF-8 WITHOUT BOM. Cell text and token values
  are XML-escaped. Written in English like the source template.

  Model schema (see references/model-schema.md):
    {
      "prdCode": "ABCD",                      # substitutes every <PRD> token
      "reflexTechnicalName": "...",           # APPLICATION Information C3
      "reflexFunctionalName": "...",          # APPLICATION Information C4
      "dict": "D3 I3 C3 T2",                  # APPLICATION Information C5
      "prdCodeField": "ABCD",                 # APPLICATION Information C6 (usually = prdCode)
      "functionalDescription": "...",         # APPLICATION Information C7
      "reflexNameDev": "",                    # optional, replaces "<REFLEX_NAME of the DEV Application ...>"
      "reflexNamePre": "",                    # optional, replaces "<REFLEX_NAME of the PREPROD/preProduction Application ...>"
      "reflexNameProd": "",                   # optional, replaces "<REFLEX_NAME of the PROD/production Application>"
      "businessProfiles": "none" | "defined", # MANDATORY - see model-schema.md. No default:
                                               # missing/empty/anything else is a BUILD ERROR.
      "businessProfilesList": []              # required (non-empty) when businessProfiles="defined"
    }
  Any field left empty is NOT substituted: the original placeholder stays visible in
  the deliverable so a missing value is never silently invented. The ONE exception is
  `businessProfiles`: the ABSENCE of a decision there must never be invented either, so
  New-RightMatrixXlsx THROWS rather than leaving the "Matrix of BUSINESS rights" sheet
  silently blank (the defect this module originally had - see git history / SKILL.md).
#>

Set-StrictMode -Version Latest

function ConvertTo-XlsxText {
  param([string]$Text)
  if ($null -eq $Text) { return '' }
  $t = $Text -replace '&', '&amp;'
  $t = $t -replace '<', '&lt;'
  $t = $t -replace '>', '&gt;'
  $t = $t -replace '"', '&quot;'
  $t = $t -replace "'", '&apos;'
  return $t
}

function Get-RmProp {
  param($Obj, [string]$Name, [string]$Default = '')
  if ($null -eq $Obj) { return $Default }
  if ($Obj.PSObject.Properties.Name -contains $Name) {
    $v = $Obj.$Name
    if ($null -eq $v) { return $Default }
    return [string]$v
  }
  return $Default
}

function Set-RmSharedStrings {
  <# Token substitution in the sharedStrings.xml text. Only replaces a token when the
     replacement value is non-empty. Tokens live in the XML as escaped text, e.g.
     "<PRD>" is stored as "&lt;PRD&gt;". #>
  param([string]$Xml, $Model)

  $prd = Get-RmProp $Model 'prdCode'
  if ($prd -ne '') {
    $Xml = $Xml.Replace('&lt;PRD&gt;', (ConvertTo-XlsxText $prd))
  }

  # Optional REFLEX_NAME descriptive placeholders. These appear in several verbose
  # forms; we replace the whole "<REFLEX_NAME ...>" / "<Reflex_Application>" span only
  # when the caller provided a value.
  $dev  = Get-RmProp $Model 'reflexNameDev'
  $pre  = Get-RmProp $Model 'reflexNamePre'
  $prod = Get-RmProp $Model 'reflexNameProd'

  if ($dev -ne '') {
    $Xml = [regex]::Replace($Xml, '&lt;REFLEX_NAME of the DEV Application[^&]*?&gt;', (ConvertTo-XlsxText $dev))
  }
  if ($pre -ne '') {
    $Xml = [regex]::Replace($Xml, '&lt;REFLEX_NAME of the (PREPROD|preProduction) Application[^&]*?&gt;', (ConvertTo-XlsxText $pre))
    $Xml = $Xml.Replace('&lt;REFLEX_NAME of thepreProduction Application&gt;', (ConvertTo-XlsxText $pre))
  }
  if ($prod -ne '') {
    $Xml = [regex]::Replace($Xml, '&lt;REFLEX_NAME of the (PROD|production) Application&gt;', (ConvertTo-XlsxText $prod))
  }
  # <Reflex_Application> generic token: prefer prod name, else technical name.
  $generic = if ($prod -ne '') { $prod } elseif ((Get-RmProp $Model 'reflexTechnicalName') -ne '') { Get-RmProp $Model 'reflexTechnicalName' } else { '' }
  if ($generic -ne '') {
    $Xml = $Xml.Replace('&lt;Reflex_Application&gt;', (ConvertTo-XlsxText $generic))
  }
  return $Xml
}

function Set-RmCell {
  <# Replace an empty styled cell "<c r="REF" s="N"/>" with an inline-string cell
     carrying Value. If the cell is not found empty (already has content), it is left
     untouched and a warning is emitted. #>
  param([string]$Xml, [string]$Ref, [string]$Value)
  if ($Value -eq '') { return $Xml }
  $esc = ConvertTo-XlsxText $Value
  $pattern = '<c r="' + [regex]::Escape($Ref) + '"( s="\d+")?\s*/>'
  $m = [regex]::Match($Xml, $pattern)
  if (-not $m.Success) {
    Write-Warning "Cell $Ref not found as an empty cell; left unchanged."
    return $Xml
  }
  $styleAttr = $m.Groups[1].Value
  $replacement = '<c r="' + $Ref + '"' + $styleAttr + ' t="inlineStr"><is><t xml:space="preserve">' + $esc + '</t></is></c>'
  # Replace only the first matched empty cell (literal replace of the exact match text).
  $idx = $Xml.IndexOf($m.Value)
  if ($idx -lt 0) { return $Xml }
  return $Xml.Substring(0, $idx) + $replacement + $Xml.Substring($idx + $m.Value.Length)
}

function Get-RmColumnLetter {
  <# 1-based column index -> Excel column letter (1=A, 2=B, ... 19=S... wait: Profile 1
     lives in column B, so column index = ProfileNumber + 1). Handles up to column Z
     (the template's 19 business profiles need at most column T). #>
  param([int]$Index)
  if ($Index -lt 1 -or $Index -gt 26) { throw "Column index out of supported range (1-26): $Index" }
  [char](64 + $Index)
}

function New-RightMatrixXlsx {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)] $Model,
    [Parameter(Mandatory=$true)] [string]$TemplatePath,
    [Parameter(Mandatory=$true)] [string]$OutFile
  )

  if ($Model -is [string]) { $Model = $Model | ConvertFrom-Json }
  if ($Model -is [hashtable]) { $Model = [pscustomobject]$Model }
  if (-not (Test-Path $TemplatePath)) { throw "Template not found: $TemplatePath" }

  # --- businessProfiles is MANDATORY: refuse to build rather than leave the "Matrix of
  #     BUSINESS rights" sheet silently at its blank template state (see model-schema.md,
  #     "No silent skip"). This is the one case where an undecided value is an error, not
  #     a placeholder-left-visible situation, because a blank sheet with no marker is
  #     indistinguishable from "nobody looked at this".
  $bp = Get-RmProp $Model 'businessProfiles'
  if ($bp -ne 'none' -and $bp -ne 'defined') {
    throw "Model field 'businessProfiles' must be exactly 'none' or 'defined' (got '$bp'). " +
          "Ask the user whether business profiles apply to this project (questionnaire.md #10) " +
          "before generating - do not default this value."
  }
  $bpList = @()
  if ($bp -eq 'defined') {
    if ($Model.PSObject.Properties.Name -contains 'businessProfilesList') { $bpList = @($Model.businessProfilesList) }
    if ($bpList.Count -eq 0) { throw "businessProfiles='defined' but 'businessProfilesList' is empty. Provide at least one profile, or set businessProfiles='none'." }
    if ($bpList.Count -gt 19) { throw "businessProfilesList has $($bpList.Count) entries; the template has only 19 business-profile columns (never add columns)." }
  }

  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $utf8 = New-Object System.Text.UTF8Encoding($false)

  # --- 1. Read every part of the template into memory (bytes) ---
  $entries = New-Object System.Collections.Generic.List[object]
  $zin = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $TemplatePath).Path)
  try {
    foreach ($e in $zin.Entries) {
      $ms = New-Object System.IO.MemoryStream
      $s = $e.Open(); $s.CopyTo($ms); $s.Close()
      $entries.Add([pscustomobject]@{ Name = $e.FullName; Bytes = $ms.ToArray() })
      $ms.Dispose()
    }
  } finally { $zin.Dispose() }

  # --- 2. Rewrite the two parts we edit ---
  # APPLICATION Information is sheet3.xml (index=Guide=Guide... mapping: sheet1=index,
  # sheet2=Guide, sheet3=APPLICATION Information, sheet4=BUSINESS, sheet5=TECHNICAL).
  $appInfoCells = @{
    'C3' = (Get-RmProp $Model 'reflexTechnicalName')
    'C4' = (Get-RmProp $Model 'reflexFunctionalName')
    'C5' = (Get-RmProp $Model 'dict')
    'C6' = (Get-RmProp $Model 'prdCodeField')
    'C7' = (Get-RmProp $Model 'functionalDescription')
  }

  for ($i = 0; $i -lt $entries.Count; $i++) {
    $name = $entries[$i].Name
    if ($name -eq 'xl/sharedStrings.xml') {
      $txt = $utf8.GetString($entries[$i].Bytes)
      # strip a possible BOM
      if ($txt.Length -gt 0 -and $txt[0] -eq [char]0xFEFF) { $txt = $txt.Substring(1) }
      $txt = Set-RmSharedStrings -Xml $txt -Model $Model
      $entries[$i].Bytes = $utf8.GetBytes($txt)
    }
    elseif ($name -eq 'xl/worksheets/sheet3.xml') {
      $txt = $utf8.GetString($entries[$i].Bytes)
      if ($txt.Length -gt 0 -and $txt[0] -eq [char]0xFEFF) { $txt = $txt.Substring(1) }
      foreach ($ref in $appInfoCells.Keys) {
        $txt = Set-RmCell -Xml $txt -Ref $ref -Value $appInfoCells[$ref]
      }
      $entries[$i].Bytes = $utf8.GetBytes($txt)
    }
    elseif ($name -eq 'xl/worksheets/sheet4.xml') {
      # "Matrix of BUSINESS rights". Row layout (fixed template, never add/remove rows):
      #   row4=Label row5=Description row6=User type row7=Assignment method
      #   row8=Access service code row9=Level of delegation row10=Confidentiality
      #   row11=Integrity row17=Feature 1 row18=Feature 2 (only 2 feature slots exist).
      # Column B = Profile 1 ... column T = Profile 19 (column index = profile number + 1).
      $txt = $utf8.GetString($entries[$i].Bytes)
      if ($txt.Length -gt 0 -and $txt[0] -eq [char]0xFEFF) { $txt = $txt.Substring(1) }

      if ($bp -eq 'none') {
        # Single, unmissable marker that a decision WAS made (vs. an untouched template).
        $txt = Set-RmCell -Xml $txt -Ref 'B4' -Value 'N/A - no business profile for this scope (see README)'
      }
      else {
        for ($n = 0; $n -lt $bpList.Count; $n++) {
          $prof = $bpList[$n]
          $col = Get-RmColumnLetter -Index ($n + 2)   # Profile 1 -> B (index 2)
          $cells = @{
            ($col + '4')  = (Get-RmProp $prof 'label')
            ($col + '5')  = (Get-RmProp $prof 'description')
            ($col + '6')  = (Get-RmProp $prof 'userType')
            ($col + '7')  = (Get-RmProp $prof 'assignmentMethod')
            ($col + '8')  = (Get-RmProp $prof 'accessServiceCode')
            ($col + '9')  = (Get-RmProp $prof 'delegationLevel')
            ($col + '10') = (Get-RmProp $prof 'confidentiality')
            ($col + '11') = (Get-RmProp $prof 'integrity')
          }
          $features = @()
          if ($prof.PSObject.Properties.Name -contains 'features') { $features = @($prof.features) }
          if ($features.Count -gt 0) { $cells[($col + '17')] = [string]$features[0] }
          if ($features.Count -gt 1) { $cells[($col + '18')] = [string]$features[1] }
          if ($features.Count -gt 2) {
            Write-Warning "Profile '$($cells[$col+'4'])' has $($features.Count) features; only 2 feature rows exist in the template (Feature 1/Feature 2) - the rest are not written. List them in the README instead of adding rows."
          }
          foreach ($ref in $cells.Keys) {
            if ([string]$cells[$ref] -eq '') { continue }
            $txt = Set-RmCell -Xml $txt -Ref $ref -Value ([string]$cells[$ref])
          }
        }
      }
      $entries[$i].Bytes = $utf8.GetBytes($txt)
    }
  }

  # --- 3. Re-zip with Create (never Update), copying all parts verbatim ---
  if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
  $fs = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create)
  try {
    $zout = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
      foreach ($ent in $entries) {
        $ze = $zout.CreateEntry($ent.Name, [System.IO.Compression.CompressionLevel]::Optimal)
        $os = $ze.Open()
        $os.Write($ent.Bytes, 0, $ent.Bytes.Length)
        $os.Close()
      }
    } finally { $zout.Dispose() }
  } finally { $fs.Dispose() }

  return (Resolve-Path $OutFile).Path
}

Export-ModuleMember -Function New-RightMatrixXlsx, ConvertTo-XlsxText
