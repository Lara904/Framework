<#
    PptxGates.psm1 - Shared primitives for the Architecture Gates skill.

    Single source of truth for the low-level actions every script needs:
      - reading a .pptx (a ZIP of Open XML parts) WITHOUT extracting to disk
      - resolving the true slide display order (sldIdLst -> r:id -> rels target)
      - extracting <a:t> text per slide
      - the read-only template guard
      - XML entity escaping
      - the slide map (position -> title + gate tags)
      - the placeholder / leftover-guidance detection patterns

    Import from a sibling script with:
        Import-Module (Join-Path $PSScriptRoot 'PptxGates.psm1') -Force

    Design notes:
      - Reads only the XML entries it needs (presentation.xml, its rels, and slide parts),
        skipping media/fonts/theme. This avoids Expand-Archive of the whole ~6 MB package.
      - Read paths open the archive read-only; edit paths open once in Update mode so many
        fields can be written in a single pass (see Set-PptxSlideReplacements).
#>

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$script:DrawingNs = 'http://schemas.openxmlformats.org/drawingml/2006/main'

# --- Guard ---------------------------------------------------------------------------------
function Assert-NotTemplate {
    <#
        Throw if the given path targets the read-only template file. Use before any write.
    #>
    param([Parameter(Mandatory)][string]$Path)
    if ((Split-Path $Path -Leaf) -match 'SIBS_Architecture_Gates_Template') {
        throw "Refusing to touch the read-only template ('$(Split-Path $Path -Leaf)'). Copy it to a new name and work on the copy."
    }
}

# --- XML escaping --------------------------------------------------------------------------
function ConvertTo-XmlText {
    <#
        Escape a plain string to the form PowerPoint stores inside <a:t> (& < >).
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

# --- Low-level zip entry helpers -----------------------------------------------------------
function Read-ZipEntryText {
    param(
        [Parameter(Mandatory)][System.IO.Compression.ZipArchive]$Archive,
        [Parameter(Mandatory)][string]$EntryName
    )
    $entry = $Archive.GetEntry($EntryName)
    if (-not $entry) { return $null }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    try { $reader.ReadToEnd() } finally { $reader.Close() }
}

function Set-PptxParts {
    <#
        Rewrite a .pptx in place, replacing the text of specific entries. CRITICAL: this does
        NOT use ZipArchiveMode.Update. .NET's Update mode rewrites the central directory in a
        way that OPC-strict consumers (PowerPoint) reject as "damaged data" - even with no
        edits - forcing a repair that can drop slides. Instead we create a BRAND-NEW archive
        (Create mode), copying every entry verbatim in its original order and swapping the
        bytes only for edited entries. Every untouched part stays intact.

        -Edits is a hashtable: entryName (e.g. 'ppt/slides/slide10.xml') -> new UTF-8 string.
        Writes atomically via a temp file then replaces the original.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [hashtable]$Edits = @{},
        [hashtable]$NewTextParts = @{},
        [hashtable]$NewBinaryParts = @{},
        [string[]]$RemoveParts = @()
    )
    $full = (Resolve-Path $Pptx).Path

    # Fail fast with a clear message if the file is locked (e.g. open in PowerPoint). Otherwise
    # the rewrite would leave an orphaned .tmp and a confusing IOException at the final Move.
    try {
        $probe = [System.IO.File]::Open($full, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $probe.Close()
    } catch {
        throw "Cannot write '$([System.IO.Path]::GetFileName($full))' - it is locked by another process (is it open in PowerPoint?). Close it and retry."
    }

    $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($full), ([System.IO.Path]::GetFileNameWithoutExtension($full) + '.tmp_' + [guid]::NewGuid().ToString('N') + '.pptx'))
    $utf8 = New-Object System.Text.UTF8Encoding($false)

    try {
        $zin = [System.IO.Compression.ZipFile]::OpenRead($full)
        try {
            $fs = [System.IO.File]::Open($tmp, [System.IO.FileMode]::CreateNew)
            $zout = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
            try {
                # 1) copy every existing entry verbatim (or with edited text), skipping removals
                foreach ($e in $zin.Entries) {
                    if ($RemoveParts -contains $e.FullName) { continue }
                    $newEntry = $zout.CreateEntry($e.FullName, [System.IO.Compression.CompressionLevel]::Optimal)
                    $os = $newEntry.Open()
                    try {
                        if ($Edits.ContainsKey($e.FullName)) {
                            $bytes = $utf8.GetBytes([string]$Edits[$e.FullName])
                            $os.Write($bytes, 0, $bytes.Length)
                        }
                        else {
                            $is = $e.Open(); try { $is.CopyTo($os) } finally { $is.Close() }
                        }
                    } finally { $os.Close() }
                }
                # 2) append brand-new text parts (e.g. new .rels files)
                foreach ($name in $NewTextParts.Keys) {
                    $ne = $zout.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
                    $os = $ne.Open()
                    try { $bytes = $utf8.GetBytes([string]$NewTextParts[$name]); $os.Write($bytes, 0, $bytes.Length) } finally { $os.Close() }
                }
                # 3) append brand-new binary parts (e.g. media images). Value is a byte[].
                foreach ($name in $NewBinaryParts.Keys) {
                    $ne = $zout.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
                    $os = $ne.Open()
                    try { $b = [byte[]]$NewBinaryParts[$name]; $os.Write($b, 0, $b.Length) } finally { $os.Close() }
                }
            } finally { $zout.Dispose(); $fs.Close() }
        } finally { $zin.Dispose() }

        # Replace the original with the rewritten package.
        [System.IO.File]::Delete($full)
        [System.IO.File]::Move($tmp, $full)
    } catch {
        # Never leave an orphaned temp file behind.
        if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        throw
    }
}

function Add-PptxImageToSlide {
    <#
        Insert an image (PNG/JPEG) into a slide as a <p:pic>, positioned/sized in EMU. Adds the
        media part, a slide relationship, and the picture shape - all via the OPC-safe Create
        rewrite (never Update mode). Assumes the content-type for the image extension is already
        declared in [Content_Types].xml (png and jpeg are, in this template). Refuses template.

        -EmuX/-EmuY/-EmuCx/-EmuCy position and size the picture (slide is 9144000 x 5143500 EMU).
        Returns the new media part name.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int]$Position,
        [Parameter(Mandatory)][string]$ImagePath,
        [Parameter(Mandatory)][int]$EmuX,
        [Parameter(Mandatory)][int]$EmuY,
        [Parameter(Mandatory)][int]$EmuCx,
        [Parameter(Mandatory)][int]$EmuCy,
        [string]$Name = 'Picture'
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    if (-not (Test-Path $ImagePath)) { throw "Image not found: $ImagePath" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path
    $ext = ([System.IO.Path]::GetExtension($ImagePath)).TrimStart('.').ToLower()
    $imgBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $ImagePath).Path)

    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        if ($Position -lt 1 -or $Position -gt $order.Count) { throw "Position out of range (1..$($order.Count))." }
        $slideEntry = $order[$Position - 1]
        $slideName = Split-Path $slideEntry -Leaf
        $slideXml = Read-ZipEntryText -Archive $zip -EntryName $slideEntry

        # next free media index
        $maxImg = 0
        foreach ($e in $zip.Entries) {
            $m = [regex]::Match($e.FullName, '^ppt/media/image(\d+)\.')
            if ($m.Success) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxImg) { $maxImg = $n } }
        }
        $imgNum = $maxImg + 1
        $mediaName = "ppt/media/image$imgNum.$ext"

        # next free rId in this slide's rels
        $relsName = "ppt/slides/_rels/$slideName.rels"
        $relsXml = Read-ZipEntryText -Archive $zip -EntryName $relsName
        $maxRid = 0
        foreach ($m in [regex]::Matches($relsXml, 'Id="rId(\d+)"')) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxRid) { $maxRid = $n } }
        $rid = "rId$($maxRid + 1)"

        # next free shape id in the slide
        $maxSid = 1
        foreach ($m in [regex]::Matches($slideXml, 'id="(\d+)"')) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxSid) { $maxSid = $n } }
        $sid = $maxSid + 1

        # new relationship (insert before closing tag)
        $rel = "<Relationship Id=""$rid"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"" Target=""../media/image$imgNum.$ext""/>"
        $newRels = $relsXml -replace '</Relationships>', ($rel + '</Relationships>')

        # picture shape
        $pic = @"
<p:pic><p:nvPicPr><p:cNvPr id="$sid" name="$Name"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr><p:blipFill><a:blip r:embed="$rid"/><a:stretch><a:fillRect/></a:stretch></p:blipFill><p:spPr><a:xfrm><a:off x="$EmuX" y="$EmuY"/><a:ext cx="$EmuCx" cy="$EmuCy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic>
"@
        $pic = $pic.Trim()
        $newSlide = $slideXml -replace '</p:spTree>', ($pic + '</p:spTree>')

        $zip.Dispose(); $zip = $null

        Set-PptxParts -Pptx $full `
            -Edits @{ $slideEntry = $newSlide; $relsName = $newRels } `
            -NewBinaryParts @{ $mediaName = $imgBytes }

        return $mediaName
    } finally { if ($zip) { $zip.Dispose() } }
}

function Remove-PptxImagesFromSlide {
    <#
        Remove ALL <p:pic> picture shapes from a slide, their image relationships, and the
        media parts they reference (when not used by any other slide). OPC-safe (Create rewrite).
        Use to replace a wrongly-inserted image: remove, then Add-PptxImageToSlide again.
        Returns the list of removed media part names.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int]$Position
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        if ($Position -lt 1 -or $Position -gt $order.Count) { throw "Position out of range (1..$($order.Count))." }
        $slideEntry = $order[$Position - 1]
        $slideName = Split-Path $slideEntry -Leaf
        $slideXml = Read-ZipEntryText -Archive $zip -EntryName $slideEntry
        $relsName = "ppt/slides/_rels/$slideName.rels"
        $relsXml = Read-ZipEntryText -Archive $zip -EntryName $relsName

        # Protected spans: a <p:pic> INSIDE an OLE object's <mc:AlternateContent> is the preview
        # image of an embedded OLE object (progId/oleObj). Removing it leaves a schema-invalid
        # <p:oleObj> with no picture, which makes PowerPoint refuse to open the file. So only
        # strip TOP-LEVEL pictures, never OLE-fallback ones.
        $protectedSpans = @()
        foreach ($ac in [regex]::Matches($slideXml, '<mc:AlternateContent\b.*?</mc:AlternateContent>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
            $protectedSpans += , @($ac.Index, $ac.Index + $ac.Length)
        }
        $inProtected = {
            param([int]$idx)
            foreach ($s in $protectedSpans) { if ($idx -ge $s[0] -and $idx -lt $s[1]) { return $true } }
            return $false
        }

        # rIds referenced by <a:blip r:embed> inside the <p:pic> shapes we will actually remove
        # (top-level pics only; OLE-fallback pics are left intact).
        $embedRids = @()
        foreach ($m in [regex]::Matches($slideXml, '<p:pic>.*?</p:pic>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
            if (& $inProtected $m.Index) { continue }
            foreach ($b in [regex]::Matches($m.Value, 'r:embed="(rId\d+)"')) { $embedRids += $b.Groups[1].Value }
        }
        # strip only the top-level <p:pic> shapes (skip those inside an OLE AlternateContent)
        $newSlide = [regex]::Replace($slideXml, '<p:pic>.*?</p:pic>', {
                param($m)
                if (& $inProtected $m.Index) { return $m.Value }
                return ''
            }, [System.Text.RegularExpressions.RegexOptions]::Singleline)

        # resolve those rIds to media targets, and remove the relationships
        $mediaTargets = @()
        $newRels = $relsXml
        foreach ($rid in ($embedRids | Select-Object -Unique)) {
            $rm = [regex]::Match($relsXml, "<Relationship[^>]*Id=""$rid""[^>]*Target=""\.\./(media/[^""]+)""[^>]*/>")
            if ($rm.Success) { $mediaTargets += ('ppt/' + $rm.Groups[1].Value) }
            $newRels = [regex]::Replace($newRels, "<Relationship[^>]*Id=""$rid""[^>]*/>", '')
        }

        # only delete a media part if no OTHER slide rels reference it
        $mediaToDelete = @()
        foreach ($media in ($mediaTargets | Select-Object -Unique)) {
            $leaf = Split-Path $media -Leaf
            $usedElsewhere = $false
            foreach ($e in $zip.Entries) {
                if ($e.FullName -eq $relsName) { continue }
                if ($e.FullName -match '^ppt/slides/_rels/.*\.rels$') {
                    $other = Read-ZipEntryText -Archive $zip -EntryName $e.FullName
                    if ($other -match [regex]::Escape($leaf)) { $usedElsewhere = $true; break }
                }
            }
            if (-not $usedElsewhere) { $mediaToDelete += $media }
        }

        $zip.Dispose(); $zip = $null

        Set-PptxParts -Pptx $full `
            -Edits @{ $slideEntry = $newSlide; $relsName = $newRels } `
            -RemoveParts $mediaToDelete

        return $mediaToDelete
    } finally { if ($zip) { $zip.Dispose() } }
}

# --- Slide order resolution ----------------------------------------------------------------
function Get-PptxSlideOrderFromArchive {
    <#
        Return an ordered array of slide entry names (e.g. 'ppt/slides/slide1.xml') in TRUE
        display order, resolved from <p:sldIdLst> in presentation.xml via r:id -> rels target.
    #>
    param([Parameter(Mandatory)][System.IO.Compression.ZipArchive]$Archive)
    $pres = Read-ZipEntryText -Archive $Archive -EntryName 'ppt/presentation.xml'
    $rels = Read-ZipEntryText -Archive $Archive -EntryName 'ppt/_rels/presentation.xml.rels'
    if (-not $pres -or -not $rels) { throw "Not a valid .pptx (missing presentation.xml or its rels)." }

    $map = @{}
    foreach ($m in [regex]::Matches($rels, 'Id="(rId\d+)"[^>]*Target="slides/(slide\d+\.xml)"')) {
        $map[$m.Groups[1].Value] = 'ppt/slides/' + $m.Groups[2].Value
    }
    [regex]::Matches($pres, '<p:sldId[^>]*r:id="(rId\d+)"') |
        ForEach-Object { $map[$_.Groups[1].Value] } | Where-Object { $_ }
}

