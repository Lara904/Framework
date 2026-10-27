<#
  DatDocx.psm1 - build a valid .docx (Word) Technical Architecture Document (DAT)
  from a structured JSON model, WITHOUT Python or Microsoft Office.

  The output mirrors the official Stellantis DAT template (derived from the reference
  example "BPF B2C CS DAT"): a cover page ("Technical Architecture File"), a Table of
  Contents, the front-matter tables (Distribution List, Approval of the version,
  Referenced documents, Document evolution), then the numbered body (1, 1.1, 1.1.1 ...).

  Why a module: a .docx is an OPC package (a ZIP of Open XML parts). This module
  writes the minimal set of valid parts (document.xml, styles.xml, numbering.xml,
  settings.xml, rels, content types) and zips them with ZipArchiveMode.Create (NEVER
  Update - Update corrupts OPC packages and triggers "repair on open").

  Public function:
    New-DatDocx -Model <hashtable|pscustomobject> -OutFile <path>

  Encoding: all parts are written as UTF-8 WITHOUT BOM. Text is XML-escaped. The DAT is
  written in English like the other deliverables; any non-ASCII characters are still
  preserved correctly as proper UTF-8 (Word handles them).
#>

Set-StrictMode -Version Latest

function ConvertTo-XmlText {
  param([string]$Text)
  if ($null -eq $Text) { return '' }
  $t = $Text -replace '&', '&amp;'
  $t = $t -replace '<', '&lt;'
  $t = $t -replace '>', '&gt;'
  $t = $t -replace '"', '&quot;'
  $t = $t -replace "'", '&apos;'
  return $t
}

function Get-DatProp {
  # Safe accessor for an optional property on a pscustomobject/hashtable.
  param($Object, [string]$Name)
  if ($null -eq $Object) { return $null }
  if ($Object -is [hashtable]) { if ($Object.ContainsKey($Name)) { return $Object[$Name] } else { return $null } }
  if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
  return $null
}

function New-DatRun {
  param([string]$Text, [switch]$Bold, [string]$Color = '')
  $rpr = ''
  $props = @()
  if ($Bold) { $props += '<w:b/>' }
  if ($Color -ne '') { $props += ('<w:color w:val="{0}"/>' -f $Color) }
  if ($props.Count -gt 0) { $rpr = '<w:rPr>' + ($props -join '') + '</w:rPr>' }
  return ('<w:r>{0}<w:t xml:space="preserve">{1}</w:t></w:r>' -f $rpr, (ConvertTo-XmlText $Text))
}

function New-DatParagraph {
  param([string]$Style = '', [string]$Text = '', [switch]$Bold)
  $ppr = ''
  if ($Style -ne '') { $ppr = ('<w:pPr><w:pStyle w:val="{0}"/></w:pPr>' -f $Style) }
  $run = if ($Text -ne '') { New-DatRun -Text $Text -Bold:$Bold } else { '' }
  return ('<w:p>{0}{1}</w:p>' -f $ppr, $run)
}

function New-DatBullet {
  param([string]$Text)
  # numId 1 = bullet list defined in numbering.xml
  return ('<w:p><w:pPr><w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr>{0}</w:p>' -f (New-DatRun -Text $Text))
}

function New-DatPageBreak {
  return '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
}

