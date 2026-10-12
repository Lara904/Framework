<#
  FlowMappingXlsx.psm1 - build a valid .xlsx (Excel) Data Flow Mapping workbook
  from a structured JSON model, WITHOUT Python or Microsoft Office.

  Why a module: a .xlsx is an OPC package (a ZIP of Open XML parts). This module
  writes the minimal set of valid parts (workbook.xml, worksheets, styles, rels,
  content types) and zips them with ZipArchiveMode.Create (NEVER Update - Update
  corrupts OPC packages and triggers "repair on open", exactly like the DatDocx and
  the .pptx lessons).

  It reproduces the official Stellantis "Data flow mapping" workbook (derived from the
  reference example, see assets/templates/): a Cover sheet, a "Functional Flow Pattern"
  sheet and a "Technical Flow Pattern" sheet, with the official columns and the
  C1/C2/C3/C4 + DCP classification (including the DCP breakdown columns Party / Party
  identification / Banking information / Sensitive personal data).

  Public function:
    New-FlowMappingXlsx -Model <hashtable|pscustomobject> -OutFile <path>

  Encoding: all parts are UTF-8 WITHOUT BOM. Cell text is XML-escaped and stored as
  inline strings (no sharedStrings table needed). Written in English like the other
  deliverables.

  Model schema (see references/data-flow-mapping.md):
    {
      "title": "Data flow mapping",
      "subtitle": "<App name>",
      "author": "<name>",
      "date": "YYYY-MM-DD",
      "purpose": "<one line>",
      "objective": "<one line>",
      "sources": [ { "type":"CMDB", "sheet":"Dependencies", "extractionDate":"YYYY-MM-DD", "url":"..." } ],
      "assumptions": [ "line 1", "line 2" ],
      "method": [ "rule 1", "rule 2" ],
      "versions": [ { "version":"0.1", "type":"flow map", "updatedDate":"YYYY-MM-DD", "updatedBy":"<name>", "owners":"", "comments":"" } ],
      "functionalFlows": [
        { "name":"", "treatment":"", "source":"", "destination":"", "frequency":"",
          "confidentiality":"C3", "dcp":"No", "party":"No", "partyIdentification":"No",
          "bankingInformation":"No", "sensitiveData":"No", "dataType":"" }
      ],
      "technicalFlows": [
        { "functionalName":"", "name":"", "type":"", "source":"", "hostnameSource":"",
          "destination":"", "hostnameDestination":"", "frequency":"",
          "confidentiality":"C1", "dcp":"No", "port":"443", "protocol":"https",
          "tokenSupplier":"", "endpoint":"", "apicProduct":"" }
      ]
    }
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
  param([int]$Index)  # 1-based
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
  param([int]$RowNum, [string[]]$Values, [int]$StyleId = 0, [int]$FirstCol = 1)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append(('<row r="{0}">' -f $RowNum))
  $col = $FirstCol
  foreach ($v in $Values) {
    [void]$sb.Append((New-XlsxCell -Col $col -Row $RowNum -Text ([string]$v) -StyleId $StyleId))
    $col++
  }
  [void]$sb.Append('</row>')
  return $sb.ToString()
}

