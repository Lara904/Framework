# Generation Process (functional diagram)

Build a `.drawio` file with two pages: `Versions` (see `output-format.md`) then the functional
page. Everything is self-contained (no external images).

## Page layout strategy
1. Create one **company container** per confirmed company (ICT, SFS, others). Lay them out
   side by side (e.g. ICT on the left, SFS on the right) so cross-company flows read left-to-right.
2. Place each company's **applications** as nodes stacked inside its container.
3. Draw **interactions** as directed edges between application nodes, with business labels.
4. Place **user actors** near the application they use (external users typically on the far
   left/outside ICT; internal users near the SFS applications they operate).
5. Add a small **legend** (company colours, "(New)/(Update)/(Existing)" tags, actor = user).

## Style conventions (draw.io mxCell styles)
- Company container:
  `swimlane;html=1;startSize=28;fontStyle=1;fontSize=14;horizontal=1;` plus a distinct fill,
  e.g. ICT `fillColor=#dae8fc;strokeColor=#6c8ebf`, SFS `fillColor=#d5e8d4;strokeColor=#82b366`.
  Other party: `fillColor=#ffe6cc;strokeColor=#d79b00`.
- Application node (child of a container; use `parent=<containerId>` and relative geometry):
  `rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#6c8ebf;fontSize=12`.
- Interaction edge:
  `endArrow=block;html=1;rounded=0;fontSize=11;` (add `dashed=1` only if the user flags an
  optional/planned flow). Always give the edge a `value` (the business label). Prefer
  `edgeStyle=orthogonalEdgeStyle` and set explicit source/target ports
  (`exitX/exitY`, `entryX/entryY` using 0, 0.25, 0.5, 0.75, 1) so the path is predictable.
- **Avoid overlapping edges.** Two edges must not run along the same segment or sit on top of
  each other, and an edge must not pass through an unrelated node. When two flows share the
  same pair of nodes or the same corridor, separate them: use different ports on each node,
  add distinct `<mxPoint>` waypoints, or offset one edge by at least ~20px. Crossings are
  acceptable only when unavoidable; overlaps are not.
- User actor:
  `shape=umlActor;html=1;verticalLabelPosition=bottom;verticalAlign=top;fontSize=11` (or
  `shape=mxgraph.aws4.user` if you prefer the person glyph). Actors are top-level (not inside a
  company container) unless the user is clearly internal to one company.
- Note / constraint / TODO:
  `shape=note;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;fontSize=11`.

## IDs, parents, geometry
- Use stable, readable cell IDs: `ictBox`, `sfsBox`, `app_widget`, `app_leadmgmt`,
  `edge_widget_leadmgmt`, `user_customer`, etc.
- Application nodes are children of their company container: set `parent="ictBox"` and use
  geometry relative to the container's top-left.
- Edges reference `source` and `target` cell IDs (never leave an edge with a missing endpoint).

## Validation before saving
- **Containment**: every application node is inside its company container (within bounds).
- **No overlaps**: application nodes within a container do not overlap; containers do not overlap.
- **No orphaned edges**: every edge has a valid `source` and `target` that exist.
- **No overlapping edges**: no two edges share the same segment or sit on top of each other,
  and no edge runs through an unrelated node. Parallel flows use distinct ports/waypoints or
  are offset. Edge labels do not overlap other labels, edges, or nodes.
- **Direction & labels**: every interaction edge has an arrowhead and a non-empty business label.
- **Users linked**: every actor connects to at least one application.
- **Functional purity**: no technical elements (VPC/subnet/AWS/ports/protocols/CI-CD).

## File encoding rules (avoid mojibake)
- UTF-8 **without BOM**; ASCII-only text in cell values.
- Avoid em/en dashes, curly quotes, and bullet glyphs (they render as mojibake). Use `-` and
  straight quotes.

## Minimal skeleton (functional page)
The company names, applications, flow and actor below are an **example, fictional** - replace them
with the project's real companies/applications:
```xml
<mxCell id="companyABox" value="Company A - websites and IT" style="swimlane;html=1;startSize=28;fontStyle=1;fontSize=14;fillColor=#dae8fc;strokeColor=#6c8ebf" vertex="1" parent="1">
  <mxGeometry x="40" y="80" width="360" height="360" as="geometry"/>
</mxCell>
<mxCell id="app_main" value="My Application (New)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#6c8ebf;fontSize=12" vertex="1" parent="companyABox">
  <mxGeometry x="40" y="60" width="200" height="50" as="geometry"/>
</mxCell>
<mxCell id="companyBBox" value="Company B - business applications and IT" style="swimlane;html=1;startSize=28;fontStyle=1;fontSize=14;fillColor=#d5e8d4;strokeColor=#82b366" vertex="1" parent="1">
  <mxGeometry x="520" y="80" width="360" height="360" as="geometry"/>
</mxCell>
<mxCell id="app_partner" value="Partner Application (Existing)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#82b366;fontSize=12" vertex="1" parent="companyBBox">
  <mxGeometry x="40" y="60" width="200" height="50" as="geometry"/>
</mxCell>
<mxCell id="edge_main_partner" value="qualified data" style="endArrow=block;html=1;fontSize=11" edge="1" parent="1" source="app_main" target="app_partner">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
<mxCell id="user_customer" value="End customer" style="shape=umlActor;html=1;verticalLabelPosition=bottom;verticalAlign=top;fontSize=11" vertex="1" parent="1">
  <mxGeometry x="-120" y="180" width="40" height="80" as="geometry"/>
</mxCell>
<mxCell id="edge_customer_main" value="uses" style="endArrow=block;html=1;fontSize=11" edge="1" parent="1" source="user_customer" target="app_main">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```
(Child geometry is relative to the parent container; adjust coordinates so nodes do not overlap.)