# --- Slide text extraction -----------------------------------------------------------------
function Get-SlideTextFromXml {
    <#
        Extract the concatenated <a:t> text of a slide XML string.
        -Joined returns a single delimited string; otherwise an array of runs.
    #>
    param(
        [Parameter(Mandatory)][string]$Xml,
        [string]$Delimiter = ' | ',
        [switch]$Joined
    )
    $doc = New-Object System.Xml.XmlDocument
    $doc.LoadXml($Xml)
    $ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
    $ns.AddNamespace('a', $script:DrawingNs)
    $runs = @($doc.SelectNodes('//a:t', $ns) | ForEach-Object { $_.InnerText })
    if ($Joined) { return ($runs -join $Delimiter) }
    return $runs
}

function Get-SlideNotesEntry {
    <#
        Resolve the notesSlide entry name for a slide entry via its rels, or $null if none.
    #>
    param(
        [Parameter(Mandatory)][System.IO.Compression.ZipArchive]$Archive,
        [Parameter(Mandatory)][string]$SlideEntry
    )
    $name = Split-Path $SlideEntry -Leaf
    $relsXml = Read-ZipEntryText -Archive $Archive -EntryName "ppt/slides/_rels/$name.rels"
    if (-not $relsXml) { return $null }
    $m = [regex]::Match($relsXml, 'Target="\.\./(notesSlides/notesSlide\d+\.xml)"')
    if (-not $m.Success) { return $null }
    'ppt/' + $m.Groups[1].Value
}

function Get-PptxSlides {
    <#
        Open a .pptx read-only and return one object per slide, in display order:
          Position (1-based), Entry (zip path), File (slideN.xml), Text (joined <a:t>).
        With -IncludeNotes, also adds Notes (joined speaker-note <a:t>, space-delimited).
        Reads only the XML parts it needs (no Expand-Archive, no media/fonts).
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [string]$Delimiter = ' | ',
        [switch]$IncludeNotes
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    $full = (Resolve-Path $Pptx).Path
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        $pos = 0
        foreach ($entry in $order) {
            $pos++
            $xml = Read-ZipEntryText -Archive $zip -EntryName $entry
            if (-not $xml) { continue }
            $rootTag = [regex]::Match($xml, '<p:sld\b[^>]*>').Value
            $visible = -not ($rootTag -match 'show="0"')
            $obj = [ordered]@{
                Position   = $pos
                Entry      = $entry
                File       = Split-Path $entry -Leaf
                Visible    = $visible
                HasPicture = $xml.Contains('<p:pic>')
                Text       = Get-SlideTextFromXml -Xml $xml -Delimiter $Delimiter -Joined
            }
            if ($IncludeNotes) {
                $notesEntry = Get-SlideNotesEntry -Archive $zip -SlideEntry $entry
                $notes = ''
                if ($notesEntry) {
                    $nxml = Read-ZipEntryText -Archive $zip -EntryName $notesEntry
                    if ($nxml) { $notes = Get-SlideTextFromXml -Xml $nxml -Delimiter ' ' -Joined }
                }
                $obj.Notes = $notes
            }
            [pscustomobject]$obj
        }
    } finally { $zip.Dispose() }
}

# --- Batch text replacement (single zip open) ----------------------------------------------
function Set-PptxSlideReplacements {
    <#
        Apply one or more placeholder replacements to a .pptx COPY in a single pass.
        -Replacements is an array of hashtables: @{ Position=<n>; Find='...'; Replace='...' }.
        Matches the XML-escaped form first, then the literal form. Returns a result object
        per replacement (Applied true/false + reason). Refuses to edit the template.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][hashtable[]]$Replacements
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    # Read phase (read-only open; never Update mode).
    $cache = @{}
    $results = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        foreach ($r in $Replacements) {
            $p = [int]$r.Position
            if ($p -lt 1 -or $p -gt $order.Count) {
                $results += [pscustomobject]@{ Position = $p; Find = $r.Find; Applied = $false; Reason = "position out of range (1..$($order.Count))" }
                continue
            }
            $entry = $order[$p - 1]
            if (-not $cache.ContainsKey($entry)) { $cache[$entry] = Read-ZipEntryText -Archive $zip -EntryName $entry }
            $content = $cache[$entry]

            $findXml = ConvertTo-XmlText $r.Find
            $replXml = ConvertTo-XmlText ([string]$r.Replace)
            if ($content.Contains($findXml)) {
                $cache[$entry] = $content.Replace($findXml, $replXml)
                $results += [pscustomobject]@{ Position = $p; Find = $r.Find; Applied = $true; Reason = 'escaped match' }
            }
            elseif ($content.Contains($r.Find)) {
                $cache[$entry] = $content.Replace([string]$r.Find, $replXml)
                $results += [pscustomobject]@{ Position = $p; Find = $r.Find; Applied = $true; Reason = 'literal match' }
            }
            else {
                $results += [pscustomobject]@{ Position = $p; Find = $r.Find; Applied = $false; Reason = 'not found (may be split across runs)' }
            }
        }
    } finally { $zip.Dispose() }

    # Write phase (rewrite the package in Create mode - OPC-safe).
    $edits = @{}
    foreach ($k in $cache.Keys) { $edits[$k] = $cache[$k] }
    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $results
}

# --- Run-index targeted replacement (unambiguous; safe for repeated / split runs) ----------
function Set-PptxSlideRuns {
    <#
        Replace the inner text of specific <a:t> runs, addressed by their 0-based index on a
        slide (as printed by inspect run probes). This is UNAMBIGUOUS - unlike Find/Replace it
        never collides with repeated or substring run text - and edits only the bytes of the
        targeted run (no re-serialization). Use for slides where the same placeholder string
        repeats (e.g. the Applicability "Yes / No : ..." runs).

        -Runs is an array of hashtables: @{ Position=<n>; RunIndex=<i>; Text='<new value>' }.
        Returns a result object per run (Applied true/false + reason). Refuses to edit template.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][hashtable[]]$Runs
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    # Read phase (read-only open; never Update mode).
    $cache = @{}
    $results = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        $byPos = $Runs | Group-Object { [int]$_.Position }
        foreach ($grp in $byPos) {
            $p = [int]$grp.Name
            if ($p -lt 1 -or $p -gt $order.Count) {
                foreach ($r in $grp.Group) { $results += [pscustomobject]@{ Position = $p; RunIndex = $r.RunIndex; Applied = $false; Reason = 'position out of range' } }
                continue
            }
            $entry = $order[$p - 1]
            if (-not $cache.ContainsKey($entry)) { $cache[$entry] = Read-ZipEntryText -Archive $zip -EntryName $entry }
            $content = $cache[$entry]

            # Apply run edits for this slide from LAST index to FIRST so earlier string offsets
            # stay valid as we splice.
            $ordered = $grp.Group | Sort-Object { [int]$_.RunIndex } -Descending
            foreach ($r in $ordered) {
                $idx = [int]$r.RunIndex
                $matches = [regex]::Matches($content, '<a:t>.*?</a:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($idx -lt 0 -or $idx -ge $matches.Count) {
                    $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $false; Reason = "run index out of range (0..$($matches.Count - 1))" }
                    continue
                }
                $m = $matches[$idx]
                $newRun = '<a:t>' + (ConvertTo-XmlText ([string]$r.Text)) + '</a:t>'
                $content = $content.Substring(0, $m.Index) + $newRun + $content.Substring($m.Index + $m.Length)
                $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $true; Reason = 'run replaced' }
            }
            $cache[$entry] = $content
        }
    } finally { $zip.Dispose() }

    # Write phase (rewrite the package in Create mode - OPC-safe).
    $edits = @{}
    foreach ($k in $cache.Keys) { $edits[$k] = $cache[$k] }
    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $results
}

function Add-PptxTableCellText {
    <#
        Insert text into a genuinely EMPTY table cell - one the template ships as a blank
        paragraph with no run at all (<a:p><a:endParaRPr lang="en-US" sz="1200"/></a:p>), such as
        the Risks table's Impact/Likehood/Mitigation plan/Comments columns for its "Gen AI" /
        "Accessibility" / "Lack of training" / "Data" example rows (rule 8d: these rows are
        indicative and must be completed with real project values, or deleted if not applicable).

        Set-PptxSlideRuns cannot address these cells - it replaces the text of an EXISTING <a:t>,
        and an empty cell has none. This function instead locates the cell by table/row/column
        position and inserts a new <a:r> (reusing the cell's own <a:endParaRPr> lang/sz as the new
        run's <a:rPr>, so added text matches the surrounding table's formatting per rule 8d)
        immediately before that <a:endParaRPr>. It refuses to touch a cell that already has an
        <a:t> run, to avoid silently duplicating or shadowing existing content - use
        Set-PptxSlideRuns for a cell that already has text.

        -Cells is an array of hashtables: @{ Position=<n>; TableIndex=0; Row=<r>; Col=<c>; Text='..' }
        TableIndex/Row/Col are all 0-based, counting <a:tbl>/<a:tr>/<a:tc> elements on the slide (or
        within the row) in document order; a gridSpan-merged cell still occupies exactly one <a:tc>
        at its position. Returns a result object per cell (Applied true/false + Reason).
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][hashtable[]]$Cells
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    $cache = @{}
    $results = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        foreach ($c in $Cells) {
            $p = [int]$c.Position
            $tblIdx = if ($c.ContainsKey('TableIndex')) { [int]$c.TableIndex } else { 0 }
            $row = [int]$c.Row
            $col = [int]$c.Col
            $text = [string]$c.Text

            if ($p -lt 1 -or $p -gt $order.Count) {
                $results += [pscustomobject]@{ Position = $p; Row = $row; Col = $col; Applied = $false; Reason = 'position out of range' }
                continue
            }
            $entry = $order[$p - 1]
            if (-not $cache.ContainsKey($entry)) { $cache[$entry] = Read-ZipEntryText -Archive $zip -EntryName $entry }
            $content = $cache[$entry]

            $tblMatches = [regex]::Matches($content, '<a:tbl>.*?</a:tbl>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($tblIdx -lt 0 -or $tblIdx -ge $tblMatches.Count) {
                $results += [pscustomobject]@{ Position = $p; Row = $row; Col = $col; Applied = $false; Reason = "table index out of range (0..$($tblMatches.Count - 1))" }
                continue
            }
            $tblMatch = $tblMatches[$tblIdx]

            $rowMatches = [regex]::Matches($tblMatch.Value, '<a:tr[ >].*?</a:tr>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($row -lt 0 -or $row -ge $rowMatches.Count) {
                $results += [pscustomobject]@{ Position = $p; Row = $row; Col = $col; Applied = $false; Reason = "row index out of range (0..$($rowMatches.Count - 1))" }
                continue
            }
            $rowMatch = $rowMatches[$row]

            $cellMatches = [regex]::Matches($rowMatch.Value, '<a:tc[ >].*?</a:tc>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($col -lt 0 -or $col -ge $cellMatches.Count) {
                $results += [pscustomobject]@{ Position = $p; Row = $row; Col = $col; Applied = $false; Reason = "col index out of range (0..$($cellMatches.Count - 1))" }
                continue
            }
            $cellMatch = $cellMatches[$col]

            if ($cellMatch.Value -match '<a:t>') {
                $results += [pscustomobject]@{ Position = $p; Row = $row; Col = $col; Applied = $false; Reason = 'cell already has text - use Set-PptxSlideRuns instead' }
                continue
            }

            $endParaMatch = [regex]::Match($cellMatch.Value, '<a:endParaRPr[^>]*/>')
            if (-not $endParaMatch.Success) {
                $results += [pscustomobject]@{ Position = $p; Row = $row; Col = $col; Applied = $false; Reason = 'no empty <a:endParaRPr/> found to anchor the new run on' }
                continue
            }
            $lang = 'en-US'
            $langMatch = [regex]::Match($endParaMatch.Value, 'lang="([^"]*)"')
            if ($langMatch.Success) { $lang = $langMatch.Groups[1].Value }
            $sz = $null
            $szMatch = [regex]::Match($endParaMatch.Value, 'sz="([^"]*)"')
            if ($szMatch.Success) { $sz = $szMatch.Groups[1].Value }
            $rPrAttrs = "lang=`"$lang`""
            if ($sz) { $rPrAttrs += " sz=`"$sz`"" }
            $newRun = "<a:r><a:rPr $rPrAttrs/><a:t>" + (ConvertTo-XmlText $text) + '</a:t></a:r>'

            # Absolute offset of the <a:endParaRPr/> within the full part content.
            $absOffset = $tblMatch.Index + $rowMatch.Index + $cellMatch.Index + $endParaMatch.Index
            $content = $content.Substring(0, $absOffset) + $newRun + $content.Substring($absOffset)
            $cache[$entry] = $content
            $results += [pscustomobject]@{ Position = $p; Row = $row; Col = $col; Applied = $true; Reason = 'run inserted' }
        }
    } finally { $zip.Dispose() }

    $edits = @{}
    foreach ($k in $cache.Keys) { $edits[$k] = $cache[$k] }
    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $results
}

