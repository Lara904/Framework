<#
  build-diagrams.ps1 - render a project's .drawio diagrams to PNG and insert them into the
  Architecture Gates deck. Resolves the blocker logged in Suivi_Avancement_ARB_Readiness and
  analysed in Kiro_Drawio_Rendering_Solution.md: Add-PptxImageToSlide (PptxGates.psm1) only
  inserts an already-rendered picture; the missing piece was a working .drawio -> .png step.

  VALIDATED end-to-end 2026-11 (see Kiro_Drawio_Rendering_Solution.md, "Validated recipe"
  section) against the real Forensic-tooling diagrams and deck: draw.io Desktop CLI, run
  headless under Xvfb as root, with two flags the original analysis had not identified -
  without them the export either fails (sandbox) or silently exports the wrong page
  (multi-page .drawio files default to page 0 = the "Versions" cover page, not the diagram):
    - ELECTRON_DISABLE_SANDBOX=1   (Electron refuses to run as root otherwise: "Running as
                                     root without --no-sandbox is not supported")
    - --page-index <n>             (0-based; this skill's .drawio files all put the actual
                                     diagram on page 2, i.e. --page-index 1)
  The project-npm package also named "drawio" (installable via `npx drawio`) is NOT this tool -
  it is an unrelated CSV chart generator that happens to share the name. Do not use it.

  Prerequisites (install once; see the "Runbook prerequisites" section of
  Kiro_Drawio_Rendering_Solution.md for the exact commands):
    - xvfb
    - draw.io Desktop (the .deb from https://github.com/jgraph/drawio-desktop/releases)

  Usage:
    pwsh -File build-diagrams.ps1 -ProjectDir "output/<project_name>" -Project "<project_name>" `
      [-Gate2Slide 42] [-DataflowSlide 33] [-Width 1920]

  Safe to re-run: inserting a diagram first removes that slide's existing top-level pictures
  (Remove-PptxImagesFromSlide) so a re-run replaces rather than stacks images.
#>
param(
    [Parameter(Mandatory)][string]$ProjectDir,
    [Parameter(Mandatory)][string]$Project,
    [int]$Gate2Slide = 42,       # "(Solution X) - Technical Architecture global view"
    [int]$DataflowSlide = 33,    # "Applications Flows technical diagram for Gate 2 or Gate 1 PoC"
    [int]$Width = 1920
)

$ErrorActionPreference = 'Stop'
Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'PptxGates.psm1')).Path -Force

$deck = Join-Path $ProjectDir "${Project}_Architecture_Gates_G2.pptx"
if (-not (Test-Path $deck)) { throw "Deck not found: $deck (run presentation-gates first)" }

$drawioCmd = Get-Command drawio -ErrorAction SilentlyContinue
if (-not $drawioCmd) {
    Write-Warning "draw.io CLI not found on PATH. Install it (see Kiro_Drawio_Rendering_Solution.md 'Runbook prerequisites') or leave the deck's diagram slides with their textual .drawio reference instead of an embedded image - never fabricate one."
    exit 0
}
$haveXvfb = [bool](Get-Command xvfb-run -ErrorAction SilentlyContinue)
if (-not $haveXvfb) {
    Write-Warning "xvfb-run not found on PATH (needed to run draw.io headless). Install xvfb."
    exit 0
}

function Convert-DrawioToPng {
    param([string]$DrawioPath, [string]$OutPng, [int]$PageIndex, [int]$Width)
    $env:ELECTRON_DISABLE_SANDBOX = '1'
    $args = @('-a', 'drawio', '--export', '--format', 'png', '--width', "$Width", '--border', '20',
               '--page-index', "$PageIndex", '--output', $OutPng, $DrawioPath)
    & xvfb-run @args 2>&1 | ForEach-Object { Write-Verbose $_ }   # Electron/dbus/GPU noise on stderr is normal, not a failure signal
    if (-not (Test-Path $OutPng) -or (Get-Item $OutPng).Length -lt 500) {
        throw "drawio export produced no (or an empty) PNG for $DrawioPath - re-run with -Verbose to see the CLI output."
    }
    return $OutPng
}

# Map: source .drawio -> target slide + placement. Diagram page index is 1 (0 = Versions cover
# page) for every .drawio this framework's upstream skills produce (functional-architecture,
# technical-architecture) - confirmed across all 4 diagram files of a real project.
$diagramMap = @(
    @{ Source = Join-Path $ProjectDir "${Project}_technical_architecture_diagram.drawio"; Position = $Gate2Slide
       EmuX = 300000; EmuY = 1450000; EmuCx = 8500000; EmuCy = 3400000 },
    @{ Source = Join-Path $ProjectDir "${Project}_technical_architecture_dataflow.drawio"; Position = $DataflowSlide
       EmuX = 300000; EmuY = 1980000; EmuCx = 8500000; EmuCy = 3050000 }
)

foreach ($entry in $diagramMap) {
    if (-not (Test-Path $entry.Source)) {
        Write-Warning "Drawio source not found, skipping position $($entry.Position): $($entry.Source)"
        continue
    }
    $pngPath = [System.IO.Path]::ChangeExtension($entry.Source, '.png')
    Write-Host "Rendering $($entry.Source) -> $pngPath"
    Convert-DrawioToPng -DrawioPath $entry.Source -OutPng $pngPath -PageIndex 1 -Width $Width | Out-Null

    Write-Host "  Removing any existing top-level picture on slide $($entry.Position)"
    Remove-PptxImagesFromSlide -Pptx $deck -Position $entry.Position

    Write-Host "  Inserting $pngPath into slide $($entry.Position)"
    $mediaName = Add-PptxImageToSlide -Pptx $deck -Position $entry.Position -ImagePath $pngPath `
        -EmuX $entry.EmuX -EmuY $entry.EmuY -EmuCx $entry.EmuCx -EmuCy $entry.EmuCy -Name 'DiagramFromDrawio'
    Write-Host "  -> inserted as $mediaName"
}

Write-Host ""
Write-Host "build-diagrams.ps1 complete. Run validate-deck.ps1 next - its 'Image / text overlap'"
Write-Host "check (Get-PptxImageTextOverlaps) will flag it if a diagram still covers a text field;"
Write-Host "nudge EmuY/EmuCy above rather than trusting the default placement blindly."