function New-DatTable {
  # Usable page width for this template (A4, pgMar left=1134 right=1134 on pgSz w=11906)
  # is 11906-1134-1134 = 9638 twips. <w:tblGrid> is a MANDATORY child of <w:tbl> per the
  # OOXML schema (ECMA-376 17.4.49): without it the part is invalid XML. python-docx and
  # other strict readers raise InvalidXmlError on it, and Word silently "repairs" the
  # file on open (risking a recovery prompt for the end user) rather than erroring, which
  # is why this went unnoticed. We also set tblLayout=fixed with the grid widths so long
  # cell text (this document's tables routinely carry 100-500+ character cells) actually
  # wraps inside a sane column width instead of the autofit engine collapsing columns to
  # fit their widest single word.
  param([string[]]$Header, [object[]]$Rows, [int[]]$ColWidths)
  $sb = New-Object System.Text.StringBuilder
  $colCount = if ($Header -and $Header.Count -gt 0) { $Header.Count } elseif ($Rows -and $Rows.Count -gt 0) { @($Rows[0]).Count } else { 1 }
  $usableWidth = 9638
  if (-not $ColWidths -or $ColWidths.Count -ne $colCount) {
    $base = [int]([math]::Floor($usableWidth / $colCount))
    $ColWidths = @(for ($i = 0; $i -lt $colCount; $i++) { $base })
    $ColWidths[$ColWidths.Count - 1] += $usableWidth - ($base * $colCount)
  }
  [void]$sb.Append('<w:tbl><w:tblPr><w:tblStyle w:val="DatTable"/><w:tblW w:w="' + $usableWidth + '" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:left w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:right w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="999999"/></w:tblBorders></w:tblPr>')
  [void]$sb.Append('<w:tblGrid>')
  foreach ($w in $ColWidths) { [void]$sb.Append('<w:gridCol w:w="' + $w + '"/>') }
  [void]$sb.Append('</w:tblGrid>')
  # header row (shaded, bold)
  if ($Header -and $Header.Count -gt 0) {
    [void]$sb.Append('<w:tr>')
    for ($i = 0; $i -lt $Header.Count; $i++) {
      $cell = '<w:tc><w:tcPr><w:tcW w:w="' + $ColWidths[$i] + '" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="DAE8FC"/></w:tcPr><w:p><w:pPr><w:pStyle w:val="TableText"/></w:pPr>' + (New-DatRun -Text ([string]$Header[$i]) -Bold) + '</w:p></w:tc>'
      [void]$sb.Append($cell)
    }
    [void]$sb.Append('</w:tr>')
  }
  foreach ($row in $Rows) {
    [void]$sb.Append('<w:tr>')
    $cells = @($row)
    for ($i = 0; $i -lt $cells.Count; $i++) {
      $w = if ($i -lt $ColWidths.Count) { $ColWidths[$i] } else { $ColWidths[$ColWidths.Count - 1] }
      $cell = '<w:tc><w:tcPr><w:tcW w:w="' + $w + '" w:type="dxa"/></w:tcPr><w:p><w:pPr><w:pStyle w:val="TableText"/></w:pPr>' + (New-DatRun -Text ([string]$cells[$i])) + '</w:p></w:tc>'
      [void]$sb.Append($cell)
    }
    [void]$sb.Append('</w:tr>')
  }
  [void]$sb.Append('</w:tbl>')
  # a table must be followed by a paragraph in OOXML
  [void]$sb.Append('<w:p/>')
  return $sb.ToString()
}

function New-DatTocField {
  # A real Word TOC field (levels 1-4). With settings.xml updateFields=true, Word
  # rebuilds it (with page numbers) when the document is opened.
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<w:p><w:pPr><w:pStyle w:val="FrontTitle"/></w:pPr><w:r><w:t>Table of Contents</w:t></w:r></w:p>')
  [void]$sb.Append('<w:p><w:pPr><w:rPr><w:noProof/></w:rPr></w:pPr>')
  [void]$sb.Append('<w:r><w:fldChar w:fldCharType="begin"/></w:r>')
  [void]$sb.Append('<w:r><w:instrText xml:space="preserve"> TOC \o "1-4" \h \z \u </w:instrText></w:r>')
  [void]$sb.Append('<w:r><w:fldChar w:fldCharType="separate"/></w:r>')
  [void]$sb.Append('<w:r><w:t>Right-click and choose "Update Field" to build the table of contents.</w:t></w:r>')
  [void]$sb.Append('<w:r><w:fldChar w:fldCharType="end"/></w:r>')
  [void]$sb.Append('</w:p>')
  return $sb.ToString()
}