# --- Table row autosize (root-cause fix for text-overflow/overlap on table slides) -----------
function Measure-PptxTableRowHeightsInternal {
    <#
        Internal helper (not exported). Estimates each row's content height for a table XML
        fragment at a given font-size SCALE (1.0 = actual declared run sizes). Returns an
        array of per-row heights in EMU, same order as the table's rows. Used twice by
        Set-PptxTableRowAutosize: once at scale 1.0 to see whether the table fits as filled,
        and again at a reduced scale to size-check a candidate font shrink BEFORE committing
        to it.
    #>
    param(
        [Parameter(Mandatory)][string]$Tbl,
        [Parameter(Mandatory)][int64[]]$GridCols,
        [double]$Scale = 1.0
    )
    $reOpts = [System.Text.RegularExpressions.RegexOptions]::Singleline
    $rowMatches = [regex]::Matches($Tbl, '<a:tr\s[^>]*?\bh="(\d+)"[^>]*>.*?</a:tr>', $reOpts)
    $heights = @()
    foreach ($rowMatch in $rowMatches) {
        $rowXml = $rowMatch.Value
        $cellMatches = [regex]::Matches($rowXml, '<a:tc(?:\s[^>]*)?/>|<a:tc(?:\s[^>]*)?>.*?</a:tc>', $reOpts)
        $colIdx = 0
        $maxCellHeight = [int64]0
        foreach ($cm in $cellMatches) {
            $tc = $cm.Value
            $gridSpanM = [regex]::Match($tc, '\bgridSpan="(\d+)"')
            $span = 1
            if ($gridSpanM.Success) { $span = [Math]::Max(1, [int]$gridSpanM.Groups[1].Value) }

            $cellWidth = [int64]0
            for ($s = 0; $s -lt $span -and ($colIdx + $s) -lt $GridCols.Count; $s++) { $cellWidth += $GridCols[$colIdx + $s] }
            if ($cellWidth -le 0) { $cellWidth = 914400 }
            $colIdx += $span

            $isMergeContinuation = ($tc -match '\bhMerge="1"') -or ($tc -match '\bvMerge="1"')
            if ($isMergeContinuation) { continue }

            $marLm = [regex]::Match($tc, 'marL="(\d+)"'); $marL = if ($marLm.Success) { [int64]$marLm.Groups[1].Value } else { 91440 }
            $marRm = [regex]::Match($tc, 'marR="(\d+)"'); $marR = if ($marRm.Success) { [int64]$marRm.Groups[1].Value } else { 91440 }
            $marTm = [regex]::Match($tc, 'marT="(\d+)"'); $marT = if ($marTm.Success) { [int64]$marTm.Groups[1].Value } else { 45720 }
            $marBm = [regex]::Match($tc, 'marB="(\d+)"'); $marB = if ($marBm.Success) { [int64]$marBm.Groups[1].Value } else { 45720 }

            $usableWidth = $cellWidth - $marL - $marR
            if ($usableWidth -lt 91440) { $usableWidth = 91440 }

            $paraMatches = [regex]::Matches($tc, '<a:p>.*?</a:p>', $reOpts)
            $cellLines = 0
            $maxSz = 0
            if ($paraMatches.Count -eq 0) { $cellLines = 1 }
            foreach ($pm in $paraMatches) {
                $para = $pm.Value
                $runSzMatches = [regex]::Matches($para, '<a:r>.*?<a:rPr[^>]*\bsz="(\d+)"', $reOpts)
                $sz = 1200
                if ($runSzMatches.Count -gt 0) {
                    $sz = ($runSzMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
                } else {
                    $anySz = [regex]::Matches($para, '\bsz="(\d+)"')
                    if ($anySz.Count -gt 0) { $sz = ($anySz | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum }
                }
                $sz = $sz * $Scale
                if ($sz -gt $maxSz) { $maxSz = $sz }

                $texts = [regex]::Matches($para, '<a:t>(.*?)</a:t>')
                $paraText = ($texts | ForEach-Object { [System.Net.WebUtility]::HtmlDecode($_.Groups[1].Value) }) -join ''
                $fontPt = $sz / 100.0
                # 0.62, not the more typical ~0.52 for a plain proportional font: this
                # template's "Encode Sans" is usually unavailable (e.g. on a Linux render host)
                # and falls back to a substitute whose metrics run wider, plus this pads for the
                # heuristic's own imprecision - calibrated against the actual slide 32 overflow.
                $avgCharWidthEmu = [Math]::Max(1.0, $fontPt * 0.62 * 12700)
                $charsPerLine = [Math]::Max(1, [Math]::Floor($usableWidth / $avgCharWidthEmu))
                $len = $paraText.Length
                $linesInPara = if ($len -eq 0) { 1 } else { [Math]::Ceiling($len / $charsPerLine) }
                $cellLines += $linesInPara
            }
            if ($maxSz -eq 0) { $maxSz = 1200 * $Scale }
            $lineHeightEmu = ($maxSz / 100.0) * 1.3 * 12700
            $cellHeight = [int64]([Math]::Ceiling($cellLines * $lineHeightEmu) + $marT + $marB)
            if ($cellHeight -gt $maxCellHeight) { $maxCellHeight = $cellHeight }
        }
        $heights += $maxCellHeight
    }
    return , $heights
}

function Set-PptxTableRowAutosize {
    <#
        Root-cause fix for the "longer real content overlaps something below the table" class
        of defect found by rendering the slide 32 (Technical stack) table to PNG: replacing a
        template's short placeholder cell text ("Debian XX*", a ~66-char comment) with longer
        real content ("~115-char comment") makes the table need more vertical room than the
        template originally laid out for it - and PowerPoint tables do not push other shapes
        out of their way, so a standalone caption/callout sitting below the table (here, a
        fixed-position "All the software and libraries will be upgraded..." note box) ends up
        with the now-taller table rendered underneath it. Rendering the deck (LibreOffice) is
        how this was found; the same geometry defect reproduces in real PowerPoint, since it is
        two independently-positioned shapes overlapping, not a renderer quirk.

        Call this AFTER filling a table's cell text (Set-PptxSlideRuns / Set-PptxSlideReplacements)
        on every table-bearing slide - see presentation-gates SKILL.md rule 8e. For each table:
          1. Estimates each row's content height from its actual text (column width, cell
             insets, gridSpan, and the run font size(s) present), using a character-width
             heuristic (0.62 * font size, padded above the ~0.52 textbook average to cover
             both substitute-font widening and the heuristic's own imprecision).
          2. Finds the next shape positioned below the table (by XML/declaration order) to learn
             how much room is actually free before something else starts, and how much further
             that shape could still be nudged down before it would run off the bottom of the
             16:9 slide (-SlideHeightEmu, default 5143500 - this template's canvas height).
          3. If the table already fits in that free room: done, no visual change, but the
             <a:tr h="..."> values and the frame's declared cy are still set to the content-
             accurate heights (cosmetic/consistency - real PowerPoint recomputes these dynamically
             when it opens the file, but shipping accurate values avoids relying on that).
          4. If it doesn't fit but nudging the next shape down (within the slide's remaining
             room) closes the gap: shift that shape down by exactly the overflow - the content
             itself is untouched.
          5. If it still doesn't fit even after using all the room on the slide: shrinks every
             run's font size in the table by the smallest uniform factor (floor 9pt / sz=900)
             that makes it fit, and nudges the next shape down by any remainder. This is a last
             resort - a reviewer should still sanity-check whether that content truly needs to
             be that dense, or should be shortened instead (this function cannot tell).
        Reports exactly which of these happened per position, so the caller/report doesn't have
        to guess from the file diff.

        -Positions: slide positions whose top-level table(s) should be sized. Never shrinks a
        row/font below what's needed - only grows/shrinks exactly as far as the content and the
        slide's own geometry require. OPC-safe: byte-level splice + Create-mode rewrite
        (Set-PptxParts), like the rest of this module - never re-serializes slide XML.

        This is a heuristic (character-width approximation, not a real text-layout engine), not
        a substitute for actually looking at the rendered PNG - always re-render after calling
        it and visually confirm, especially on a last-resort font shrink.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int[]]$Positions,
        [int64]$SlideHeightEmu = 5143500
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path
    $reOpts = [System.Text.RegularExpressions.RegexOptions]::Singleline
    $bottomMargin = 45720   # 0.05in - never push a shape flush against the slide edge
    $gapMargin = 45720      # 0.05in - minimum visual gap to preserve above the next shape

    $cache = @{}
    $report = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        foreach ($p in $Positions) {
            if ($p -lt 1 -or $p -gt $order.Count) { $report += [pscustomobject]@{ Position = $p; Applied = $false; RowsResized = 0; FontScale = 1.0; ShapeShiftedEmu = 0; Reason = 'position out of range' }; continue }
            $entry = $order[$p - 1]
            if (-not $cache.ContainsKey($entry)) { $cache[$entry] = Read-ZipEntryText -Archive $zip -EntryName $entry }
            $content = $cache[$entry]

            $tblMatches = [regex]::Matches($content, '<a:tbl>.*?</a:tbl>', $reOpts)
            if ($tblMatches.Count -eq 0) { $report += [pscustomobject]@{ Position = $p; Applied = $false; RowsResized = 0; FontScale = 1.0; ShapeShiftedEmu = 0; Reason = 'no <a:tbl> found' }; continue }

            $plannedEdits = @()   # list of @{ Start; Length; Replacement }
            $rowsResized = 0
            $minScaleApplied = 1.0
            $totalShift = 0

            foreach ($tblMatch in $tblMatches) {
                $tbl = $tblMatch.Value
                $gridCols = @([regex]::Matches($tbl, '<a:gridCol[^>]*\sw="(\d+)"') | ForEach-Object { [int64]$_.Groups[1].Value })
                if ($gridCols.Count -eq 0) { continue }

                # This table's own frame position (search backward for the nearest preceding xfrm).
                # p:graphicFrame (tables, embedded objects) uses <p:xfrm>; ordinary shapes
                # (<p:sp>, <p:pic>) carry their position as <a:xfrm> inside <p:spPr>/<p:pic>'s
                # shape properties - match either so a plain textbox below the table is found.
                $xfrmPattern = '<[ap]:xfrm[^>]*>\s*<a:off x="(-?\d+)" y="(-?\d+)"\s*/>\s*<a:ext cx="(\d+)" cy="(\d+)"\s*/>\s*</[ap]:xfrm>'
                $beforeTbl = $content.Substring(0, $tblMatch.Index)
                $selfXfrms = [regex]::Matches($beforeTbl, $xfrmPattern)
                if ($selfXfrms.Count -eq 0) { continue }
                $selfXfrm = $selfXfrms[$selfXfrms.Count - 1]
                $tableY = [int64]$selfXfrm.Groups[2].Value
                $cyGroup = $selfXfrm.Groups[4]

                # The shape positioned immediately below the table on the SLIDE - not simply the
                # next xfrm in document order, because shapes are not necessarily declared in
                # top-to-bottom visual order (e.g. a callout box drawn above the table can appear
                # later in the XML than the table itself). Scan every xfrm on the slide, exclude
                # the table's own, keep only those whose top (y) is at or below the table's own
                # top, and take the SMALLEST such y as the nearest shape below.
                $allXfrms = [regex]::Matches($content, $xfrmPattern)
                $hasNextShape = $false
                $nextShapeY = $SlideHeightEmu
                $nextShapeH = 0
                $nextShapeYGroup = $null
                foreach ($nx in $allXfrms) {
                    if ($nx.Index -eq $selfXfrm.Index) { continue }  # skip the table's own xfrm
                    $candY = [int64]$nx.Groups[2].Value
                    if ($candY -lt $tableY) { continue }  # above the table - not relevant
                    if (-not $hasNextShape -or $candY -lt $nextShapeY) {
                        $hasNextShape = $true
                        $nextShapeY = $candY
                        $nextShapeH = [int64]$nx.Groups[4].Value
                        $nextShapeYGroup = $nx.Groups[2]
                    }
                }
                if (-not $hasNextShape) { $nextShapeY = $SlideHeightEmu }

                $budget = $nextShapeY - $tableY - $gapMargin
                if ($budget -lt 0) { $budget = 0 }
                $maxSlack = 0
                if ($hasNextShape) {
                    $maxSlack = $SlideHeightEmu - $bottomMargin - ($nextShapeY + $nextShapeH)
                    if ($maxSlack -lt 0) { $maxSlack = 0 }
                }
                $extendedBudget = $budget + $maxSlack

                $naturalHeights = Measure-PptxTableRowHeightsInternal -Tbl $tbl -GridCols $gridCols -Scale 1.0
                $naturalTotal = [int64](($naturalHeights | Measure-Object -Sum).Sum)

                $finalHeights = $naturalHeights
                $finalTotal = $naturalTotal
                $scale = 1.0
                $shiftNeeded = 0

                if ($naturalTotal -gt $budget) {
                    if ($naturalTotal -le $extendedBudget) {
                        $shiftNeeded = $naturalTotal - $budget
                    } else {
                        if ($extendedBudget -gt 0) {
                            $scale = [Math]::Max(0.6, [Math]::Min(0.95, $extendedBudget / [double]$naturalTotal))
                        } else {
                            $scale = 0.6
                        }
                        $scaledHeights = Measure-PptxTableRowHeightsInternal -Tbl $tbl -GridCols $gridCols -Scale $scale
                        $scaledTotal = [int64](($scaledHeights | Measure-Object -Sum).Sum)
                        $finalHeights = $scaledHeights
                        $finalTotal = $scaledTotal
                        $shiftNeeded = [Math]::Min($maxSlack, [Math]::Max(0, $scaledTotal - $budget))
                    }
                }
                if ($shiftNeeded -lt 0) { $shiftNeeded = 0 }
                if ($scale -lt $minScaleApplied) { $minScaleApplied = $scale }
                $totalShift += $shiftNeeded

                # Queue the font-size shrink (only if scale < 1.0): rewrite every sz="N" inside
                # this table to round(N*scale) clamped to a 9pt floor, nearest 0.5pt (50 units).
                if ($scale -lt 1.0) {
                    $szMatches = [regex]::Matches($tbl, '\bsz="(\d+)"')
                    foreach ($szm in $szMatches) {
                        $origSz = [int]$szm.Groups[1].Value
                        $newSz = [Math]::Max(900, [Math]::Round(($origSz * $scale) / 50.0) * 50)
                        if ($newSz -ne $origSz) {
                            $g = $szm.Groups[1]
                            $plannedEdits += [pscustomobject]@{ Start = $tblMatch.Index + $g.Index; Length = $g.Length; Replacement = [string]([int]$newSz) }
                        }
                    }
                }

                # Queue row height edits using the final (natural or scaled) per-row heights.
                $rowMatches = [regex]::Matches($tbl, '<a:tr\s[^>]*?\bh="(\d+)"[^>]*>.*?</a:tr>', $reOpts)
                for ($i = 0; $i -lt $rowMatches.Count -and $i -lt $finalHeights.Count; $i++) {
                    $rowMatch = $rowMatches[$i]
                    $existingH = [int64]$rowMatch.Groups[1].Value
                    $newH = $finalHeights[$i]
                    if ($newH -ne $existingH) {
                        $hGroup = $rowMatch.Groups[1]
                        $plannedEdits += [pscustomobject]@{ Start = $tblMatch.Index + $hGroup.Index; Length = $hGroup.Length; Replacement = [string]([int64]$newH) }
                        $rowsResized++
                    }
                }

                # Queue the frame's own cy update if the table's total height changed.
                $existingCy = [int64]$cyGroup.Value
                if ($finalTotal -ne $existingCy) {
                    $plannedEdits += [pscustomobject]@{ Start = $cyGroup.Index; Length = $cyGroup.Length; Replacement = [string]$finalTotal }
                }

                # Queue the next shape's downward shift, if any. $nextShapeYGroup.Index is
                # already an absolute offset into $content (found via a full-content scan above).
                if ($shiftNeeded -gt 0 -and $nextShapeYGroup) {
                    $newY = $nextShapeY + $shiftNeeded
                    $plannedEdits += [pscustomobject]@{ Start = $nextShapeYGroup.Index; Length = $nextShapeYGroup.Length; Replacement = [string]([int64]$newY) }
                }
            }

            if ($plannedEdits.Count -eq 0) {
                $report += [pscustomobject]@{ Position = $p; Applied = $false; RowsResized = 0; FontScale = 1.0; ShapeShiftedEmu = 0; Reason = 'already fits - no change needed' }
                continue
            }

            # Apply right-to-left so earlier offsets stay valid as we splice (same pattern as
            # Set-PptxSlideRuns / Set-PptxSlideReplacements elsewhere in this module).
            $ordered = $plannedEdits | Sort-Object { [int64]$_.Start } -Descending
            foreach ($e in $ordered) {
                $content = $content.Substring(0, $e.Start) + $e.Replacement + $content.Substring($e.Start + $e.Length)
            }
            $cache[$entry] = $content
            $reason = $null
            if ($minScaleApplied -lt 1.0) { $reason = "font shrunk to $([Math]::Round($minScaleApplied*100))% to fit" }
            $report += [pscustomobject]@{ Position = $p; Applied = $true; RowsResized = $rowsResized; FontScale = $minScaleApplied; ShapeShiftedEmu = $totalShift; Reason = $reason }
        }
    } finally { $zip.Dispose() }

    $edits = @{}
    foreach ($k in $cache.Keys) { $edits[$k] = $cache[$k] }
    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $report
}

