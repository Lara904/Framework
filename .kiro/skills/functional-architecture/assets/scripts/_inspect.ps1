$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$src = Join-Path $PSScriptRoot "..\templates\Functional_Architecture_Dossier_template.docx"
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $src).Path)
try {
  $e = $zip.Entries | Where-Object { $_.FullName -eq 'word/styles.xml' }
  $sr = New-Object System.IO.StreamReader($e.Open()); $x = [xml]$sr.ReadToEnd(); $sr.Close()
  $nsm = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
  $nsm.AddNamespace('w','http://schemas.openxmlformats.org/wordprocessingml/2006/main')
  Write-Output "==== STYLES (styleId | type | name) ===="
  foreach ($st in $x.SelectNodes('//w:style',$nsm)) {
    $id = $st.GetAttribute('styleId','http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    $type = $st.GetAttribute('type','http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    $nameNode = $st.SelectSingleNode('w:name',$nsm)
    $name = if ($nameNode) { $nameNode.GetAttribute('val','http://schemas.openxmlformats.org/wordprocessingml/2006/main') } else { '' }
    Write-Output ("{0} | {1} | {2}" -f $id, $type, $name)
  }
  Write-Output "==== document.xml.rels ===="
  $e = $zip.Entries | Where-Object { $_.FullName -eq 'word/_rels/document.xml.rels' }
  $sr = New-Object System.IO.StreamReader($e.Open()); Write-Output $sr.ReadToEnd(); $sr.Close()
  $e = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
  $sr = New-Object System.IO.StreamReader($e.Open()); $doc = $sr.ReadToEnd(); $sr.Close()
  Write-Output ("==== DOC LENGTH ==== " + $doc.Length)
  Write-Output "==== sectPr ===="
  foreach ($m in [regex]::Matches($doc, '<w:sectPr[\s\S]*?</w:sectPr>')) { Write-Output $m.Value }
  Write-Output "==== parts ===="
  foreach ($en in $zip.Entries) { if ($en.FullName -match 'header|footer|media|theme|numbering|settings|fontTable') { Write-Output $en.FullName } }
}
finally { $zip.Dispose() }