function New-DatFrontMatter {
  param($Model)
  $sb = New-Object System.Text.StringBuilder

  # Distribution List
  $dist = Get-DatProp $Model 'distributionList'
  if ($dist) {
    [void]$sb.Append((New-DatParagraph -Style 'FrontTitle' -Text 'Distribution List'))
    $rows = @()
    foreach ($d in $dist) { $rows += ,@((Get-DatProp $d 'recipient'), (Get-DatProp $d 'entity')) }
    [void]$sb.Append((New-DatTable -Header @('Recipient', 'Entity') -Rows $rows))
  }

  # Approval of the version
  $appr = Get-DatProp $Model 'approval'
  if ($appr) {
    [void]$sb.Append((New-DatParagraph -Style 'FrontTitle' -Text 'Approval of the version'))
    $rows = @()
    foreach ($a in $appr) { $rows += ,@((Get-DatProp $a 'role'), (Get-DatProp $a 'function'), (Get-DatProp $a 'name'), (Get-DatProp $a 'entity')) }
    [void]$sb.Append((New-DatTable -Header @('Role', 'Function', 'Name', 'Entity') -Rows $rows))
  }

  # Referenced documents
  $refs = Get-DatProp $Model 'referencedDocuments'
  if ($refs) {
    [void]$sb.Append((New-DatParagraph -Style 'FrontTitle' -Text 'Referenced documents'))
    $rows = @()
    foreach ($r in $refs) { $rows += ,@((Get-DatProp $r 'n'), (Get-DatProp $r 'title'), (Get-DatProp $r 'reference')) }
    [void]$sb.Append((New-DatTable -Header @('No', 'Title', 'Reference') -Rows $rows))
  }

  # Document evolution (preferred), else fall back to legacy "revisions"
  $evo = Get-DatProp $Model 'documentEvolution'
  if ($evo) {
    [void]$sb.Append((New-DatParagraph -Style 'FrontTitle' -Text 'Document evolution'))
    $rows = @()
    foreach ($e in $evo) { $rows += ,@((Get-DatProp $e 'date'), (Get-DatProp $e 'version'), (Get-DatProp $e 'chapter'), (Get-DatProp $e 'changes'), (Get-DatProp $e 'editors')) }
    [void]$sb.Append((New-DatTable -Header @('Date', 'Version', 'Chapter', 'Changes', 'Editors') -Rows $rows))
  }
  else {
    $rev = Get-DatProp $Model 'revisions'
    if ($rev) {
      [void]$sb.Append((New-DatParagraph -Style 'FrontTitle' -Text 'Document evolution'))
      $rows = @()
      foreach ($r in $rev) { $rows += ,@((Get-DatProp $r 'date'), (Get-DatProp $r 'revision'), 'All', (Get-DatProp $r 'object'), (Get-DatProp $r 'author')) }
      [void]$sb.Append((New-DatTable -Header @('Date', 'Version', 'Chapter', 'Changes', 'Editors') -Rows $rows))
    }
  }

  return $sb.ToString()
}

function ConvertFrom-DatBody {
  param([object[]]$Body)
  $sb = New-Object System.Text.StringBuilder
  foreach ($node in $Body) {
    switch ($node.type) {
      'h1'      { [void]$sb.Append((New-DatParagraph -Style 'Heading1' -Text $node.text)) }
      'h2'      { [void]$sb.Append((New-DatParagraph -Style 'Heading2' -Text $node.text)) }
      'h3'      { [void]$sb.Append((New-DatParagraph -Style 'Heading3' -Text $node.text)) }
      'h4'      { [void]$sb.Append((New-DatParagraph -Style 'Heading4' -Text $node.text)) }
      'p'       { [void]$sb.Append((New-DatParagraph -Text $node.text)) }
      'bullets' { foreach ($it in $node.items) { [void]$sb.Append((New-DatBullet -Text ([string]$it))) } }
      'table'   { [void]$sb.Append((New-DatTable -Header $node.header -Rows $node.rows)) }
      'pagebreak' { [void]$sb.Append((New-DatPageBreak)) }
      default   { if ($node.PSObject.Properties.Name -contains 'text') { [void]$sb.Append((New-DatParagraph -Text $node.text)) } }
    }
  }
  return $sb.ToString()
}

function Get-DatStylesXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:rPrDefault></w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:pPr><w:spacing w:before="2400" w:after="120"/><w:jc w:val="center"/></w:pPr><w:rPr><w:b/><w:color w:val="1F3864"/><w:sz w:val="72"/><w:szCs w:val="72"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:pPr><w:spacing w:after="120"/><w:jc w:val="center"/></w:pPr><w:rPr><w:b/><w:color w:val="0070AD"/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="CoverMeta"><w:name w:val="Cover Meta"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="120" w:after="120"/><w:jc w:val="center"/></w:pPr><w:rPr><w:color w:val="595959"/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="FrontTitle"><w:name w:val="Front Title"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="360" w:after="160"/></w:pPr><w:rPr><w:b/><w:color w:val="1F3864"/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="2"/></w:numPr><w:spacing w:before="360" w:after="120"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:color w:val="1F3864"/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:numPr><w:ilvl w:val="1"/><w:numId w:val="2"/></w:numPr><w:spacing w:before="280" w:after="120"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:numPr><w:ilvl w:val="2"/><w:numId w:val="2"/></w:numPr><w:spacing w:before="240" w:after="120"/><w:outlineLvl w:val="2"/></w:pPr><w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading4"><w:name w:val="heading 4"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:numPr><w:ilvl w:val="3"/><w:numId w:val="2"/></w:numPr><w:spacing w:before="200" w:after="120"/><w:outlineLvl w:val="3"/></w:pPr><w:rPr><w:b/><w:i/><w:color w:val="404040"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="ListParagraph"><w:name w:val="List Paragraph"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="60"/><w:ind w:left="720"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="TableText"><w:name w:val="Table Text"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="0"/></w:pPr></w:style>
  <w:style w:type="table" w:styleId="DatTable"><w:name w:val="DAT Table"/><w:tblPr><w:tblCellMar><w:top w:w="40" w:type="dxa"/><w:left w:w="80" w:type="dxa"/><w:bottom w:w="40" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>