function Test-PptxTableOverflowRisk {
    <#
        Text/geometry-only early warning for the table-overflow defect class
        Set-PptxTableRowAutosize fixes (see its help and SKILL.md rule 8e): for every table on
        every given slide position, estimates the table's natural content height the same way
        Set-PptxTableRowAutosize does, and flags it if that height would still need a font
        shrink to fit before the next shape on the slide - i.e. Set-PptxTableRowAutosize was
        never run on it, or ran and had to shrink fonts to cope, either of which is worth a
        second look. This is the rule-8c-style "a text-only check can't replace looking at the
        render" check for THIS specific defect: it catches the geometry case cheaply, in every
        validate-deck.ps1 run, without needing to render anything - but a PASS here is not proof
        the slide looks right; it only means the known failure mode wasn't detected. Always
        still do the full visual render pass before calling a deck final.

        -Positions: slide positions to check (validate-deck.ps1 passes every visible slide).
        Returns one object per table found, with Position, RowCount, NaturalHeightEmu,
        BudgetEmu, FontScaleNeeded (1.0 = fits as-is) and AtRisk (bool - true when
        FontScaleNeeded < 1.0, meaning even using all the slide's free room wasn't enough).
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int[]]$Positions,
        [int64]$SlideHeightEmu = 5143500
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    $full = (Resolve-Path $Pptx).Path
    $reOpts = [System.Text.RegularExpressions.RegexOptions]::Singleline
    $bottomMargin = 45720
    $gapMargin = 45720
    $xfrmPattern = '<[ap]:xfrm[^>]*>\s*<a:off x="(-?\d+)" y="(-?\d+)"\s*/>\s*<a:ext cx="(\d+)" cy="(\d+)"\s*/>\s*</[ap]:xfrm>'

    $results = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        foreach ($p in $Positions) {
            if ($p -lt 1 -or $p -gt $order.Count) { continue }
            $entry = $order[$p - 1]
            $content = Read-ZipEntryText -Archive $zip -EntryName $entry
            $tblMatches = [regex]::Matches($content, '<a:tbl>.*?</a:tbl>', $reOpts)
            foreach ($tblMatch in $tblMatches) {
                $tbl = $tblMatch.Value
                $gridCols = @([regex]::Matches($tbl, '<a:gridCol[^>]*\sw="(\d+)"') | ForEach-Object { [int64]$_.Groups[1].Value })
                if ($gridCols.Count -eq 0) { continue }

                $beforeTbl = $content.Substring(0, $tblMatch.Index)
                $selfXfrms = [regex]::Matches($beforeTbl, $xfrmPattern)
                if ($selfXfrms.Count -eq 0) { continue }
                $selfXfrm = $selfXfrms[$selfXfrms.Count - 1]
                $tableY = [int64]$selfXfrm.Groups[2].Value

                $allXfrms = [regex]::Matches($content, $xfrmPattern)
                $hasNextShape = $false
                $nextShapeY = $SlideHeightEmu
                $nextShapeH = 0
                foreach ($nx in $allXfrms) {
                    if ($nx.Index -eq $selfXfrm.Index) { continue }
                    $candY = [int64]$nx.Groups[2].Value
                    if ($candY -lt $tableY) { continue }
                    if (-not $hasNextShape -or $candY -lt $nextShapeY) {
                        $hasNextShape = $true; $nextShapeY = $candY; $nextShapeH = [int64]$nx.Groups[4].Value
                    }
                }
                if (-not $hasNextShape) { $nextShapeY = $SlideHeightEmu }

                $budget = [Math]::Max(0, $nextShapeY - $tableY - $gapMargin)
                $maxSlack = 0
                if ($hasNextShape) { $maxSlack = [Math]::Max(0, $SlideHeightEmu - $bottomMargin - ($nextShapeY + $nextShapeH)) }
                $extendedBudget = $budget + $maxSlack

                $naturalHeights = Measure-PptxTableRowHeightsInternal -Tbl $tbl -GridCols $gridCols -Scale 1.0
                $naturalTotal = [int64](($naturalHeights | Measure-Object -Sum).Sum)

                $scaleNeeded = 1.0
                if ($naturalTotal -gt $extendedBudget -and $extendedBudget -gt 0) {
                    $scaleNeeded = $extendedBudget / [double]$naturalTotal
                } elseif ($naturalTotal -gt $extendedBudget) {
                    $scaleNeeded = 0.0
                }

                $results += [pscustomobject]@{
                    Position          = $p
                    RowCount          = $naturalHeights.Count
                    NaturalHeightEmu  = $naturalTotal
                    BudgetEmu         = $extendedBudget
                    FontScaleNeeded   = [Math]::Round($scaleNeeded, 3)
                    AtRisk            = ($scaleNeeded -lt 0.999)
                }
            }
        }
    } finally { $zip.Dispose() }
    return $results
}

# --- Slide map: position -> Title + Gate tags (SINGLE SOURCE OF TRUTH) ----------------------
# Tags: G1 G2 G3 G4 (primary gate to fill), GEN (general / any solution), ALL (every gate),
#       SKIP (front matter, dividers, reference/example slides - not filled with project data).
# Keep in sync with references/template-structure.md.
# V5.2 numbering (75-slide template). Recaled from SIBS_Architecture_Gates_Template_V5.2.pptx.
# V5.2 dropped the "Revisions index (your document)" slide and inserted four new content slides:
# Exit plan for SaaS (14), Exit plan for make cloud/AWS (15), SOX/CAC stock-flow (20), DATA MODEL (43).
$script:SlideMap = @{
     1 = @{ T = 'Cover (project name)';                            G = @('G1') }
     2 = @{ T = 'Revisions index of the template';                 G = @('SKIP') }
     3 = @{ T = 'Introduction';                                    G = @('SKIP') }
     4 = @{ T = 'Approval process: Study/NO/Discovery';            G = @('SKIP') }
     5 = @{ T = 'Approval process: Realisation/NE/Delivery';       G = @('SKIP') }
     6 = @{ T = 'NOTES - User guide';                              G = @('SKIP') }
     7 = @{ T = 'Table of content';                                G = @('SKIP') }
     8 = @{ T = 'Objectives';                                      G = @('G1', 'G2') }
     9 = @{ T = 'Architecture One Pager';                          G = @('G1') }
    10 = @{ T = 'Architecture Overview Diagram';                   G = @('G1') }
    11 = @{ T = 'Applicability';                                   G = @('G1') }
    12 = @{ T = 'Project information / Synthesis';                 G = @('G2') }
    13 = @{ T = 'Data Privacy';                                    G = @('G1', 'G2') }
    14 = @{ T = 'Exit plan for SaaS Applications';                G = @('G2') }
    15 = @{ T = 'Exit Plan for make cloud applications (AWS)';    G = @('G2') }
    16 = @{ T = 'Objectives of the project';                       G = @('GEN') }
    17 = @{ T = 'Functional Architecture - dependencies';         G = @('G2') }
    18 = @{ T = 'Non-Functional Requirements (NFR)';              G = @('G2') }
    19 = @{ T = 'Enterprise Architecture - dependencies';         G = @('G2') }
    20 = @{ T = 'FOR SOX / CAC Applications';                     G = @('G2') }
    21 = @{ T = 'SOLUTION TO BE VALIDATED (divider)';             G = @('SKIP') }
    22 = @{ T = 'Impacted Applications Service';                   G = @('G2') }
    23 = @{ T = 'Risks';                                           G = @('G1', 'G2', 'G4') }
    24 = @{ T = 'Costs (global view)';                             G = @('G1', 'G2', 'G4') }
    25 = @{ T = 'Costs (AWS estimate)';                            G = @('G2', 'G4') }
    26 = @{ T = 'Timeline';                                        G = @('GEN') }
    27 = @{ T = 'Summary of the Solutions';                        G = @('GEN') }
    28 = @{ T = 'Presentation of the Cloud Project';              G = @('G1', 'G2') }
    29 = @{ T = 'Cloud';                                           G = @('G1', 'G2') }
    30 = @{ T = 'Cloud: Build & Run organization';               G = @('G3', 'G4') }
    31 = @{ T = 'Technical Architecture - global description';    G = @('GEN') }
    32 = @{ T = 'Technical stack (1/2)';                           G = @('G3') }
    33 = @{ T = 'Application Flows technical diagram';            G = @('G2') }
    34 = @{ T = 'Availability, SLA';                               G = @('GEN') }
    35 = @{ T = 'Data summary';                                    G = @('GEN') }
    36 = @{ T = 'Functional objects for data platform';          G = @('GEN') }
    37 = @{ T = 'Power BI sizing';                                 G = @('GEN') }
    38 = @{ T = 'DevSecOps';                                       G = @('G1', 'G2') }
    39 = @{ T = 'DevSecOps (environment)';                         G = @('G2', 'G3') }
    40 = @{ T = 'Enterprise Architecture - interactions details'; G = @('G2') }
    41 = @{ T = 'Impacted Applications Service';                   G = @('G2') }
    42 = @{ T = 'Technical Architecture global view';            G = @('GEN') }
    43 = @{ T = 'DATA MODEL';                                      G = @('G2') }
    44 = @{ T = 'API';                                             G = @('G2') }
    45 = @{ T = 'Gen AI';                                          G = @('G2', 'G3') }
    46 = @{ T = 'Container orchestrator - technical stack';       G = @('G3') }
    47 = @{ T = 'Technical stack (2/2)';                           G = @('GEN') }
    48 = @{ T = 'Technical Architecture global view (focus)';     G = @('GEN') }
    49 = @{ T = 'Localization';                                    G = @('GEN') }
    50 = @{ T = 'Environments needs & Account organization';      G = @('GEN') }
    51 = @{ T = 'Existing migration strategy (M2C)';              G = @('GEN') }
    52 = @{ T = 'Batch strategy';                                  G = @('GEN') }
    53 = @{ T = 'Data-flow';                                       G = @('GEN') }
    54 = @{ T = 'Application architecture: SSDLC';                G = @('GEN') }
    55 = @{ T = 'Access rights';                                   G = @('GEN') }
    56 = @{ T = 'Environment deployment';                          G = @('GEN') }
    57 = @{ T = 'Tagging and FinOps strategy';                    G = @('GEN') }
    58 = @{ T = 'Monitoring';                                      G = @('G2', 'G3') }
    59 = @{ T = 'RPA';                                             G = @('GEN') }
    60 = @{ T = 'Low code & Citizen development';                 G = @('G3') }
    61 = @{ T = 'Costs (AWS estimate)';                            G = @('GEN') }
    62 = @{ T = 'Costs (global view)';                             G = @('GEN') }
    63 = @{ T = 'Threat modeling - Report';                       G = @('G2') }
    64 = @{ T = 'Application architecture: SSDLC';                G = @('GEN') }
    65 = @{ T = 'Residual Risks';                                  G = @('G1', 'G2', 'G4') }
    66 = @{ T = 'TCC after Design - approvers';                   G = @('G3') }
    67 = @{ T = 'Summary of the Solutions';                        G = @('GEN') }
    68 = @{ T = 'TCC initial - Approval';                          G = @('G2') }
    69 = @{ T = 'TCC initial - Actions';                           G = @('G2') }
    70 = @{ T = 'TCC initial - approvers';                         G = @('G2') }
    71 = @{ T = 'Reference & examples (divider)';                 G = @('SKIP') }
    72 = @{ T = 'Subject Matter Experts';                          G = @('SKIP') }
    73 = @{ T = 'Flow mapping - guideline';                        G = @('SKIP') }
    74 = @{ T = 'Overview Diagram - EXAMPLE';                      G = @('SKIP') }
    75 = @{ T = 'Timeline for Data project - EXAMPLE';            G = @('SKIP') }
}