function Get-XlsxSheetData {
  param([string[]]$Header, [object[]]$Rows, [string]$Title = '')
  # StyleId 1 = title, 2 = header (bold + shaded), 0 = normal
  $sb = New-Object System.Text.StringBuilder
  $r = 1
  if ($Title -ne '') {
    [void]$sb.Append((New-XlsxRow -RowNum $r -Values @($Title) -StyleId 1))
    $r += 2  # blank row after title
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
  $lastCol = Get-XlsxColLetter -Index ([math]::Max(1, $ColCount))
@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <cols><col min="1" max="$ColCount" width="26" customWidth="1"/></cols>
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
    <font><b/><sz val="16"/><color rgb="FF1F3864"/><name val="Calibri"/></font>
    <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF4472C4"/><bgColor indexed="64"/></patternFill></fill>
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
  <Application>Kiro technical-architecture skill</Application>
</Properties>
'@
}

function New-FlowMappingXlsx {
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

  # ---- Sheet 1: Cover sheet (mirrors the official template: Purpose, Objective,
  #      Sources, Assumptions & Rules, Method, Version) ----
  $coverSb = New-Object System.Text.StringBuilder
  $r = 1
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Purpose') -StyleId 2)); $r++
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @((Get-Prop $Model 'purpose' 'The purpose of this spreadsheet is to give a list of dependencies between the applications of our Information System.')) -StyleId 0)); $r += 2

  $objective = Get-Prop $Model 'objective' ''
  if ($objective -ne '') {
    [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Objective') -StyleId 2)); $r++
    [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @($objective) -StyleId 0)); $r += 2
  }

  $sources = Get-Prop $Model 'sources' @()
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Sources','Type','Extraction Date','Sheet') -StyleId 2)); $r++
  foreach ($s in $sources) {
    [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @((Get-Prop $s 'url'),(Get-Prop $s 'type'),(Get-Prop $s 'extractionDate'),(Get-Prop $s 'sheet')) -StyleId 0)); $r++
  }
  $r++
  $assumptions = Get-Prop $Model 'assumptions' @()
  [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Assumptions & Rules') -StyleId 2)); $r++
  foreach ($a in $assumptions) {
    [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @([string]$a) -StyleId 0)); $r++
  }
  $r++
  $method = @(Get-Prop $Model 'method' @())
  if ($method.Count -gt 0) {
    [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Method') -StyleId 2)); $r++
    foreach ($m in $method) {
      [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @([string]$m) -StyleId 0)); $r++
    }
    $r++
  }
  $versions = @(Get-Prop $Model 'versions' @())
  if ($versions.Count -gt 0) {
    [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @('Version','Type','Updated Date','Updated by','Owners','Update Comments') -StyleId 2)); $r++
    foreach ($v in $versions) {
      [void]$coverSb.Append((New-XlsxRow -RowNum $r -Values @((Get-Prop $v 'version'),(Get-Prop $v 'type'),(Get-Prop $v 'updatedDate'),(Get-Prop $v 'updatedBy'),(Get-Prop $v 'owners'),(Get-Prop $v 'comments')) -StyleId 0)); $r++
    }
  }
  $coverXml = Get-XlsxWorksheetXml -SheetData $coverSb.ToString() -ColCount 6

  # ---- Sheet 2: Functional Flow Pattern (official columns incl. DCP breakdown) ----
  $fHeader = @('Functional flow name','Type of treatment','Source Service/App','Destination Service/App','Frequency','Data confidentiality (C1/C2/C3/C4)','DCP (Yes/No)','Party (Yes/No)','Party identification (Yes/No)','Banking information (Yes/No)','Sensitive personnal data (Yes/No)','Type of data with DCP')
  $fRows = @()
  foreach ($f in (Get-Prop $Model 'functionalFlows' @())) {
    $fRows += ,@(
      (Get-Prop $f 'name'), (Get-Prop $f 'treatment'), (Get-Prop $f 'source'),
      (Get-Prop $f 'destination'), (Get-Prop $f 'frequency'), (Get-Prop $f 'confidentiality'),
      (Get-Prop $f 'dcp'), (Get-Prop $f 'party'), (Get-Prop $f 'partyIdentification'),
      (Get-Prop $f 'bankingInformation'), (Get-Prop $f 'sensitiveData'), (Get-Prop $f 'dataType')
    )
  }
  $funcData = Get-XlsxSheetData -Header $fHeader -Rows $fRows
  $funcXml = Get-XlsxWorksheetXml -SheetData $funcData -ColCount $fHeader.Count

  # ---- Sheet 3: Technical Flow Pattern (official columns) ----
  $tHeader = @('Functional flow name','Technical flow name','Type of flow','Source Service/App','Hostname Source','Destination Service/App','Hostname Destination','Frequency','Data confidentiality (C1/C2/C3/C4)','DCP (Yes/No)','Port','Protocol','Token supplier if API','Exposition End Point','APIC Product')
  $tRows = @()
  foreach ($t in (Get-Prop $Model 'technicalFlows' @())) {
    $tRows += ,@(
      (Get-Prop $t 'functionalName'), (Get-Prop $t 'name'), (Get-Prop $t 'type'), (Get-Prop $t 'source'),
      (Get-Prop $t 'hostnameSource'), (Get-Prop $t 'destination'), (Get-Prop $t 'hostnameDestination'),
      (Get-Prop $t 'frequency'), (Get-Prop $t 'confidentiality'), (Get-Prop $t 'dcp'), (Get-Prop $t 'port'),
      (Get-Prop $t 'protocol'), (Get-Prop $t 'tokenSupplier'), (Get-Prop $t 'endpoint'),
      (Get-Prop $t 'apicProduct')
    )
  }
  $techData = Get-XlsxSheetData -Header $tHeader -Rows $tRows
  $techXml = Get-XlsxWorksheetXml -SheetData $techData -ColCount $tHeader.Count

  $sheetNames = @('Cover sheet', 'Functional Flow Pattern', 'Technical Flow Pattern')
  $sheetCount = $sheetNames.Count

  $parts = @{
    '[Content_Types].xml'          = (Get-XlsxContentTypesXml -SheetCount $sheetCount)
    '_rels/.rels'                  = (Get-XlsxRootRelsXml)
    'xl/workbook.xml'              = (Get-XlsxWorkbookXml -SheetNames $sheetNames)
    'xl/_rels/workbook.xml.rels'   = (Get-XlsxWorkbookRelsXml -SheetCount $sheetCount)
    'xl/worksheets/sheet1.xml'     = $coverXml
    'xl/worksheets/sheet2.xml'     = $funcXml
    'xl/worksheets/sheet3.xml'     = $techXml
    'xl/styles.xml'                = (Get-XlsxStylesXml)
    'docProps/core.xml'            = (Get-XlsxCoreXml -Title (Get-Prop $Model 'title' 'Data flow mapping') -Author (Get-Prop $Model 'author' '') -Date (Get-Prop $Model 'date' ''))
    'docProps/app.xml'             = (Get-XlsxAppXml)
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

Export-ModuleMember -Function New-FlowMappingXlsx, ConvertTo-XlsxText
