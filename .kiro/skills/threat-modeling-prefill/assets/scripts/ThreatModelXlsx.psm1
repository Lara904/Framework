<#
  ThreatModelXlsx.psm1 - build a valid .xlsx (Excel) Threat Modeling (STRIDE-LM) workbook
  from a structured JSON model, WITHOUT Python or Microsoft Office.

  A .xlsx is an OPC package (a ZIP of Open XML parts). This module writes the minimal set of
  valid parts and zips them with ZipArchiveMode.Create (NEVER Update - Update corrupts OPC
  packages and triggers "repair on open"). All parts are UTF-8 WITHOUT BOM; cell text is
  XML-escaped and stored as inline strings (no sharedStrings table). English, like the other
  deliverables.

  The workbook has three sheets:
    1. "Cover" - project, engine, the mandatory "TO BE VALIDATED BY THE SECURITY TEAM" banner,
       scenario count, and the risk/effectiveness scales.
    2. "Threat Scenarios" - one row per STRIDE-LM scenario (ID, element, scope, scenario,
       STRIDE-LM, occurrence, impact, risk level, countermeasures, effectiveness, NIST,
       validation status).
    3. "NIST Mapping" - scenario id -> NIST SP 800-53 families touched.

  Public function:
    New-ThreatModelXlsx -Model <hashtable|pscustomobject> -OutFile <path>

  Model schema: see references/model-schema.md.
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

function Get-XlsxColLetter {
  param([int]$Index)
  $letters = ''
  while ($Index -gt 0) {
    $rem = ($Index - 1) % 26
    $letters = [char](65 + $rem) + $letters
    $Index = [math]::Floor(($Index - 1) / 26)
  }
  return $letters
}

function New-XlsxCell {
  param([int]$Col, [int]$Row, [string]$Text, [int]$StyleId = 0)
  $ref = (Get-XlsxColLetter -Index $Col) + $Row
  $styleAttr = if ($StyleId -gt 0) { ' s="' + $StyleId + '"' } else { '' }
  if ($null -eq $Text -or $Text -eq '') {
    if ($StyleId -gt 0) { return ('<c r="{0}"{1}/>' -f $ref, $styleAttr) } else { return '' }
  }
  return ('<c r="{0}"{1} t="inlineStr"><is><t xml:space="preserve">{2}</t></is></c>' -f $ref, $styleAttr, (ConvertTo-XlsxText $Text))
}

function New-XlsxRow {
  param([int]$RowNum, [string[]]$Values, [int]$StyleId = 0)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append(('<row r="{0}">' -f $RowNum))
  $col = 1
  foreach ($v in $Values) {
    [void]$sb.Append((New-XlsxCell -Col $col -Row $RowNum -Text ([string]$v) -StyleId $StyleId))
    $col++
  }
  [void]$sb.Append('</row>')
  return $sb.ToString()
}

function Get-XlsxSheetData {
  param([string[]]$Header, [object[]]$Rows, [string]$Title = '')
  $sb = New-Object System.Text.StringBuilder
  $r = 1
  if ($Title -ne '') {
    [void]$sb.Append((New-XlsxRow -RowNum $r -Values @($Title) -StyleId 1))
    $r += 2
  }
  [void]$sb.Append((New-XlsxRow -RowNum $r -Values $Header -StyleId 2))
  $r++
  foreach ($row in $Rows) {
    [void]$sb.Append((New-XlsxRow -RowNum $r -Values $row -StyleId 0))
    $r++
  }
  return $sb.ToString()
}

function Get-XlsxWorksheetXml {
  param([string]$SheetData, [int]$ColCount)
@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <cols><col min="1" max="$ColCount" width="24" customWidth="1"/></cols>
  <sheetData>$SheetData</sheetData>
</worksheet>
"@
}

function Get-XlsxStylesXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="3">
    <font><sz val="11"/><name val="Calibri"/></font>
    <font><b/><sz val="16"/><color rgb="FF8B0000"/><name val="Calibri"/></font>
    <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFB85450"/><bgColor indexed="64"/></patternFill></fill>
  </fills>
  <borders count="2">
    <border><left/><right/><top/><bottom/><diagonal/></border>
    <border><left style="thin"><color rgb="FF999999"/></left><right style="thin"><color rgb="FF999999"/></right><top style="thin"><color rgb="FF999999"/></top><bottom style="thin"><color rgb="FF999999"/></bottom><diagonal/></border>
  </borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="3">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
    <xf numFmtId="0" fontId="2" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
  </cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>