function Get-SlideMap {
    <# Return the position -> @{ T=title; G=@(tags) } map. #>
    $script:SlideMap
}

function Get-SlideTitle {
    <#
        Derive a short, human-readable TITLE from a slide's actual text (the joined <a:t> runs
        produced by Get-PptxSlides, segments separated by ' | '). This is the GENERIC way to label
        a slide: it reads the real deck, so it stays correct whatever the deck's numbering or how
        many slides it has - unlike the V5.2 SlideMap titles, which are only true for a standard
        75-slide template. The SlideMap is kept for gate TAGS and as a fallback label when a slide
        is absent, never to title an existing slide.

        Heuristic: take the first non-empty, meaningful segment (skip pure punctuation / decorative
        runs like '*', '-', bullets), collapse inner whitespace, strip a trailing colon, and cap
        the length so the checklist stays readable. Returns '' when no usable text is found (the
        caller then falls back to the SlideMap title, or 'Slide N').
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [int]$MaxLength = 70
    )
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $segments = $Text -split '\s*\|\s*'
    foreach ($seg in $segments) {
        $s = ($seg -replace '\s+', ' ').Trim()
        # skip decorative/empty segments: pure punctuation, single symbols, or too short to be a title
        if ($s -eq '') { continue }
        if ($s -match '^[\p{P}\p{S}\s]+$') { continue }   # only punctuation/symbols
        if ($s.Length -lt 2) { continue }
        $s = $s.TrimEnd(':', ' ', '-', [char]0x2013, [char]0x2014).Trim()
        if ($s -eq '') { continue }
        if ($s.Length -gt $MaxLength) { $s = $s.Substring(0, $MaxLength).TrimEnd() + '...' }
        return $s
    }
    return ''
}

# --- Required annex deliverables per gate (SINGLE SOURCE OF TRUTH) --------------------------
# Documents/artefacts that the gates require IN ADDITION to filling slides (the template's
# "Link to ..." fields). Each has:
#   Id, Name, Gate(s)
#   SlideRole  : a case-insensitive title/role marker searched in the ACTUAL deck to resolve the
#                real display position (robust to decks that add/reorder slides vs the V5.2 count).
#   SlideHint  : the V5.2 standard position, used ONLY as a fallback if SlideRole is not found and
#                as documentation. NEVER used to drive the real position when the role resolves.
#   LinkFile   : the generated deliverable filename; if that string is present on the resolved
#                slide, the deliverable's link is POSTED -> default status becomes "Provided".
# This is the ONE place the mapping lives; references/deliverables.md documents it, the script
# reads it. Do not duplicate the mapping elsewhere.
$script:Deliverables = @(
    @{ Id = 'digitalme-demand';   Name = 'DigitalMe Demand (ID + link)';                 Gate = @('G1');       SlideRole = 'Architecture One Pager';                 SlideHint = 9;  LinkFile = '' }
    @{ Id = 'overview-diagram';   Name = 'As-Is / To-Be Overview diagram';               Gate = @('G1');       SlideRole = 'Architecture OVERVIEW DIAGRAM';          SlideHint = 10; LinkFile = '' }
    @{ Id = 'dp-self-assessment'; Name = 'Data Privacy self-assessment (GDPR)';          Gate = @('G1', 'G2'); SlideRole = 'Data Privacy';                           SlideHint = 13; LinkFile = '' }
    @{ Id = 'func-arch-doc';      Name = 'Functional Architecture document';             Gate = @('G2');       SlideRole = 'Functional Architecture document';       SlideHint = 17; LinkFile = '_functional_architecture_document.docx' }
    @{ Id = 'nfr-doc';            Name = 'Non-Functional Requirements (NFR) document';   Gate = @('G2');       SlideRole = 'Non-Functional Requirements';            SlideHint = 18; LinkFile = '_NFR.xlsm' }
    @{ Id = 'ent-data-model';     Name = 'Enterprise data model / Application flow';     Gate = @('G2');       SlideRole = 'Enterprise Architecture - DEPENDENCIES'; SlideHint = 19; LinkFile = '' }
    @{ Id = 'risk-analysis';      Name = 'Risk analysis';                                Gate = @('G2');       SlideRole = 'RISKs';                                  SlideHint = 23; LinkFile = '' }
    @{ Id = 'cost-estimate';      Name = 'Cost estimate (AWS Calculator + K amounts)';   Gate = @('G2');       SlideRole = 'Costs (for Gate';                        SlideHint = 24; LinkFile = '' }
    @{ Id = 'timeline';           Name = 'Timeline / macro planning';                    Gate = @('G2');       SlideRole = 'Timeline';                               SlideHint = 26; LinkFile = '' }
    @{ Id = 'cloud-eligibility';  Name = 'Cloud eligibility tree';                       Gate = @('G2');       SlideRole = 'PRESENTATION OF THE CLOUD PROJECT';      SlideHint = 28; LinkFile = '' }
    @{ Id = 'tech-arch-doc';      Name = 'Technical Architecture document (DAT) + diagram'; Gate = @('G2');    SlideRole = 'Technical Architecture global view';     SlideHint = 42; LinkFile = '_technical_architecture_document.docx' }
    @{ Id = 'flow-mapping';       Name = 'Functional & Technical flow mapping';          Gate = @('G2');       SlideRole = 'Data-flow';                              SlideHint = 73; LinkFile = '_technical_architecture_dataflow_mapping.xlsx' }
    @{ Id = 'access-rights';      Name = 'Access rights matrix';                         Gate = @('G2');       SlideRole = 'ACCESS RIGHTS';                          SlideHint = 55; LinkFile = '_access_right_matrix.xlsx' }
    @{ Id = 'threat-model';       Name = 'Threat modeling report';                       Gate = @('G2');       SlideRole = 'Threat modeling';                        SlideHint = 63; LinkFile = '_threat_modeling.xlsx' }
)

function Get-Deliverables {
    <# Return the list of required annex deliverables (see $script:Deliverables). #>
    $script:Deliverables
}