</w:styles>
'@
}

function Get-DatNumberingXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0"><w:multiLevelType w:val="hybridMultilevel"/>
    <w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="&#8226;"/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr><w:rPr><w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/></w:rPr></w:lvl>
  </w:abstractNum>
  <w:abstractNum w:abstractNumId="1"><w:multiLevelType w:val="multilevel"/>
    <w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="0" w:hanging="0"/></w:pPr></w:lvl>
    <w:lvl w:ilvl="1"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1.%2."/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="0" w:hanging="0"/></w:pPr></w:lvl>
    <w:lvl w:ilvl="2"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1.%2.%3."/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="0" w:hanging="0"/></w:pPr></w:lvl>
    <w:lvl w:ilvl="3"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1.%2.%3.%4."/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="0" w:hanging="0"/></w:pPr></w:lvl>
  </w:abstractNum>
  <w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
  <w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>
</w:numbering>
'@
}

function Get-DatSettingsXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:updateFields w:val="true"/>
</w:settings>
'@
}

function Get-DatContentTypesXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
'@
}

function Get-DatRootRelsXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'@
}

function Get-DatDocumentRelsXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
</Relationships>
'@
}

function Get-DatCoreXml {
  param([string]$Title, [string]$Author, [string]$Date)
  $t = ConvertTo-XmlText $Title
  $a = ConvertTo-XmlText $Author
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

function Get-DatAppXml {
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>Kiro technical-architecture skill</Application>
</Properties>
'@
}

function Get-DatDocumentXml {
  param($Model)

  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
  [void]$sb.Append('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>')

  # ---- Cover page ----
  [void]$sb.Append((New-DatParagraph -Style 'Title' -Text ($Model.title)))
  $subtitle = Get-DatProp $Model 'subtitle'
  if ($subtitle) { [void]$sb.Append((New-DatParagraph -Style 'Subtitle' -Text $subtitle)) }
  $version = Get-DatProp $Model 'version'
  if ($version) { [void]$sb.Append((New-DatParagraph -Style 'CoverMeta' -Text ("Version {0}" -f $version))) }
  $meta = ("Author: {0}    Date: {1}" -f $Model.author, $Model.date)
  [void]$sb.Append((New-DatParagraph -Style 'CoverMeta' -Text $meta))
  [void]$sb.Append((New-DatPageBreak))

  # ---- Table of Contents ----
  [void]$sb.Append((New-DatTocField))
  [void]$sb.Append((New-DatPageBreak))

  # ---- Front matter (Distribution List, Approval, Referenced documents, Document evolution) ----
  [void]$sb.Append((New-DatFrontMatter -Model $Model))
  [void]$sb.Append((New-DatPageBreak))

  # ---- Body (numbered chapters) ----
  [void]$sb.Append((ConvertFrom-DatBody -Body $Model.body))

  # Section properties (A4 portrait, margins)
  [void]$sb.Append('<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>')
  [void]$sb.Append('</w:body></w:document>')
  return $sb.ToString()
}

function New-DatDocx {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)] $Model,
    [Parameter(Mandatory=$true)] [string]$OutFile
  )

  # Normalize model if passed as hashtable / JSON string
  if ($Model -is [string]) { $Model = $Model | ConvertFrom-Json }
  if ($Model -is [hashtable]) { $Model = [pscustomobject]$Model }

  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $utf8 = New-Object System.Text.UTF8Encoding($false)  # no BOM

  $parts = @{
    '[Content_Types].xml'      = (Get-DatContentTypesXml)
    '_rels/.rels'              = (Get-DatRootRelsXml)
    'word/document.xml'        = (Get-DatDocumentXml -Model $Model)
    'word/styles.xml'          = (Get-DatStylesXml)
    'word/numbering.xml'       = (Get-DatNumberingXml)
    'word/settings.xml'        = (Get-DatSettingsXml)
    'word/_rels/document.xml.rels' = (Get-DatDocumentRelsXml)
    'docProps/core.xml'        = (Get-DatCoreXml -Title $Model.title -Author $Model.author -Date $Model.date)
    'docProps/app.xml'         = (Get-DatAppXml)
  }

  # Ordered list so [Content_Types].xml is first
  $order = @('[Content_Types].xml','_rels/.rels','word/_rels/document.xml.rels','word/document.xml','word/styles.xml','word/numbering.xml','word/settings.xml','docProps/core.xml','docProps/app.xml')

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

Export-ModuleMember -Function New-DatDocx, ConvertTo-XmlText
