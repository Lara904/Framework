# Layout & Geometry Validation

After building or modifying components, perform a geometry double-check to ensure proper visual rendering.

## Position & Dimension Rules

**Account boundaries** must contain all their children:
- For each group/container cell, verify that all child cells' `(x, y, width, height)` fit within the parent's geometry
- Parent `x + width` must be >= child `x + width`, and parent `y + height` must be >= child `y + height`
- Leave at least 30px padding between a group boundary and its inner components
- Leave at least 40px top padding for group labels (account names, subnet names)

**Subnet stacking** (top to bottom in VPC):
- Protected subnet: y range approximately [-62, 48] (relative to VPC)
- Private subnet: y range approximately [75, 226]
- Isolated subnet: y range approximately [247, 377]
- Ensure no vertical overlap between subnet boundaries

**Component spacing** within a subnet:
- Minimum 40px horizontal gap between service icons
- Minimum 30px vertical gap between rows of services
- Icons standard size: 34x34 to 64x64 (keep aspect ratio `aspect=fixed`)
- Labels should not overlap adjacent icons (check `verticalLabelPosition` offset)

**Edge geometry** validation:
- For `edgeStyle=orthogonalEdgeStyle`: verify that intermediate `<mxPoint>` waypoints don't cross through unrelated components
- **No overlapping edges**: no two edges may share the same segment or sit on top of each other. When multiple flows connect the same pair of components or run through the same corridor, separate them: use different source/target ports (0, 0.25, 0.5, 0.75, 1), add distinct waypoints, or offset one edge by at least ~20px. Line crossings are tolerated only when unavoidable; collinear overlaps are not.
- After removing a cell, check all edges — any edge with a `source=` or `target=` referencing a deleted cell ID must also be removed
- Edge labels (`edgeLabel` cells with a `parent=` pointing to an edge) must be removed if their parent edge is removed

## Data Flow Diagram validation (separate `_dataflow.drawio` file)
The Data Flow Diagram is its own file (`<project>_technical_architecture_dataflow.drawio`) with a
`Versions` page first and a `Data Flow` page. It follows the same geometry rules as the
architecture diagram. In addition:
- Intra-application components sit inside the application boundary box; verify containment/padding.
- External applications/actors sit OUTSIDE that boundary.
- Every flow edge has both a valid source and target (no orphaned/dangling edges), a criticality
  colour (C1 green / C2 yellow / C3 orange / C4 red / C? dashed grey) and a single-line ASCII
  label of the form `Cx | DCP=Yes/No | <protocol/port> | <what data>`.
- The legend box (C1-C4 colours + DCP flag + encryption abbreviations + inter/intra convention)
  is present and does not overlap the flow nodes.
- The file declares `<mxfile pages="2">` (Versions + Data Flow).

## Frameworks diagram validation (separate `_frameworks.drawio` file)
The Frameworks diagram is its own file (`<project>_technical_architecture_frameworks.drawio`) with
a `Versions` page first and a `Frameworks` page. It follows the same geometry rules as the
architecture diagram. In addition:
- The layered stack boxes do not overlap; each layer heading is present (a "Not applicable" layer
  keeps its box rather than being deleted).
- Every product/framework shows a **version** (or `XX*` / `TBC` for an undecided one).
- Cell text is ASCII-only (no em dash / bullet / curly quotes); no external image references.
- The file declares `<mxfile pages="2">` (Versions + Frameworks).

## Overlap Detection Process
For each page in the diagram:
1. Build a list of all vertex cells with their absolute bounding boxes (resolve parent-relative coordinates)
2. For cells at the same hierarchy level (same `parent=`), check that no two bounding boxes overlap unless one is a container for the other
3. Flag any overlap and resolve by shifting the conflicting cell:
   - Prefer shifting right or down
   - Maintain alignment with existing grid (gridSize=10 in template)
4. After shifting, update any connected edge waypoints if they become misaligned

## Boundary Resize After Changes
- **Removing**: If remaining children no longer fill the container, shrink the container boundary to fit (min 30px padding around remaining children)
- **Adding**: If new children exceed the container, expand the container boundary. Then check if the container's parent also needs expansion (cascade upward)
- **Account-level**: If the Application Account or VPC boundary changes, verify it still fits within the AWS SFS NG Landing Zone boundary and the AWS Cloud outer boundary

## Reference Dimensions (from template)
| Element | Approximate Geometry |
|---------|---------------------|
| AWS Cloud boundary | x=-800, y=-514, w=2040, h=1074 |
| SFS NG Landing Zone | x=-774, y=-484, w=1740, h=1000 |
| Application Account | x=-564, y=-455, w=1210, h=941 |
| Global Region (inside Application Account) | x=-724, y=-425, w=914, h=101 — must fit within Application Account |
| VPC | x=-424, y=-173, w=624, h=620 |
| Protected subnet | x=-391, y=-62, w=570, h=110 |
| Private subnet | x=-391, y=75.5, w=570, h=151 |
| Isolated subnet | x=-391, y=247, w=570, h=130 |
| Region eu-west-3 | x=-544, y=-314, w=1150, h=780 |
| On-Premise Data Center | x=1311, y=-514, w=449, h=1074 |
| Shared Endpoint Account | x=690, y=-94, w=236, h=434 |
| Network Account | x=690, y=-298, w=236, h=174 |
| Transit Gateway | x=726, y=-237, w=64, h=64 |

## Alignment Grid
- The template uses `gridSize=10` — all positions should be aligned to multiples of 10 (or at minimum multiples of 5 for fine adjustments)
- When placing new components, snap to the nearest grid position
- Edge connection points should use standard port positions (0, 0.25, 0.5, 0.75, 1 on each side)

## Final Rendering Check
- [ ] No component overlaps another at the same hierarchy level
- [ ] All containers fully enclose their children (with padding)
- [ ] All edges connect to existing cells (no dangling source/target references)
- [ ] No edge overlaps another edge (no shared/collinear segments); edges do not run through unrelated components
- [ ] Edge label positions make sense (not overlapping other labels or components)
- [ ] Icon sizes are consistent (same service type = same dimensions throughout)
- [ ] Text labels don't overflow their cells (`whiteSpace=wrap` is set)
- [ ] The canvas `pageWidth`/`pageHeight` in `<mxGraphModel>` is large enough if diagram expanded
- [ ] Coordinates use the same reference frame as the template (negative values are normal for top/left areas)
- [ ] Separate Data Flow Diagram file present (`_dataflow.drawio`), with its own Versions page, a legend, per-flow C1/C2/C3/C4 criticality + DCP + transport labels, and no orphaned edges
- [ ] Separate Frameworks diagram file present (`_frameworks.drawio`), with its own Versions page, the layered stack with versions (or `XX*`/`TBC`), no overlapping boxes, and consistent with DAT 2.1.2 and Deck slides 30/44/43