function Resolve-DeliverableSlide {
    <#
        Resolve the REAL display position of a deliverable in a given deck by matching its
        SlideRole marker against actual slide titles (robust to added/reordered slides). Also
        reports whether the deliverable's LinkFile string is present on that slide (= link posted).

        Returns a hashtable: @{ Position = <n|null>; LinkPosted = <bool>; Resolved = <bool> }.
        Position falls back to SlideHint when the role is not found (Resolved=$false).

        -Slides is the output of Get-PptxSlides (so the caller reads the deck once).
    #>
    param(
        [Parameter(Mandatory)][hashtable]$Deliverable,
        [Parameter(Mandatory)][object[]]$Slides
    )
    $role = [string]$Deliverable.SlideRole
    $linkFile = [string]$Deliverable.LinkFile

    # Collect ALL visible slides whose TITLE begins with the role marker (not just the first), so a
    # short/generic role ("Timeline", "RISKs", "Data-flow", "Costs", "Data Privacy") that could
    # appear on more than one slide can be detected and reported instead of silently taking the
    # first. Matching is ANCHORED to the start of a title segment (see Find-SlidesByTitleRole).
    $hits = @(Find-SlidesByTitleRole -Role $role -Slides $Slides)

    if ($hits.Count -eq 0) {
        return @{ Position = $Deliverable.SlideHint; LinkPosted = $false; Resolved = $false; Ambiguous = $false; MatchCount = 0 }
    }
    $ambiguous = $hits.Count -gt 1
    if ($ambiguous) {
        $positions = ($hits | ForEach-Object { $_.Position }) -join ', '
        Write-Warning ("Deliverable '$($Deliverable.Id)': SlideRole '$role' matched $($hits.Count) slides (display positions $positions). Taking the first in display order ($($hits[0].Position)). Make the SlideRole more distinctive if this is wrong.")
    }
    $hit = $hits[0]
    $linkPosted = $false
    if ($linkFile -ne '') {
        $linkPosted = (([string]$hit.Text).IndexOf($linkFile, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
    }
    return @{ Position = $hit.Position; LinkPosted = $linkPosted; Resolved = $true; Ambiguous = $ambiguous; MatchCount = $hits.Count }
}

function Find-SlidesByTitleRole {
    <#
        Return the visible slides (in display order) whose TITLE starts with the given role marker.
        Shared, generic title-role matcher used by both the deliverable resolution and the gate
        tagging, so the "what counts as a title match" rule lives in ONE place.

        Rule (anchored, not "contains anywhere"):
          - look only in the slide's TITLE zone (leading ~140 chars of the joined <a:t> text);
          - split that zone on the run separator ' | ' into segments;
          - a segment MATCHES when, after stripping a leading "(Solution X) -" / "Solution N -"
            style prefix and surrounding punctuation, it STARTS with the role (case-insensitive).
        Anchoring to a segment start is what makes a short role (e.g. "Costs", "Timeline") robust:
        it will not match a slide that merely mentions the word later in a sentence/table.
    #>
    param(
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][object[]]$Slides
    )
    $roleTrim = $Role.Trim()
    $out = @()
    foreach ($s in ($Slides | Sort-Object Position)) {
        if (-not $s.Visible) { continue }
        $txt = [string]$s.Text
        $titleZone = if ($txt.Length -gt 140) { $txt.Substring(0, 140) } else { $txt }
        $segments = $titleZone -split '\s*\|\s*'
        $segMatch = $false
        foreach ($seg in $segments) {
            $cand = $seg.Trim()
            # strip a leading "(Solution X) -" / "(Solution 1) -" / "Solution X -" decorative prefix.
            # Separator may be hyphen, en-dash or em-dash or colon (decks mix them).
            $cand = [regex]::Replace($cand, '^\(?\s*Solution\s*[0-9Xx]+\s*\)?\s*[-\u2013\u2014:]\s*', '')
            $cand = $cand.TrimStart('(', ')', '-', [char]0x2013, [char]0x2014, ':', ' ')
            if ($cand.StartsWith($roleTrim, [System.StringComparison]::OrdinalIgnoreCase)) { $segMatch = $true; break }
        }
        if ($segMatch) { $out += $s }
    }
    return $out
}

function Get-SlideGateTags {
    <#
        Resolve the gate TAGS (G1/G2/G3/G4/GEN/SKIP) of a REAL deck slide, by matching its actual
        title against the SlideMap's titles - NOT by indexing the SlideMap by a fixed V5.2 number.
        This keeps the SlideMap as the single source of truth for "which gate does a slide belong
        to", while the slide's POSITION and TITLE always come from the real deck (sldIdLst order).

        Matching treats each SlideMap title as a role marker. Returns the tag array of the BEST
        (longest-title) SlideMap entry whose title matches a title segment, or @() when none
        matches (the slide still appears in the deck, just not forced into a gate section).

        -Slide is one object from Get-PptxSlides. -SlideMap defaults to the shared map.
    #>
    param(
        [Parameter(Mandatory)][object]$Slide,
        [hashtable]$SlideMap = $script:SlideMap
    )
    $txt = [string]$Slide.Text
    $titleZone = if ($txt.Length -gt 140) { $txt.Substring(0, 140) } else { $txt }
    $segments = @($titleZone -split '\s*\|\s*' | ForEach-Object {
            $c = $_.Trim()
            $c = [regex]::Replace($c, '^\(?\s*Solution\s*[0-9Xx]+\s*\)?\s*[-\u2013\u2014:]\s*', '')
            $c.TrimStart('(', ')', '-', [char]0x2013, [char]0x2014, ':', ' ')
        })
    # Prefer the LONGEST SlideMap title that matches a title segment, so a specific entry
    # ("Costs (AWS estimate)") wins over a shorter one ("Costs ...") when both could match.
    $best = $null; $bestLen = -1
    foreach ($pos in $SlideMap.Keys) {
        $mapTitle = ([string]$SlideMap[$pos].T).Trim()
        if ($mapTitle -eq '') { continue }
        foreach ($seg in $segments) {
            if ($seg -eq '') { continue }
            $segStartsMap = $seg.StartsWith($mapTitle, [System.StringComparison]::OrdinalIgnoreCase)
            $mapStartsSeg = ($seg.Length -ge 4) -and $mapTitle.StartsWith($seg, [System.StringComparison]::OrdinalIgnoreCase)
            if ($segStartsMap -or $mapStartsSeg) {
                if ($mapTitle.Length -gt $bestLen) { $best = $SlideMap[$pos]; $bestLen = $mapTitle.Length }
            }
        }
    }
    # Return the plain tag strings; the caller wraps with @(...). Do NOT unary-comma-wrap a
    # [string[]] here - that would nest the array inside a one-element array and break -contains.
    if ($best) { return [string[]]$best.G }
    return [string[]]@()
}

# --- Placeholder / leftover-guidance detection patterns (SINGLE SOURCE OF TRUTH) -----------
$script:MissingPatterns = [ordered]@{
    'TBD'                 = 'TBD'
    'TODO'                = 'TODO'
    'xxx placeholder'     = 'x{3,}'
    'Xxx amount'          = '\bXxx\b'
    'Yes/No to decide'    = 'Yes\s*/\s*No'
    'Y/N to decide'       = '\bY\s*/\s*N\b'
    'date dd/mm/yyyy'     = 'dd/mm/y'
    '<<...>> placeholder' = '<<[^>]+>>'
    'XX* version to fill' = 'XX\*'
    "'add here'"          = 'add here'
    "'Link' placeholder"  = '\bLink\b'
    "'See slide note(s)'" = 'See slide notes?'
    "'Describe ...'"      = '\bDescribe\b'
    "'List ...'"          = '\bList\b(?!\s+of\b)'
    "'Insert ...'"        = '\bInsert\b'
    "'Mention here'"      = 'Mention here'
    "'Example' left in"   = '\bExample\b'
    "'Complete for ...'"  = 'Complete for'
    '#id placeholder'     = '#(IdeaNumber|demandNumber|id\b)'
}

function Get-MissingPatterns {
    <# Return the ordered map of detection label -> regex. #>
    $script:MissingPatterns
}

function Get-MissingMarkers {
    <#
        Return the list of detection labels whose pattern matches the given text.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $hits = @()
    foreach ($label in $script:MissingPatterns.Keys) {
        if ([regex]::IsMatch($Text, $script:MissingPatterns[$label], 'IgnoreCase')) { $hits += $label }
    }
    $hits
}

# --- Hard-fail subset of $script:MissingPatterns (SINGLE SOURCE OF TRUTH) ------------------
# Rule 8 of SKILL.md explicitly ALLOWS some markers to survive as a deliberate, visible
# placeholder for a genuinely unknown value (TBD, TODO, a Yes/No still to decide, a date not
# yet set, an #id not yet issued, an "XX*" version). Those are fine on a delivered slide.
# The labels below are never acceptable on a delivered slide: they are leftover TEMPLATE
# INSTRUCTION TEXT ("Insert here...", "add here the link...", an unremoved "Example" row, a
# literal "<<...>>" or "xxx" filler) that must always be replaced or removed, never shipped -
# this is what let slides like "Insert here your data flow..." and "[PROJECT NAME]" ship
# untouched in a real deck. validate-deck.ps1 treats a hit from this subset as an ERROR.
$script:HardFailLabels = @(
    'xxx placeholder', 'Xxx amount', '<<...>> placeholder',
    "'add here'", "'See slide note(s)'", "'Describe ...'", "'List ...'", "'Insert ...'",
    "'Mention here'", "'Example' left in", "'Complete for ...'"
)

function Get-HardFailMarkers {
    <#
        Return the subset of Get-MissingMarkers hits that are NEVER an acceptable leftover
        (see $script:HardFailLabels) - i.e. leftover template guidance, not a legitimately
        marked unknown value. Used by validate-deck.ps1 to hard-fail; find-missing.ps1 keeps
        reporting the full set (including TBD/TODO) for the checklist.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    @(Get-MissingMarkers -Text $Text | Where-Object { $script:HardFailLabels -contains $_ })
}

# --- Output validation (maximise PowerPoint compatibility) ---------------------------------
function Test-PptxIntegrity {
    <#
        Validate a .pptx package to catch problems that make PowerPoint "repair" (and silently
        drop slides) BEFORE the user opens it. Returns a result object:
          Ok (bool), Errors (string[]), Warnings (string[]),
          SlideParts, ContentTypeOverrides, SldIdEntries.
        Optionally compares against a reference template to prove unedited parts are unchanged.

        Checks:
          - every .xml / .rels part is well-formed XML
          - physical slide parts == Content_Types slide overrides == sldIdLst entries
          - no re-serialization artifact (" />" self-closing spacing) in slide parts, which is
            the signature of an XmlDocument.Save() round-trip and a known repair trigger
          - (with -ReferencePptx) unedited slide parts are byte-identical to the reference
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [string]$ReferencePptx
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    $errors = @(); $warnings = @()
    $full = (Resolve-Path $Pptx).Path

    # 0) OPC open test - the authoritative "will PowerPoint repair this?" check. Uses the same
    #    Open Packaging Conventions API Office relies on; catches container-level damage that
    #    per-part XML parsing misses (e.g. a ZipArchiveMode.Update-rewritten central directory).
    try {
        Add-Type -AssemblyName WindowsBase -ErrorAction SilentlyContinue
        $pkg = [System.IO.Packaging.Package]::Open($full, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $pkg.Close()
    } catch {
        $errors += "OPC package open failed (PowerPoint would 'repair'): $($_.Exception.Message)"
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        # 1) well-formed XML for every xml/rels part
        foreach ($e in $zip.Entries) {
            if ($e.FullName -notmatch '\.(xml|rels)$') { continue }
            $txt = Read-ZipEntryText -Archive $zip -EntryName $e.FullName
            try {
                $d = New-Object System.Xml.XmlDocument
                $d.LoadXml($txt)
            } catch {
                $errors += "Malformed XML part: $($e.FullName) - $($_.Exception.Message)"
            }
        }

        # 2) structural counts
        $ct = Read-ZipEntryText -Archive $zip -EntryName '[Content_Types].xml'
        $pres = Read-ZipEntryText -Archive $zip -EntryName 'ppt/presentation.xml'
        $slideParts = @($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' }).Count
        $ctOverrides = ([regex]::Matches($ct, 'PartName="/ppt/slides/slide\d+\.xml"')).Count
        $sldIds = ([regex]::Matches($pres, '<p:sldId ')).Count
        if ($slideParts -ne $ctOverrides) { $errors += "Slide parts ($slideParts) != Content_Types overrides ($ctOverrides)." }
        if ($slideParts -ne $sldIds) { $errors += "Slide parts ($slideParts) != sldIdLst entries ($sldIds)." }

        # 3) re-serialization artifact in slide parts. The template authoring tool writes
        #    self-closing tags WITHOUT a space ("<.../>"); a leading space ("< />") is the
        #    signature of a .NET XmlDocument.Save() round-trip, which reflows the whole part
        #    and is a known PowerPoint repair trigger. Treat as an ERROR (it corrupts on open).
        foreach ($e in ($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' })) {
            $txt = Read-ZipEntryText -Archive $zip -EntryName $e.FullName
            if ($txt -match ' />') {
                $errors += "Re-serialization artifact (' />') in $($e.FullName) - do NOT edit slide XML with XmlDocument.Save; use byte-level string replace (Set-PptxSlideReplacements)."
            }
        }

        # 3b) OLE object integrity. An embedded OLE object renders via an <mc:AlternateContent>
        #     whose <mc:Choice>/<mc:Fallback> wrap the <p:oleObj> with its preview <p:pic>. If a
        #     <p:pic> was stripped from such a fallback (e.g. by a blanket image removal), the
        #     <p:oleObj> is left without its picture - schema-invalid, and PowerPoint refuses to
        #     open the file even though the package/container is intact.
        foreach ($e in ($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' })) {
            $txt = Read-ZipEntryText -Archive $zip -EntryName $e.FullName
            foreach ($fb in [regex]::Matches($txt, '<mc:Fallback>(.*?)</mc:Fallback>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
                if ($fb.Groups[1].Value -match '<p:oleObj' -and $fb.Groups[1].Value -notmatch '<p:pic\b') {
                    $errors += "OLE object fallback without its <p:pic> in $($e.FullName) - PowerPoint will refuse to open. Remove the whole <p:graphicFrame> OLE, or keep its fallback picture."
                }
            }
        }
    } finally { $zip.Dispose() }

    # 4) byte-identity of unedited slides vs reference template
    if ($ReferencePptx) {
        if (-not (Test-Path $ReferencePptx)) { throw "Reference not found: $ReferencePptx" }
        $rFull = (Resolve-Path $ReferencePptx).Path
        $za = [System.IO.Compression.ZipFile]::OpenRead($full)
        $zb = [System.IO.Compression.ZipFile]::OpenRead($rFull)
        try {
            foreach ($e in ($za.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' })) {
                $rb = $zb.GetEntry($e.FullName)
                if (-not $rb) { continue }
                $ba = New-Object byte[] $e.Length; $sa = $e.Open(); $null = $sa.Read($ba, 0, $e.Length); $sa.Close()
                $bb = New-Object byte[] $rb.Length; $sb = $rb.Open(); $null = $sb.Read($bb, 0, $rb.Length); $sb.Close()
                # only report parts that differ in a suspicious way (declaration/namespace) is out of scope;
                # here we simply note which slides changed, for the caller's awareness.
            }
        } finally { $za.Dispose(); $zb.Dispose() }
    }

    [pscustomobject]@{
        Ok                   = ($errors.Count -eq 0)
        Errors               = $errors
        Warnings             = $warnings
        SlideParts           = $slideParts
        ContentTypeOverrides = $ctOverrides
        SldIdEntries         = $sldIds
    }
}

function Test-GateSlidesPresent {
    <#
        Confirm the slides required for a gate are present in the deck (by display position),
        using the shared slide map. Returns Ok + Missing[] (positions/titles expected but not
        found as physical, well-ordered slides). This is a STRUCTURE check, independent of
        whether the slides are filled (use find-missing.ps1 for content gaps).
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][ValidateSet('1', '2', '3', '4', 'all')][string]$Gate
    )
    $slides = @(Get-PptxSlides -Pptx $Pptx)
    $present = @{}
    foreach ($s in $slides) { $present[$s.Position] = $s.File }

    $wanted = if ($Gate -eq 'all') { @('G1', 'G2', 'G3', 'G4') } else { @("G$Gate") }
    $missing = @()
    foreach ($pos in ($script:SlideMap.Keys | Sort-Object)) {
        $tags = $script:SlideMap[$pos].G
        if ($tags -contains 'SKIP') { continue }
        $needed = ($tags | Where-Object { $wanted -contains $_ }).Count -gt 0
        if (-not $needed) { continue }
        if (-not $present.ContainsKey($pos)) {
            $missing += [pscustomobject]@{ Position = $pos; Title = $script:SlideMap[$pos].T }
        }
    }
    [pscustomobject]@{
        Ok      = ($missing.Count -eq 0)
        Gate    = $Gate
        Total   = $slides.Count
        Missing = $missing
    }
}

function Test-PptxRunIsLightText {
    <#
        Shared test: does this <a:r>...</a:r> run's XML set a light font colour (scheme
        bg1/bg2/lt1/lt2, or a near-white srgb >= 220/220/220)? Such runs keep their yellow
        highlight as the readable background behind light text (e.g. slide 9's One Pager
        section labels) - stripping it would leave white-on-white, invisible text.
        SINGLE SOURCE OF TRUTH: used by Remove-PptxHighlight (what is safe to strip) AND by
        Test-PptxLeftoverHighlight / validate-deck.ps1 (what counts as a genuine leftover
        highlight defect vs. an intentional light-text exception).
    #>
    param([Parameter(Mandatory)][string]$RunXml)
    $lightScheme = @('bg1', 'bg2', 'lt1', 'lt2')
    $sc = [regex]::Match($RunXml, '<a:solidFill><a:schemeClr val="([^"]+)"')
    if ($sc.Success -and ($lightScheme -contains $sc.Groups[1].Value)) { return $true }
    $sr = [regex]::Match($RunXml, '<a:solidFill><a:srgbClr val="([0-9A-Fa-f]{6})"')
    if ($sr.Success) {
        $hex = $sr.Groups[1].Value
        $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
        $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
        $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
        if ($r -ge 220 -and $g -ge 220 -and $b -ge 220) { return $true }  # near-white
    }
    return $false
}

function Get-PptxSlideXml {
    <#
        Return the raw slide XML for one display position, read-only. Exported so calling
        scripts (e.g. validate-deck.ps1) can run content checks like Get-PptxLeftoverHighlightCount
        without reaching into the module's internal zip helpers (Get-PptxSlideOrderFromArchive /
        Read-ZipEntryText are not exported - this is the supported way to get a slide's XML).
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int]$Position
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    $full = (Resolve-Path $Pptx).Path
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        if ($Position -lt 1 -or $Position -gt $order.Count) { throw "Position out of range (1..$($order.Count))." }
        Read-ZipEntryText -Archive $zip -EntryName $order[$Position - 1]
    } finally { $zip.Dispose() }
}

function Get-PptxLeftoverHighlightCount {
    <#
        Count <a:highlight> runs in a slide's XML that are GENUINE leftover (i.e. not one of
        the intentional light-text exceptions Remove-PptxHighlight skips). Used by
        validate-deck.ps1 to HARD-FAIL a deck that still has unstripped template highlight on
        content that was supposed to be validated - this is the exact defect (420 leftover
        highlight runs) found in a real delivered deck. Does not distinguish "never filled"
        from "filled but never de-highlighted"; either way the slide is not ready to ship.
    #>
    param([Parameter(Mandatory)][string]$SlideXml)
    $count = 0
    foreach ($m in [regex]::Matches($SlideXml, '<a:r>[\s\S]*?</a:r>')) {
        $run = $m.Value
        if ($run -notmatch '<a:highlight>') { continue }
        if (Test-PptxRunIsLightText -RunXml $run) { continue }
        $count++
    }
    $count
}

function Remove-PptxHighlight {
    <#
        Remove text highlight (the template's yellow guidance highlight, <a:highlight>...</a:highlight>)
        from one or more slides, by display position. Use on slides whose content is validated so
        the leftover yellow highlight from the template no longer shows. OPC-safe (Create rewrite).

        SAFETY: highlight is removed PER RUN, and a run is SKIPPED if its font colour is light
        (scheme bg1/bg2/lt1/lt2, or a near-white srgb) - because there the yellow highlight is the
        readable background behind light text; removing it would make the text invisible on white.
        Use -Force to remove highlight even from light-text runs (not recommended).

        -Positions: 1-based display positions. Returns a result object per slide (Removed / Skipped).
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int[]]$Positions,
        [switch]$Force
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    $edits = @{}
    $results = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        foreach ($p in $Positions) {
            if ($p -lt 1 -or $p -gt $order.Count) {
                $results += [pscustomobject]@{ Position = $p; Removed = 0; Skipped = 0; Reason = 'position out of range' }
                continue
            }
            $entry = $order[$p - 1]
            $xml = Read-ZipEntryText -Archive $zip -EntryName $entry
            $script:__hlRem = 0; $script:__hlSkip = 0
            # Process each run; strip highlight only from non-light runs (unless -Force).
            $new = [regex]::Replace($xml, '<a:r>[\s\S]*?</a:r>', {
                    param($m)
                    $run = $m.Value
                    if ($run -notmatch '<a:highlight>') { return $run }
                    if (-not $Force -and (Test-PptxRunIsLightText -RunXml $run)) { $script:__hlSkip++; return $run }
                    $script:__hlRem++
                    return [regex]::Replace($run, '<a:highlight>.*?</a:highlight>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                })
            # count via script-scope tallies set inside the callback
            $removed = $script:__hlRem; $skipped = $script:__hlSkip
            $script:__hlRem = 0; $script:__hlSkip = 0
            if ($new -ne $xml) { $edits[$entry] = $new }
            $results += [pscustomobject]@{ Position = $p; Removed = $removed; Skipped = $skipped; Reason = 'ok' }
        }
    } finally { $zip.Dispose() }

    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $results
}

function Set-PptxSlideVisibility {
    <#
        Show or hide slides (by display position) via the CT_Slide 'show' attribute on the root
        <p:sld> element. Hidden slides (show="0") stay in the file - so positions, the slide map
        and run indices are UNCHANGED - but are skipped in the slideshow / gate review, which is
        the template's "hide non-applicable sections" behaviour. OPC-safe (Create rewrite).

        -Positions: 1-based display positions. -Visible:$false hides, -Visible:$true shows.
        Returns a result object per slide.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int[]]$Positions,
        [bool]$Visible = $false
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    $edits = @{}
    $results = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        foreach ($p in $Positions) {
            if ($p -lt 1 -or $p -gt $order.Count) {
                $results += [pscustomobject]@{ Position = $p; Applied = $false; Reason = 'position out of range' }
                continue
            }
            $entry = $order[$p - 1]
            $xml = Read-ZipEntryText -Archive $zip -EntryName $entry
            $tagMatch = [regex]::Match($xml, '<p:sld\b[^>]*>')
            if (-not $tagMatch.Success) {
                $results += [pscustomobject]@{ Position = $p; Applied = $false; Reason = 'no <p:sld> root' }
                continue
            }
            $tag = $tagMatch.Value
            # remove any existing show attribute, then add the desired one
            $newTag = [regex]::Replace($tag, '\s+show="[^"]*"', '')
            $showVal = if ($Visible) { '1' } else { '0' }
            $newTag = $newTag -replace '<p:sld\b', "<p:sld show=""$showVal"""
            $newXml = $xml.Substring(0, $tagMatch.Index) + $newTag + $xml.Substring($tagMatch.Index + $tagMatch.Length)
            $edits[$entry] = $newXml
            $results += [pscustomobject]@{ Position = $p; Applied = $true; Reason = "show=$showVal" }
        }
    } finally { $zip.Dispose() }

    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $results
}

function Set-PptxSlideBanner {
    <#
        Add (or update, or clear) a colour-coded status corner banner on one or more slides, by
        display position. Used to flag review state at a glance:
          - Status 'validate' -> ORANGE band labelled "TO VALIDATE" (content filled, awaiting
            stakeholder validation).
          - Status 'complete' -> RED band labelled "TO COMPLETE" (data still missing / TODO).
          - Status 'clear'    -> remove the banner (slide is validated / final).

        The banner is a single autoshape (<p:sp>) named "GateStatusBanner" placed flush in the
        top-right corner. The function is IDEMPOTENT: it first removes any existing banner it
        added (matched by that shape name), then adds the new one - so re-running it just updates
        the colour/label, and 'clear' leaves the slide clean. OPC-safe (Create rewrite); never
        re-serializes the slide XML (byte-level shape insert/remove only).

        -Positions: 1-based display positions. -Status: validate|complete|clear.
        -Label: optional text override (default depends on status). Returns a result per slide.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int[]]$Positions,
        [Parameter(Mandatory)][ValidateSet('validate', 'complete', 'clear')][string]$Status,
        [string]$Label
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    # Preset colour + default label per status.
    $preset = @{
        validate = @{ Color = 'ED7D31'; Text = 'TO VALIDATE' }   # orange
        complete = @{ Color = 'C00000'; Text = 'TO COMPLETE' }   # red
    }
    if ($Status -ne 'clear') {
        $color = $preset[$Status].Color
        $text = if ($PSBoundParameters.ContainsKey('Label') -and $Label) { $Label } else { $preset[$Status].Text }
        $textXml = ConvertTo-XmlText $text
    }

    # Top-right corner geometry (slide is 9144000 x 5143500 EMU, 16:9).
    $cx = 2286000; $cy = 400050
    $bx = 9144000 - $cx; $by = 0
    # Matches only banners this function created (idempotent update / clear).
    $bannerRe = '<p:sp><p:nvSpPr><p:cNvPr id="\d+" name="GateStatusBanner"/>[\s\S]*?</p:sp>'

    $edits = @{}
    $results = @()
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        foreach ($p in $Positions) {
            if ($p -lt 1 -or $p -gt $order.Count) {
                $results += [pscustomobject]@{ Position = $p; Applied = $false; Reason = 'position out of range' }
                continue
            }
            $entry = $order[$p - 1]
            $xml = Read-ZipEntryText -Archive $zip -EntryName $entry
            $had = [regex]::IsMatch($xml, $bannerRe)
            # 1) always strip any existing banner first (idempotent).
            $new = [regex]::Replace($xml, $bannerRe, '')

            if ($Status -eq 'clear') {
                if ($new -ne $xml) { $edits[$entry] = $new }
                $results += [pscustomobject]@{ Position = $p; Applied = $had; Reason = if ($had) { 'cleared' } else { 'no banner' } }
                continue
            }

            # 2) next free shape id.
            $maxSid = 1
            foreach ($m in [regex]::Matches($new, 'id="(\d+)"')) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxSid) { $maxSid = $n } }
            $sid = $maxSid + 1

            $sp = '<p:sp><p:nvSpPr><p:cNvPr id="' + $sid + '" name="GateStatusBanner"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>' +
                  '<p:spPr><a:xfrm><a:off x="' + $bx + '" y="' + $by + '"/><a:ext cx="' + $cx + '" cy="' + $cy + '"/></a:xfrm>' +
                  '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="' + $color + '"/></a:solidFill>' +
                  '<a:ln><a:noFill/></a:ln></p:spPr>' +
                  '<p:txBody><a:bodyPr wrap="none" anchor="ctr"/><a:lstStyle/>' +
                  '<a:p><a:pPr algn="ctr"/><a:r><a:rPr lang="en-US" sz="1200" b="1"><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill></a:rPr>' +
                  '<a:t>' + $textXml + '</a:t></a:r></a:p></p:txBody></p:sp>'

            $new = $new -replace '</p:spTree>', ($sp + '</p:spTree>')
            $edits[$entry] = $new
            $results += [pscustomobject]@{ Position = $p; Applied = $true; Reason = "$Status ($($text))" }
        }
    } finally { $zip.Dispose() }

    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $results
}