'@
}

function Get-XlsxWorkbookXml {
  param([string[]]$SheetNames)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
  [void]$sb.Append('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>')
  $id = 1
  foreach ($n in $SheetNames) {
    [void]$sb.Append(('<sheet name="{0}" sheetId="{1}" r:id="rId{1}"/>' -f (ConvertTo-XlsxText $n), $id))
    $id++
  }
  [void]$sb.Append('</sheets></workbook>')
  return $sb.ToString()
}

function Get-XlsxWorkbookRelsXml {
  param([int]$SheetCount)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
  [void]$sb.Append('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
  for ($i = 1; $i -le $SheetCount; $i++) {
    [void]$sb.Append(('<Relationship Id="rId{0}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{0}.xml"/>' -f $i))
  }
  $styleId = $SheetCount + 1
  [void]$sb.Append(('<Relationship Id="rId{0}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' -f $styleId))
  [void]$sb.Append('</Relationships>')
  return $sb.ToString()
}

function Get-XlsxContentTypesXml {
  param([int]$SheetCount)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
  [void]$sb.Append('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
  [void]$sb.Append('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
  [void]$sb.Append('<Default Extension="xml" ContentType="application/xml"/>')
  [void]$sb.Append('<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>')
  for ($i = 1; $i -le $SheetCount; $i++) {
    [void]$sb.Append(('<Override PartName="/xl/worksheets/sheet{0}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' -f $i))
  }
  [void]$sb.Append('<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>')
  [void]$sb.Append('<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>')
  [void]$sb.Append('<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>')
  [void]$sb.Append('</Types>')
  return $sb.ToString()
}

function Get-XlsxRootRelsXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'@
}

function Get-XlsxCoreXml {
  param([string]$Title, [string]$Author, [string]$Date)
  $t = ConvertTo-XlsxText $Title
  $a = ConvertTo-XlsxText $Author
  $iso = "$Date" + "T00:00:00Z"
@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>$t</dc:title>
  <dc:creator>$a</dc:creator>
  <cp:lastModifiedBy>$a</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$iso</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$iso</dcterms:modified>
</cp:coreProperties>
"@
}

function Get-XlsxAppXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>Kiro threat-modeling-prefill skill</Application>
</Properties>
'@
}

function New-ThreatModelXlsx {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)] $Model,
    [Parameter(Mandatory=$true)] [string]$OutFile
  )

  if ($Model -is [string]) { $Model = $Model | ConvertFrom-Json }
  if ($Model -is [hashtable]) { $Model = [pscustomobject]$Model }

  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $utf8 = New-Object System.Text.UTF8Encoding($false)

  function Get-Prop($obj, $name, $default = '') {
    if ($null -eq $obj) { return $default }
    if ($obj.PSObject.Properties.Name -contains $name) {
      $v = $obj.$name
      if ($null -eq $v) { return $default }
      return $v
    }
    return $default
  }

  $scenarios = @(Get-Prop $Model 'scenarios' @())

  # ---- Sheet 1: Cover ----
  $coverSb = New-Object System.Text.StringBuilder
  $r = 1
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Threat Modeling (STRIDE-LM) - pre-fill') -StyleId 1)); $r += 2
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('STATUS: TO BE VALIDATED BY THE SECURITY TEAM - NOT ACQUIRED') -StyleId 2)); $r += 2
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Project', (Get-Prop $Model 'subtitle')) -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Author', (Get-Prop $Model 'author')) -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Date', (Get-Prop $Model 'date')) -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('AI engine', (Get-Prop $Model 'engine' 'AWS Bedrock (direct call)')) -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Inputs', (Get-Prop $Model 'inputs' 'DAT + dataflow')) -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Scenario count', ([string]$scenarios.Count)) -StyleId 0)); $r += 2
  $disclaimer = Get-Prop $Model 'disclaimer' 'This threat model is a PRE-FILL produced to accelerate preparation. Every scenario, score and countermeasure is a CANDIDATE to be reviewed, corrected and validated by the SFES Cybersecurity team before use. It does not replace the security risk analysis.'
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Disclaimer') -StyleId 2)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @($disclaimer) -StyleId 0)); $r += 2
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Scales') -StyleId 2)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Occurrence', '1 Rare / 2 Unlikely / 3 Possible / 4 Likely') -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Impact', '1 Negligible / 2 Moderate / 3 Serious / 4 Severe') -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Risk level', 'occurrence x impact: 1-3 Low / 4-7 Medium / 8-11 High / 12-16 Critical') -StyleId 0)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Countermeasure effectiveness', '0 None / 1 Weak / 2 Moderate / 3 Strong') -StyleId 0)); $r++
  $coverXml = Get-XlsxWorksheetXml -SheetData $coverSb.ToString() -ColCount 2

  # ---- Sheet 2: Threat Scenarios ----
  $sHeader = @('ID','Element / asset','Scope','Threat scenario','STRIDE-LM','Occurrence (1-4)','Impact (1-4)','Risk level','Countermeasures','Effectiveness (0-3)','NIST families','Validation status')
  $sRows = @()
  foreach ($s in $scenarios) {
    $sRows += ,@(
      (Get-Prop $s 'id'), (Get-Prop $s 'element'), (Get-Prop $s 'scope'), (Get-Prop $s 'scenario'),
      (Get-Prop $s 'stride'), (Get-Prop $s 'occurrence'), (Get-Prop $s 'impact'), (Get-Prop $s 'riskLevel'),
      (Get-Prop $s 'countermeasures'), (Get-Prop $s 'effectiveness'), (Get-Prop $s 'nist'),
      (Get-Prop $s 'validationStatus' 'To be validated by the security team')
    )
  }
  $scenData = Get-XlsxSheetData -Header $sHeader -Rows $sRows
  $scenXml = Get-XlsxWorksheetXml -SheetData $scenData -ColCount $sHeader.Count

  # ---- Sheet 3: NIST Mapping ----
  $nHeader = @('Scenario ID','STRIDE-LM','NIST SP 800-53 families','Family names')
  $nRows = @()
  foreach ($s in $scenarios) {
    $nRows += ,@(
      (Get-Prop $s 'id'), (Get-Prop $s 'stride'), (Get-Prop $s 'nist'), (Get-Prop $s 'nistNames')
    )
  }
  $nistData = Get-XlsxSheetData -Header $nHeader -Rows $nRows -Title 'STRIDE-LM -> NIST SP 800-53 mapping'
  $nistXml = Get-XlsxWorksheetXml -SheetData $nistData -ColCount $nHeader.Count

  $sheetNames = @('Cover', 'Threat Scenarios', 'NIST Mapping')
  $sheetCount = $sheetNames.Count

  $parts = @{
    '[Content_Types].xml'        = (Get-XlsxContentTypesXml -SheetCount $sheetCount)
    '_rels/.rels'                = (Get-XlsxRootRelsXml)
    'xl/workbook.xml'            = (Get-XlsxWorkbookXml -SheetNames $sheetNames)
    'xl/_rels/workbook.xml.rels' = (Get-XlsxWorkbookRelsXml -SheetCount $sheetCount)
    'xl/worksheets/sheet1.xml'   = $coverXml
    'xl/worksheets/sheet2.xml'   = $scenXml
    'xl/worksheets/sheet3.xml'   = $nistXml
    'xl/styles.xml'              = (Get-XlsxStylesXml)
    'docProps/core.xml'          = (Get-XlsxCoreXml -Title (Get-Prop $Model 'title' 'Threat Modeling (STRIDE-LM)') -Author (Get-Prop $Model 'author' '') -Date (Get-Prop $Model 'date' ''))
    'docProps/app.xml'           = (Get-XlsxAppXml)
  }
  $order = @('[Content_Types].xml','_rels/.rels','xl/workbook.xml','xl/_rels/workbook.xml.rels','xl/worksheets/sheet1.xml','xl/worksheets/sheet2.xml','xl/worksheets/sheet3.xml','xl/styles.xml','docProps/core.xml','docProps/app.xml')

  if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
  $fs = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create)
  try {
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
      foreach ($name in $order) {
        $entry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
        $es = $entry.Open()
        $bytes = $utf8.GetBytes([string]$parts[$name])
        $es.Write($bytes, 0, $bytes.Length)
        $es.Close()
      }
    } finally { $zip.Dispose() }
  } finally { $fs.Dispose() }

  return (Resolve-Path $OutFile).Path
}

Export-ModuleMember -Function New-ThreatModelXlsx, ConvertTo-XlsxText
