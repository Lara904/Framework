# CI/CD Tool Logos (bundled with the skill)

These are the official logos for the Stellantis CI/CD stack, bundled with the technical-architecture skill so generated diagrams can embed them directly (self-contained, no external references).

Location: `.kiro/skills/technical-architecture/assets/logos/`

| Tool | PNG | Pre-encoded data URI | Native size | Width @ height 64 |
|------|-----|----------------------|-------------|-------------------|
| GitHub | `github.png` | `github.b64` | 226x128 | 113 |
| TeamCity | `teamcity.png` | `teamcity.b64` | 300x94 | 204 |
| Artifactory | `artifactory.png` | `artifactory.b64` | 206x128 | 103 |

## Usage
- Each `.b64` file contains a ready-to-use draw.io data URI: `data:image/png,<base64>` (no `;base64,` — draw.io's form).
- To place a logo in a diagram, create a `shape=image` cell and set `image=` to the full content of the matching `.b64` file.
- Always use `imageAspect=1`, a uniform height of `64`, and the width from the table above (preserves aspect ratio).
- Keep source PNGs at roughly 2x the diagram's display height (so ~128px tall for a 64px-tall
  icon), not whatever resolution the logo was originally supplied at. The GitHub and Artifactory
  PNGs originally shipped at 4000x2262 and 1200x746 (print/marketing-asset resolution) while only
  ever being displayed at 113x64 and 103x64 in a diagram — each `shape=image` cell with that
  `image=` data URI inlined ~20-35KB of base64 into every `.drawio` file that used it for zero
  visible gain over a properly-sized source image. They were downsized to 226x128 / 206x128
  (2x retina for their 64px display height) on 2026-10-27, cutting the combined footprint of the
  three logos from ~60KB to ~32KB with no visible difference at the size they're actually shown.
  Re-apply this if a logo is ever replaced with a fresh, high-resolution source file.

Example cell:
```xml
<mxCell id="github" value="GitHub&#10;(app code + IaC)"
  style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=1;labelBackgroundColor=#ffffff;fontSize=11;image=<CONTENT OF github.b64>;"
  vertex="1" parent="cicdbox">
  <mxGeometry x="130" y="78" width="113" height="64" as="geometry"/>
</mxCell>
```

## Regenerating
If a logo is updated, replace the `.png` and regenerate its `.b64` (UTF-8, no BOM):
```powershell
$uri = "data:image/png," + [Convert]::ToBase64String([IO.File]::ReadAllBytes("github.png"))
[IO.File]::WriteAllText("github.b64", $uri, (New-Object System.Text.UTF8Encoding($false)))
```