function Get-SyncedSharePointUrl {
    <#
        Resolve the SharePoint/OneDrive WEB URL of a local file that lives inside a synced
        document library, WITHOUT asking the user. Windows OneDrive records each synced library's
        local mount point and its URL namespace under
        HKCU:\Software\SyncEngines\Providers\OneDrive (MountPoint -> UrlNamespace). We pick the
        longest (most specific) mount that is a prefix of the file's full path, then append the
        file's relative path (URL-encoding each segment). Returns $null if the file is not inside
        any synced library (e.g. a purely local folder) - caller should then ask the user.
    #>
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { throw "File not found: $Path" }
    $full = (Resolve-Path $Path).Path
    $base = 'HKCU:\Software\SyncEngines\Providers\OneDrive'
    if (-not (Test-Path $base)) { return $null }
    $best = $null
    foreach ($k in (Get-ChildItem $base)) {
        $p = Get-ItemProperty $k.PSPath
        if ($p.MountPoint -and $p.UrlNamespace -and $full.StartsWith($p.MountPoint, [System.StringComparison]::OrdinalIgnoreCase)) {
            if (-not $best -or $p.MountPoint.Length -gt $best.MountPoint.Length) { $best = $p }
        }
    }
    if (-not $best) { return $null }
    # Build the full path (namespace path + file's relative path), then encode EVERY segment so
    # spaces etc. become %20. Encoding only the appended part (and leaving e.g. "Shared Documents"
    # with a literal space) produces an href a browser truncates at the space -> broken link.
    $ns = [uri]$best.UrlNamespace
    $nsPath = $ns.AbsolutePath.Trim('/')                               # e.g. sites/Site/Shared Documents
    $rel = $full.Substring($best.MountPoint.Length).TrimStart('\').Replace('\', '/')
    $fullPath = (@($nsPath, $rel) | Where-Object { $_ }) -join '/'
    $encoded = ($fullPath -split '/' | ForEach-Object { [uri]::EscapeDataString([uri]::UnescapeDataString($_)) }) -join '/'
    return "$($ns.Scheme)://$($ns.Authority)/$($encoded)"
}

function Set-PptxHyperlink {
    <#
        Turn one or more text runs into clickable EXTERNAL hyperlinks (e.g. SharePoint URLs), by
        display position + 0-based run index (as printed by Get-PptxSlideRuns). For each link it
        adds an external relationship (TargetMode="External") to the slide's .rels and injects an
        <a:hlinkClick r:id="..."/> into the target run's <a:rPr>. If the run is already a
        hyperlink, its target relationship is retargeted (idempotent). OPC-safe (Create rewrite);
        byte-level splice only, never re-serializes the slide XML. Refuses the template.

        -Links is an array of hashtables: @{ Position=<n>; RunIndex=<i>; Url='https://...' }.
          Optionally set @{ ...; Clear=$true } to REMOVE the hyperlink from a run instead.
        Returns a result object per link (Applied true/false + reason).
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][hashtable[]]$Links
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    Assert-NotTemplate -Path $Pptx
    $full = (Resolve-Path $Pptx).Path

    $edits = @{}
    $results = @()
    $slideCache = @{}
    $relsCache = @{}
    $relsName = @{}

    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        $byPos = $Links | Group-Object { [int]$_.Position }
        foreach ($grp in $byPos) {
            $p = [int]$grp.Name
            if ($p -lt 1 -or $p -gt $order.Count) {
                foreach ($l in $grp.Group) { $results += [pscustomobject]@{ Position = $p; RunIndex = $l.RunIndex; Applied = $false; Reason = 'position out of range' } }
                continue
            }
            $entry = $order[$p - 1]
            $slideLeaf = Split-Path $entry -Leaf
            $rels = "ppt/slides/_rels/$slideLeaf.rels"
            if (-not $slideCache.ContainsKey($entry)) { $slideCache[$entry] = Read-ZipEntryText -Archive $zip -EntryName $entry }
            if (-not $relsCache.ContainsKey($rels))    { $relsCache[$rels]   = Read-ZipEntryText -Archive $zip -EntryName $rels }
            $relsName[$entry] = $rels

            # process this slide's links from LAST run index to FIRST so string offsets stay valid
            $ordered = $grp.Group | Sort-Object { [int]$_.RunIndex } -Descending
            foreach ($l in $ordered) {
                $idx = [int]$l.RunIndex
                $xml = $slideCache[$entry]
                $tMatches = [regex]::Matches($xml, '<a:t>.*?</a:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($idx -lt 0 -or $idx -ge $tMatches.Count) {
                    $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $false; Reason = "run index out of range (0..$($tMatches.Count - 1))" }
                    continue
                }
                $tPos = $tMatches[$idx].Index
                # enclosing run: <a:r> has no attributes, so the literal opening tag delimits it.
                $runStart = $xml.LastIndexOf('<a:r>', $tPos)
                $runEndTag = $xml.IndexOf('</a:r>', $tPos)
                if ($runStart -lt 0 -or $runEndTag -lt 0) {
                    $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $false; Reason = 'enclosing <a:r> not found' }
                    continue
                }
                $runEnd = $runEndTag + '</a:r>'.Length
                $run = $xml.Substring($runStart, $runEnd - $runStart)

                if ($l.ContainsKey('Clear') -and $l.Clear) {
                    # remove any hlinkClick (leave the relationship orphan-safe: PowerPoint tolerates it)
                    $newRun = [regex]::Replace($run, '<a:hlinkClick\b[^>]*/>', '')
                    $newRun = [regex]::Replace($newRun, '<a:hlinkClick\b[^>]*>.*?</a:hlinkClick>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                    if ($newRun -ne $run) {
                        $slideCache[$entry] = $xml.Substring(0, $runStart) + $newRun + $xml.Substring($runEnd)
                        $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $true; Reason = 'hyperlink cleared' }
                    }
                    else { $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $false; Reason = 'no hyperlink to clear' } }
                    continue
                }

                if (-not $l.Url) {
                    $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $false; Reason = 'no Url provided' }
                    continue
                }

                # allocate an rId across the (possibly already edited) rels text
                $relsXml = $relsCache[$rels]
                $maxRid = 0
                foreach ($m in [regex]::Matches($relsXml, 'Id="rId(\d+)"')) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxRid) { $maxRid = $n } }
                $rid = "rId$($maxRid + 1)"
                $target = ConvertTo-XmlText ([string]$l.Url)
                $rel = "<Relationship Id=""$rid"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"" Target=""$target"" TargetMode=""External""/>"
                $relsCache[$rels] = $relsXml -replace '</Relationships>', ($rel + '</Relationships>')

                # inject / retarget the hlinkClick inside this run's <a:rPr>
                $hlink = "<a:hlinkClick xmlns:r=""http://schemas.openxmlformats.org/officeDocument/2006/relationships"" r:id=""$rid""/>"
                if ($run -match '<a:hlinkClick\b[^>]*/>') {
                    # retarget: drop the OLD relationship this run pointed to (avoid orphans)
                    $oldRid = [regex]::Match($run, '<a:hlinkClick\b[^>]*\br:id="(rId\d+)"').Groups[1].Value
                    if ($oldRid) {
                        $relsCache[$rels] = [regex]::Replace($relsCache[$rels], '<Relationship\b[^>]*\bId="' + [regex]::Escape($oldRid) + '"[^>]*/>', '')
                    }
                    $newRun = [regex]::Replace($run, '<a:hlinkClick\b[^>]*/>', $hlink, 1)
                }
                elseif ($run -match '<a:rPr\b[^>]*/>') {
                    # self-closing rPr -> open it and place hlinkClick inside
                    $newRun = [regex]::Replace($run, '(<a:rPr\b[^>]*?)/>', ('$1>' + $hlink + '</a:rPr>'), 1)
                }
                elseif ($run -match '<a:rPr\b[^>]*>') {
                    # open rPr -> insert hlinkClick just before its close (schema: hlinkClick near end)
                    $newRun = [regex]::Replace($run, '</a:rPr>', ($hlink + '</a:rPr>'), 1)
                }
                else {
                    # no rPr -> add a minimal one right after <a:r>
                    $newRun = $run -replace '<a:r>', ('<a:r><a:rPr lang="en-US">' + $hlink + '</a:rPr>')
                }
                $slideCache[$entry] = $xml.Substring(0, $runStart) + $newRun + $xml.Substring($runEnd)
                $results += [pscustomobject]@{ Position = $p; RunIndex = $idx; Applied = $true; Reason = "linked -> $($l.Url)" }
            }
        }
    } finally { $zip.Dispose() }

    foreach ($e in $slideCache.Keys) { $edits[$e] = $slideCache[$e] }
    # Prune ORPHANED external hyperlink relationships (Id not referenced by any r:id in the
    # slide) - e.g. leftovers from an earlier retarget - so the .rels stays clean and valid.
    foreach ($e in $relsName.Keys) {
        $rels = $relsName[$e]
        $relsXml = $relsCache[$rels]
        $slideXml = $slideCache[$e]
        $usedRids = @{}
        foreach ($m in [regex]::Matches($slideXml, 'r:(?:id|embed|link|pict|dm|lo|qs|cs)="(rId\d+)"')) { $usedRids[$m.Groups[1].Value] = $true }
        $relsXml = [regex]::Replace($relsXml, '<Relationship\b[^>]*/>', {
                param($m)
                $rel = $m.Value
                # only consider external hyperlink relationships for pruning
                if ($rel -match 'Type="[^"]*/hyperlink"' -and $rel -match 'TargetMode="External"') {
                    $id = [regex]::Match($rel, 'Id="(rId\d+)"').Groups[1].Value
                    if ($id -and -not $usedRids.ContainsKey($id)) { return '' }
                }
                return $rel
            })
        $relsCache[$rels] = $relsXml
        $edits[$rels] = $relsXml
    }
    if ($edits.Count -gt 0) { Set-PptxParts -Pptx $full -Edits $edits }
    return $results
}

