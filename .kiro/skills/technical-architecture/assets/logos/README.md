# CI/CD Tool Logos (bundled with the skill)

These are the official logos for the Stellantis CI/CD stack, bundled with the technical-architecture skill so generated diagrams can embed them directly (self-contained, no external references).

Location: `.kiro/skills/technical-architecture/assets/logos/`

| Tool | PNG | Pre-encoded data URI | Native size | Width @ height 64 |
|------|-----|----------------------|-------------|-------------------|
| GitHub | `github.png` | `github.b64` | 4000x2262 | 113 |
| TeamCity | `teamcity.png` | `teamcity.b64` | 300x94 | 204 |
| Artifactory | `artifactory.png` | `artifactory.b64` | 1200x746 | 103 |

## Usage
- Each `.b64` file contains a ready-to-use draw.io data URI: `data:image/png,<base64>` (no `;base64,` — draw.io's form).
- To place a logo in a diagram, create a `shape=image` cell and set `image=` to the full content of the matching `.b64` file.
- Always use `imageAspect=1`, a uniform height of `64`, and the width from the table above (preserves aspect ratio).

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
