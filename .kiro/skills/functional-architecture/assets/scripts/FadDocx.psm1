<#
  FadDocx.psm1 - build a valid .docx (Word) Functional Architecture Dossier (FAD)
  from a structured JSON model, WITHOUT Python or Microsoft Office.

  APPROACH: CLONE THE OFFICIAL TEMPLATE, INJECT THE BODY.
  Rather than building a .docx from scratch with home-made styles, this module starts
  from the bundled official Stellantis template
  (assets/templates/Functional_Architecture_Dossier_template.docx - DP-MD76-EN) and
  keeps ALL of its layout parts verbatim: styles (Titre1..Titre4 in Times New Roman
  with automatic numbering, Encadr, Texte, Paragraphedeliste, Grilledutableau), the
  theme, the headers/footers (including the Stellantis logo images), numbering, fonts,
  page setup (sectPr with header/footer references). Only word/document.xml's <w:body>
  is regenerated from the JSON model, using the template's REAL style IDs, so the output
  is visually faithful to the template.

  Why a module: a .docx is an OPC package (a ZIP of Open XML parts). This module copies
  every template part into a brand-new archive (ZipArchiveMode.Create - NEVER Update,
  which corrupts OPC packages) and swaps document.xml.

  Public function:
    New-FadDocx -Model <hashtable|pscustomobject|json> -OutFile <path> [-TemplatePath <path>]

  Encoding: regenerated parts are written as UTF-8 WITHOUT BOM. Text is XML-escaped.
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

function Get-FadProp {
  param($Object, [string]$Name)
  if ($null -eq $Object) { return $null }
  if ($Object -is [hashtable]) { if ($Object.ContainsKey($Name)) { return $Object[$Name] } else { return $null } }
  if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
  return $null
}

# ---- Body building blocks (use the TEMPLATE's real style IDs) ------------------------

function New-FadRun {
  param([string]$Text, [switch]$Bold, [string]$Sz = '')
  $props = @()
  if ($Bold) { $props += '<w:b/><w:bCs/>' }
  if ($Sz -ne '') { $props += ('<w:sz w:val="{0}"/><w:szCs w:val="{0}"/>' -f $Sz) }
  $rpr = if ($props.Count -gt 0) { '<w:rPr>' + ($props -join '') + '</w:rPr>' } else { '' }
  return ('<w:r>{0}<w:t xml:space="preserve">{1}</w:t></w:r>' -f $rpr, (ConvertTo-XmlText $Text))
}

function New-FadStyledPara {
  # Paragraph bound to a template paragraph style (e.g. Titre1, Texte, Encadr).
  # The template's Normal/Texte styles carry w:after=0 (the template relies on manually
  # inserted blank paragraphs for spacing). To keep proper vertical rhythm without those
  # blank paragraphs, we add explicit spacing (before/after) as direct paragraph formatting.
  # Child order in w:pPr must be schema-valid: pStyle, spacing, jc.
  param([string]$Style, [string]$Text = '', [switch]$Bold, [string]$Sz = '', [string]$Jc = '',
        [string]$After = '', [string]$Before = '')
  $pprInner = ''
  if ($Style -ne '') { $pprInner += ('<w:pStyle w:val="{0}"/>' -f $Style) }
  if ($After -ne '' -or $Before -ne '') {
    $sp = '<w:spacing'
    if ($Before -ne '') { $sp += (' w:before="{0}"' -f $Before) }
    if ($After -ne '')  { $sp += (' w:after="{0}"' -f $After) }
    $sp += '/>'
    $pprInner += $sp
  }
  if ($Jc -ne '')    { $pprInner += ('<w:jc w:val="{0}"/>' -f $Jc) }
  $ppr = if ($pprInner -ne '') { '<w:pPr>' + $pprInner + '</w:pPr>' } else { '' }
  $run = if ($Text -ne '') { New-FadRun -Text $Text -Bold:$Bold -Sz $Sz } else { '' }
  return ('<w:p>{0}{1}</w:p>' -f $ppr, $run)
}

function New-FadBullet {
  param([string]$Text)
  # Rendered as a List Paragraph with a leading "- " (ASCII-safe; avoids guessing a
  # numbering definition id from the template's numbering.xml). Small after-spacing so
  # consecutive bullets are not glued together.
  return ('<w:p><w:pPr><w:pStyle w:val="Paragraphedeliste"/><w:spacing w:after="60"/></w:pPr>{0}</w:p>' -f (New-FadRun -Text ("- " + $Text)))
}