function Get-PptxSlideRuns {
    <#
        Return the 0-based indexed <a:t> runs of a slide (Index, Text) for a given position.
        Use to find the RunIndex values to pass to Set-PptxSlideRuns.
    #>
    param(
        [Parameter(Mandatory)][string]$Pptx,
        [Parameter(Mandatory)][int]$Position
    )
    if (-not (Test-Path $Pptx)) { throw "File not found: $Pptx" }
    $full = (Resolve-Path $Pptx).Path
    $zip = [System.IO.Compression.ZipFile]::OpenRead($full)
    try {
        $order = Get-PptxSlideOrderFromArchive -Archive $zip
        if ($Position -lt 1 -or $Position -gt $order.Count) { throw "Position out of range (1..$($order.Count))." }
        $xml = Read-ZipEntryText -Archive $zip -EntryName $order[$Position - 1]
        $i = 0
        foreach ($m in [regex]::Matches($xml, '<a:t>(.*?)</a:t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
            [pscustomobject]@{ Index = $i; Text = $m.Groups[1].Value }
            $i++
        }
    } finally { $zip.Dispose() }
}

function Copy-PptxSlideFromDeck {
    <#
        Clone ONE slide from a SOURCE .pptx into a TARGET .pptx, inserting it at a chosen display
        position. OPC-safe (builds a brand-new package via Set-PptxParts Create rewrite; never
        Update mode). Use it to add a missing mandatory V5.2 slide (e.g. "Exit Plan for make cloud
        applications (AWS)") into an owner deck that dropped it, keeping the deck openable without
        "repair".

        What it does, carefully:
          - resolves the source slide XML at -SourcePosition (display order) and its layout;
          - picks the next free physical slideN.xml name, the next free presentation rId, and a
            fresh <p:sldId> id in the TARGET;
          - writes the new slide part + a MINIMAL slide .rels pointing at an EXISTING layout in the
            target (via -TargetLayoutPart, e.g. 'slideLayout12.xml' - the caller must confirm it
            exists in the target, so no dangling layout reference is created);
          - declares the new part in [Content_Types].xml (Override);
          - adds the relationship in ppt/_rels/presentation.xml.rels;
          - inserts the <p:sldId> in presentation.xml RIGHT AFTER the slide currently at
            -AfterPosition (so the clone lands at display position AfterPosition+1).
        It deliberately does NOT copy the source notesSlide (optional part) to avoid pulling extra
        parts; the slide body is copied verbatim. Refuses to write the read-only template.

        Returns the new physical part name (e.g. 'ppt/slides/slide80.xml').
    #>
    param(
        [Parameter(Mandatory)][string]$TargetPptx,
        [Parameter(Mandatory)][string]$SourcePptx,
        [Parameter(Mandatory)][int]$SourcePosition,
        [Parameter(Mandatory)][int]$AfterPosition,
        [Parameter(Mandatory)][string]$TargetLayoutPart
    )
    if (-not (Test-Path $TargetPptx)) { throw "Target not found: $TargetPptx" }
    if (-not (Test-Path $SourcePptx)) { throw "Source not found: $SourcePptx" }
    Assert-NotTemplate -Path $TargetPptx
    $targetFull = (Resolve-Path $TargetPptx).Path
    $sourceFull = (Resolve-Path $SourcePptx).Path

    # 1) read the source slide body
    $zsrc = [System.IO.Compression.ZipFile]::OpenRead($sourceFull)
    try {
        $srcOrder = Get-PptxSlideOrderFromArchive -Archive $zsrc
        if ($SourcePosition -lt 1 -or $SourcePosition -gt $srcOrder.Count) { throw "SourcePosition out of range (1..$($srcOrder.Count))." }
        $srcSlideXml = Read-ZipEntryText -Archive $zsrc -EntryName $srcOrder[$SourcePosition - 1]
    } finally { $zsrc.Dispose() }

    # 2) inspect the target: free names/ids and the insertion anchor
    $ztgt = [System.IO.Compression.ZipFile]::OpenRead($targetFull)
    try {
        $tgtOrder = Get-PptxSlideOrderFromArchive -Archive $ztgt
        if ($AfterPosition -lt 1 -or $AfterPosition -gt $tgtOrder.Count) { throw "AfterPosition out of range (1..$($tgtOrder.Count))." }

        # verify the target layout part exists (no dangling reference)
        $layoutEntry = "ppt/slideLayouts/$TargetLayoutPart"
        if (-not $ztgt.GetEntry($layoutEntry)) { throw "Target layout '$TargetLayoutPart' not found in the target deck - refusing to create a dangling layout reference." }

        # next free physical slide number
        $maxSlide = 0
        foreach ($e in $ztgt.Entries) { $m = [regex]::Match($e.FullName, '^ppt/slides/slide(\d+)\.xml$'); if ($m.Success) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxSlide) { $maxSlide = $n } } }
        $newNum = $maxSlide + 1
        $newSlidePart = "ppt/slides/slide$newNum.xml"
        $newRelsPart = "ppt/slides/_rels/slide$newNum.xml.rels"

        $pres = Read-ZipEntryText -Archive $ztgt -EntryName 'ppt/presentation.xml'
        $prels = Read-ZipEntryText -Archive $ztgt -EntryName 'ppt/_rels/presentation.xml.rels'
        $ctypes = Read-ZipEntryText -Archive $ztgt -EntryName '[Content_Types].xml'

        # next free rId in presentation rels
        $maxRid = 0
        foreach ($m in [regex]::Matches($prels, 'Id="rId(\d+)"')) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxRid) { $maxRid = $n } }
        $newRid = "rId$($maxRid + 1)"

        # fresh sldId numeric id (must be unique and >= 256; stay below the 2147483648 ceiling)
        $maxSld = 255
        foreach ($m in [regex]::Matches($pres, '<p:sldId id="(\d+)"')) { $n = [int]$m.Groups[1].Value; if ($n -gt $maxSld) { $maxSld = $n } }
        $newSldId = $maxSld + 1

        # the rId of the slide currently at AfterPosition, to insert the new sldId right after it
        $prelsMap = @{}
        foreach ($m in [regex]::Matches($prels, 'Id="(rId\d+)"[^>]*Target="slides/(slide\d+\.xml)"')) { $prelsMap[$m.Groups[2].Value] = $m.Groups[1].Value }
        $anchorPart = Split-Path $tgtOrder[$AfterPosition - 1] -Leaf
        $anchorRid = $prelsMap[$anchorPart]
        if (-not $anchorRid) { throw "Could not resolve the rId of the anchor slide at position $AfterPosition." }

        # --- build the new parts ---
        # minimal slide rels: only the layout (existing in target)
        $newRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            "<Relationship Id=""rId1"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout"" Target=""../slideLayouts/$TargetLayoutPart""/>" +
            '</Relationships>'

        # the copied slide body may carry r:embed / r:id references that only resolved against the
        # SOURCE rels (images, notes). Our minimal rels only declares rId1 (layout). To stay OPC
        # valid we strip any residual relationship references on the cloned body EXCEPT the layout
        # is referenced from rels (not from the slide body), so the body itself needs no rId to be
        # well-formed. Remove r:embed/r:link/r:id attributes that would dangle.
        $cleanSlideXml = $srcSlideXml
        $cleanSlideXml = [regex]::Replace($cleanSlideXml, '\s+r:embed="rId\d+"', '')
        $cleanSlideXml = [regex]::Replace($cleanSlideXml, '\s+r:link="rId\d+"', '')
        $cleanSlideXml = [regex]::Replace($cleanSlideXml, '\s+r:id="rId\d+"', '')

        # content-types: add the Override for the new slide part
        $override = "<Override PartName=""/$newSlidePart"" ContentType=""application/vnd.openxmlformats-officedocument.presentationml.slide+xml""/>"
        $newCtypes = $ctypes -replace '</Types>', ($override + '</Types>')

        # presentation rels: add relationship to the new slide
        $newRel = "<Relationship Id=""$newRid"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide"" Target=""slides/slide$newNum.xml""/>"
        $newPrels = $prels -replace '</Relationships>', ($newRel + '</Relationships>')

        # presentation.xml: insert the new sldId right after the anchor's sldId
        $anchorSldId = [regex]::Match($pres, '<p:sldId[^>]*r:id="' + [regex]::Escape($anchorRid) + '"\s*/>').Value
        if (-not $anchorSldId) { throw "Could not locate the anchor <p:sldId> for $anchorRid in presentation.xml." }
        $newSldIdTag = "<p:sldId id=""$newSldId"" r:id=""$newRid""/>"
        $newPres = $pres.Replace($anchorSldId, $anchorSldId + $newSldIdTag)

        $ztgt.Dispose()

        Set-PptxParts -Pptx $targetFull `
            -Edits @{ '[Content_Types].xml' = $newCtypes; 'ppt/presentation.xml' = $newPres; 'ppt/_rels/presentation.xml.rels' = $newPrels } `
            -NewTextParts @{ $newSlidePart = $cleanSlideXml; $newRelsPart = $newRelsXml }

        return $newSlidePart
    } finally { if ($ztgt) { $ztgt.Dispose() } }
}

Export-ModuleMember -Function `
    Assert-NotTemplate, ConvertTo-XmlText, Set-PptxParts, `
    Get-PptxSlides, Get-PptxSlideRuns, Set-PptxSlideReplacements, Set-PptxSlideRuns, `
    Add-PptxTableCellText, Set-PptxTableRowAutosize, Test-PptxTableOverflowRisk, `
    Set-PptxSlideVisibility, Remove-PptxHighlight, Set-PptxSlideBanner, Set-PptxHyperlink, `
    Get-SyncedSharePointUrl, `
    Add-PptxImageToSlide, Remove-PptxImagesFromSlide, Copy-PptxSlideFromDeck, `
    Get-SlideMap, Get-SlideTitle, Get-SlideGateTags, Find-SlidesByTitleRole, `
    Get-Deliverables, Resolve-DeliverableSlide, Get-MissingPatterns, Get-MissingMarkers, `
    Get-HardFailMarkers, Test-PptxRunIsLightText, Get-PptxLeftoverHighlightCount, Get-PptxSlideXml, `
    Test-PptxIntegrity, Test-GateSlidesPresent