function New-FadPageBreak {
  return '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
}

function New-FadTable {
  # Uses the template's "Grilledutableau" (Table Grid) style + explicit borders; header
  # row shaded and bold.
  #
  # Usable page width for this template (A4, pgMar left=851 right=851 on pgSz w=11905)
  # is 11905-851-851 = 10203 twips. <w:tblGrid> is a MANDATORY child of <w:tbl> per the
  # OOXML schema (ECMA-376 17.4.49): without it the part is invalid XML. python-docx and
  # other strict readers raise InvalidXmlError on it, and Word silently "repairs" the
  # file on open (risking a recovery prompt for the end user) rather than erroring, which
  # is why this went unnoticed. We also set tblLayout=fixed with the grid widths so long
  # cell text actually wraps inside a sane column width instead of the autofit engine
  # collapsing columns to fit their widest single word.
  param([string[]]$Header, [object[]]$Rows, [int[]]$ColWidths)
  $sb = New-Object System.Text.StringBuilder
  $colCount = if ($Header -and $Header.Count -gt 0) { $Header.Count } elseif ($Rows -and $Rows.Count -gt 0) { @($Rows[0]).Count } else { 1 }
  $usableWidth = 10203
  if (-not $ColWidths -or $ColWidths.Count -ne $colCount) {
    $base = [int]([math]::Floor($usableWidth / $colCount))
    $ColWidths = @(for ($i = 0; $i -lt $colCount; $i++) { $base })
    $ColWidths[$ColWidths.Count - 1] += $usableWidth - ($base * $colCount)
  }
  [void]$sb.Append('<w:tbl><w:tblPr><w:tblStyle w:val="Grilledutableau"/><w:tblW w:w="' + $usableWidth + '" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:left w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:right w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="999999"/></w:tblBorders></w:tblPr>')
  [void]$sb.Append('<w:tblGrid>')
  foreach ($w in $ColWidths) { [void]$sb.Append('<w:gridCol w:w="' + $w + '"/>') }
  [void]$sb.Append('</w:tblGrid>')
  if ($Header -and $Header.Count -gt 0) {
    [void]$sb.Append('<w:tr>')
    for ($i = 0; $i -lt $Header.Count; $i++) {
      [void]$sb.Append('<w:tc><w:tcPr><w:tcW w:w="' + $ColWidths[$i] + '" w:type="dxa"/><w:shd w:val="clear" w:color="auto" w:fill="DAE8FC"/></w:tcPr><w:p>' + (New-FadRun -Text ([string]$Header[$i]) -Bold) + '</w:p></w:tc>')
    }
    [void]$sb.Append('</w:tr>')
  }
  foreach ($row in $Rows) {
    [void]$sb.Append('<w:tr>')
    $cells = @($row)
    for ($i = 0; $i -lt $cells.Count; $i++) {
      $w = if ($i -lt $ColWidths.Count) { $ColWidths[$i] } else { $ColWidths[$ColWidths.Count - 1] }
      [void]$sb.Append('<w:tc><w:tcPr><w:tcW w:w="' + $w + '" w:type="dxa"/></w:tcPr><w:p>' + (New-FadRun -Text ([string]$cells[$i])) + '</w:p></w:tc>')
    }
    [void]$sb.Append('</w:tr>')
  }
  [void]$sb.Append('</w:tbl><w:p/>')
  return $sb.ToString()
}

function New-FadTocField {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<w:p><w:pPr><w:pStyle w:val="En-ttedetabledesmatires"/></w:pPr><w:r><w:t>Table of Contents</w:t></w:r></w:p>')
  [void]$sb.Append('<w:p><w:pPr><w:rPr><w:noProof/></w:rPr></w:pPr>')
  [void]$sb.Append('<w:r><w:fldChar w:fldCharType="begin"/></w:r>')
  [void]$sb.Append('<w:r><w:instrText xml:space="preserve"> TOC \o "1-4" \h \z \u </w:instrText></w:r>')
  [void]$sb.Append('<w:r><w:fldChar w:fldCharType="separate"/></w:r>')
  [void]$sb.Append('<w:r><w:t>Right-click and choose "Update Field" to build the table of contents.</w:t></w:r>')
  [void]$sb.Append('<w:r><w:fldChar w:fldCharType="end"/></w:r>')
  [void]$sb.Append('</w:p>')
  return $sb.ToString()
}

function New-FadSynthesis {
  param($Model)
  $sb = New-Object System.Text.StringBuilder

  $obj = Get-FadProp $Model 'objectOfDocument'
  [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text 'Object of the document / Synthesis' -Bold -Sz '28' -Before '240' -After '80'))
  [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text ($(if ($obj) { [string]$obj } else { 'This document presents the functional architecture to answer the needs of the transformation project.' })) -After '160'))

  $aud = Get-FadProp $Model 'audience'
  [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text 'Audience addressed' -Bold -Sz '28' -Before '240' -After '80'))
  [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text ($(if ($aud) { [string]$aud } else { 'TBC' })) -After '160'))

  $links = Get-FadProp $Model 'relatedDocuments'
  [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text 'Links toward related documentation' -Bold -Sz '28' -Before '240' -After '80'))
  if ($links) {
    $rows = @()
    foreach ($l in $links) { $rows += ,@((Get-FadProp $l 'title'), (Get-FadProp $l 'reference')) }
    [void]$sb.Append((New-FadTable -Header @('Document', 'Reference') -Rows $rows))
  }
  else {
    [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text 'Validated statement of needs: TBC' -After '160'))
  }

  $rev = Get-FadProp $Model 'revisions'
  [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text 'Revisions index' -Bold -Sz '28' -Before '240' -After '80'))
  if ($rev) {
    $rows = @()
    foreach ($r in $rev) { $rows += ,@((Get-FadProp $r 'version'), (Get-FadProp $r 'date'), (Get-FadProp $r 'chapters'), (Get-FadProp $r 'motives'), (Get-FadProp $r 'authors')) }
    [void]$sb.Append((New-FadTable -Header @('Version', 'Date of revision', 'Revised chapters', 'Revision motives', 'Authors') -Rows $rows))
  }
  else {
    [void]$sb.Append((New-FadTable -Header @('Version', 'Date of revision', 'Revised chapters', 'Revision motives', 'Authors') -Rows @(,@('1.0', "$(Get-FadProp $Model 'date')", 'All', 'Initial creation', "$(Get-FadProp $Model 'author')"))))
  }

  return $sb.ToString()
}

function ConvertFrom-FadBody {
  param([object[]]$Body)
  $sb = New-Object System.Text.StringBuilder
  foreach ($node in $Body) {
    switch ($node.type) {
      'h1'      { [void]$sb.Append((New-FadStyledPara -Style 'Titre1' -Text $node.text)) }
      'h2'      { [void]$sb.Append((New-FadStyledPara -Style 'Titre2' -Text $node.text)) }
      'h3'      { [void]$sb.Append((New-FadStyledPara -Style 'Titre3' -Text $node.text)) }
      'h4'      { [void]$sb.Append((New-FadStyledPara -Style 'Titre4' -Text $node.text)) }
      'p'       { [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text $node.text -After '160')) }
      'bullets' { foreach ($it in $node.items) { [void]$sb.Append((New-FadBullet -Text ([string]$it))) } }
      'table'   { [void]$sb.Append((New-FadTable -Header $node.header -Rows $node.rows)) }
      'pagebreak' { [void]$sb.Append((New-FadPageBreak)) }
      default   { if ($node.PSObject.Properties.Name -contains 'text') { [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text $node.text -After '160')) } }
    }
  }
  return $sb.ToString()
}

function New-FadBodyXml {
  param($Model, [string]$SectPr)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<w:body>')

  # ---- Cover page (framed title in the template's Encadr style) ----
  [void]$sb.Append((New-FadStyledPara -Style 'Texte'))
  [void]$sb.Append((New-FadStyledPara -Style 'Encadr' -Text ($Model.title)))
  $subtitle = Get-FadProp $Model 'subtitle'
  if ($subtitle) { [void]$sb.Append((New-FadStyledPara -Style 'Encadr' -Text $subtitle)) }
  $version = Get-FadProp $Model 'version'
  if ($version) { [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text ("Version {0}" -f $version) -Jc 'center')) }
  [void]$sb.Append((New-FadStyledPara -Style 'Texte' -Text ("Author: {0}    Date: {1}" -f $Model.author, $Model.date) -Jc 'center'))
  [void]$sb.Append((New-FadPageBreak))

  # ---- Synthesis / front matter (before the TOC, as in the template) ----
  [void]$sb.Append((New-FadSynthesis -Model $Model))
  [void]$sb.Append((New-FadPageBreak))

  # ---- Table of Contents ----
  [void]$sb.Append((New-FadTocField))
  [void]$sb.Append((New-FadPageBreak))

  # ---- Body (numbered chapters, template heading styles) ----
  [void]$sb.Append((ConvertFrom-FadBody -Body $Model.body))

  # ---- Section properties copied verbatim from the template (headers/footers/page) ----
  [void]$sb.Append($SectPr)
  [void]$sb.Append('</w:body>')
  return $sb.ToString()
}

function New-FadDocx {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)] $Model,
    [Parameter(Mandatory=$true)] [string]$OutFile,
    [string]$TemplatePath
  )

  if ($Model -is [string]) { $Model = $Model | ConvertFrom-Json }
  if ($Model -is [hashtable]) { $Model = [pscustomobject]$Model }

  if (-not $TemplatePath -or $TemplatePath -eq '') {
    $TemplatePath = Join-Path $PSScriptRoot '..\templates\Functional_Architecture_Dossier_template.docx'
  }
  if (-not (Test-Path $TemplatePath)) { throw "FAD template not found: $TemplatePath" }
  $TemplatePath = (Resolve-Path $TemplatePath).Path

  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $utf8 = New-Object System.Text.UTF8Encoding($false)  # no BOM

  # --- Read the template's document.xml to reuse its exact <w:document> tag + sectPr ---
  $tplZip = [System.IO.Compression.ZipFile]::OpenRead($TemplatePath)
  try {
    $docEntry = $tplZip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
    if (-not $docEntry) { throw "Template has no word/document.xml" }
    $sr = New-Object System.IO.StreamReader($docEntry.Open())
    $tplDoc = $sr.ReadToEnd(); $sr.Close()

    $openTag = ([regex]::Match($tplDoc, '<w:document\b[^>]*>')).Value
    if ($openTag -eq '') { $openTag = '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' }
    $sectMatches = [regex]::Matches($tplDoc, '<w:sectPr\b[\s\S]*?</w:sectPr>')
    $sectPr = if ($sectMatches.Count -gt 0) { $sectMatches[$sectMatches.Count - 1].Value } else { '<w:sectPr><w:pgSz w:w="11905" w:h="16837"/><w:pgMar w:top="1077" w:right="851" w:bottom="1077" w:left="851" w:header="567" w:footer="454" w:gutter="0"/></w:sectPr>' }

    $bodyXml = New-FadBodyXml -Model $Model -SectPr $sectPr
    $newDoc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + $openTag + $bodyXml + '</w:document>'

    # --- Write the output package: copy every template part, swap document.xml ---
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
    $fs = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create)
    try {
      $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
      try {
        foreach ($entry in $tplZip.Entries) {
          $name = $entry.FullName
          if ($name -eq 'word/document.xml') { continue }
          if ($name.StartsWith('[trash]/')) { continue }   # stray non-OOXML parts

          $newEntry = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
          $outS = $newEntry.Open()
          try {
            if ($name -eq 'word/settings.xml') {
              # Force Word to offer to rebuild the TOC on first open.
              $s = New-Object System.IO.StreamReader($entry.Open()); $txt = $s.ReadToEnd(); $s.Close()
              if ($txt -notmatch '<w:updateFields') {
                $txt = [regex]::Replace($txt, '(<w:settings\b[^>]*>)', '$1<w:updateFields w:val="true"/>', 1)
              }
              $bytes = $utf8.GetBytes($txt)
              $outS.Write($bytes, 0, $bytes.Length)
            }
            else {
              $inS = $entry.Open()
              try {
                $ms = New-Object System.IO.MemoryStream
                $inS.CopyTo($ms)
                $bytes = $ms.ToArray()
                $outS.Write($bytes, 0, $bytes.Length)
              } finally { $inS.Close() }
            }
          } finally { $outS.Close() }
        }

        # new document.xml
        $de = $zip.CreateEntry('word/document.xml', [System.IO.Compression.CompressionLevel]::Optimal)
        $ds = $de.Open()
        try { $b = $utf8.GetBytes($newDoc); $ds.Write($b, 0, $b.Length) } finally { $ds.Close() }
      } finally { $zip.Dispose() }
    } finally { $fs.Dispose() }
  } finally { $tplZip.Dispose() }

  return (Resolve-Path $OutFile).Path
}

Export-ModuleMember -Function New-FadDocx, ConvertTo-XmlText
