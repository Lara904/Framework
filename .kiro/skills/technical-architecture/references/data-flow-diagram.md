# Data Flow Diagram (DFD)

In addition to the AWS architecture view, this skill produces a **Data Flow Diagram** that shows
how data moves **between applications (inter-application flows)** and **inside the application
itself (intra-application flows)**, with, on every flow, its **data criticality (C1/C2/C3)** and
its **transport protection (TLS / mTLS / none)**.

The DFD is a **separate, standalone deliverable**: its own draw.io file named
`<project>_technical_architecture_dataflow.drawio` in `output/${project_name}/` (see the
`output-convention.md` steering; NOT a page inside the
architecture `.drawio`). Like the architecture diagram, it starts with its own **Versions** page
(same table format as `output-format.md`), followed by a **Data Flow** page. Page order in the
DFD file is therefore: **Versions** (first) -> **Data Flow**. The README (Data flows table) and
the DAT (flow matrix) carry the same information in tabular form (see below), and must stay
consistent with this file.

## Purpose and scope
The DFD answers three security questions that the AWS architecture view does not make explicit:
1. **Who exchanges data with whom** - inter-application flows (this app <-> external apps /
   systems / users) and intra-application flows (between the app's own tiers/components).
2. **How sensitive is the data on each flow** - a criticality label C1/C2/C3 per flow.
3. **How is each flow protected in transit** - TLS 1.2+, mTLS, SFTP/PGP, or "none" (in-browser
   / same-process), plus the port when relevant.

Keep it flow-centric: nodes are applications/components; the information lives on the **edges**.

## Source of truth: the Stellantis "Data flow mapping"
The authoritative flow inventory at Stellantis is the **Data flow mapping** spreadsheet (built
from ARIS, the CMDB and the GDPR files). It has two pattern sheets - a **Functional Flow
Pattern** and a **Technical Flow Pattern** - and it classifies each flow with the official
**C1/C2/C3/C4** data-confidentiality scale plus a **DCP** flag (Donnee a Caractere Personnel =
personal data yes/no). This DFD is the **graphical, application-focused view** of that mapping,
and the DAT flow matrix is its synthetic extract. All three MUST use the SAME scale (C1-C4) and
the SAME DCP terminology so they stay consistent. Reuse the values from the Data flow mapping
when it exists; do not invent them.

### Official columns to stay aligned with
- **Functional Flow Pattern**: Functional flow name | Type of treatment | Source Service/App |
  Destination Service/App | Frequency | Data confidentiality (C1/C2/C3/C4) | Type of data with DCP
- **Technical Flow Pattern**: Technical flow name | Type of flow | Source Service/App | Hostname
  Source | Hostname Destination | Data confidentiality (C1/C2/C3/C4) | Port | Protocol | Token
  supplier if API | Exposition End Point | APIC Product
- **DCP derivation rule** (from the mapping): if both endpoints carry personal data (DCP), the
  flow carries DCP; if either endpoint does not, the flow does not; if the source is DCP=Yes and
  the destination DCP is missing, the flow is DCP=Yes. When DCP cannot be settled, mark it "to be
  confirmed by an expert" rather than guessing.

## Data confidentiality scale (C1 / C2 / C3 / C4)
Use the official Stellantis **4-level** data-confidentiality scale for the criticality label on
each flow (same scale as the Data flow mapping). It classifies the **data carried by a single
flow**. In addition, tag each flow with **DCP** (personal data: Yes/No) - a flow can be, e.g.,
C3 + DCP=Yes. Confirm the exact wording of each level with the security team; keep the C1..C4
labels regardless.

| Label | Meaning (typical) | Typical content | Edge colour |
|-------|-------------------|-----------------|-------------|
| **C1** | Public / non-sensitive | Public assets, static bundles, marketing content | Green `#82b366` stroke, `#d5e8d4` label fill |
| **C2** | Internal / restricted | Internal config, non-personal business data, technical logs | Yellow `#d6b656` stroke, `#fff2cc` label fill |
| **C3** | Confidential / personal data (GDPR) | Personal data, credentials, financial data | Orange `#d79b00` stroke, `#ffe6cc` label fill |
| **C4** | Secret / highly sensitive | Secrets, keys, highly regulated data, critical assets | Red `#b85450` stroke, `#f8cecc` label fill |
| **C?** | Unknown - to confirm | criticality not yet qualified | Grey `#999999` dashed - mirror as an Open question |

- Align the DCP flag with the DICT/GDPR reading: any flow carrying personal or financial data is
  **DCP=Yes** (and usually at least C3). If a flow's criticality or DCP is not confirmed, mark it
  **C?** / "DCP TBC" (dashed grey) and raise a matching Open question in the README + a TBC note
  in the DAT. Never invent a criticality or a DCP value.

## Encryption / transport protection
Every edge states how it is protected in transit. Use short ASCII labels:
- `TLS 1.2+` (HTTPS), `mTLS` (mutual TLS), `SFTP`, `PGP` (payload encryption), or `none`.
- `none` is legitimate for **intra-browser / same-process** flows (e.g. data handed from a web
  component to its host page in the same browser) - state it explicitly rather than leaving it
  blank, so the reviewer sees it was a conscious decision.
- Add the port when it is meaningful (e.g. `443`, `22`).

## Node conventions
- **This application's components** (intra): group them inside an application boundary box
  (`rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;`), one inner box per
  tier/component (browser widget, CDN, storage, backend service, DB...). Reuse the same names as
  the AWS architecture page so the two views agree.
- **External applications / systems / actors** (inter): draw them OUTSIDE the application boundary
  as plain boxes (`rounded=1;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;`).
  Human actors use `shape=mxgraph.aws4.user;` (same convention as the architecture page).
- You may reuse AWS service icons for components that map 1:1 to a service (S3, CloudFront), but a
  DFD may also stay logical (plain labelled boxes) - either is acceptable as long as names match.

## Edge conventions
- Style: `edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;` with an arrowhead showing the data
  direction (bidirectional flows: two edges or `startArrow=classic`).
- Colour the edge stroke by criticality (see the table): C1 green, C2 yellow, C3 orange, C4 red,
  C? grey dashed. Example: `strokeColor=#b85450;strokeWidth=2;` for a C4 flow.
- **Edge label format (single line, ASCII only)**: `Cx | DCP=Yes/No | <protocol/port> | <what data>`
  - e.g. `C1 | DCP=No | TLS 1.2+ 443 | widget JS bundle`
  - e.g. `C3 | DCP=Yes | none (in-browser) | income/expenses input`
  - e.g. `C3 | DCP=Yes | mTLS 443 | pre-check request`
  - DCP may be omitted on the edge only if it is always No for the whole diagram; otherwise show
    it, since it is the point a data-flow reviewer checks.
- Keep labels short; put longer detail in the README/DAT flow table, not on the edge.
- Number the flows (`F1`, `F2`, ...) if there are many, so the README/DAT table can reference
  each edge unambiguously.

## Legend (mandatory on the Data Flow page)
Add a small legend box on the page so the diagram is self-explanatory. It must show:
1. The four criticality colours with their meaning (C1/C2/C3/C4) and the C? convention.
2. The DCP flag convention (DCP=Yes = personal data / GDPR on the flow).
3. The encryption abbreviations used (TLS 1.2+, mTLS, SFTP, PGP, none).
4. The inter vs intra convention (inside vs outside the application boundary box).

Reference skeleton for a legend row (repeat per criticality):
```xml
<mxCell id="lgndC4" value="C4 - Secret / highly sensitive" style="text;html=1;align=left;verticalAlign=middle;fillColor=#f8cecc;strokeColor=#b85450;spacingLeft=6" vertex="1" parent="1">
  <mxGeometry x="40" y="120" width="300" height="26" as="geometry"/>
</mxCell>
```

## File & Versions page
- File name: `<project>_technical_architecture_dataflow.drawio` in **`output/${project_name}/`**
  (same folder as the architecture `.drawio` and the README - see the `output-convention.md` steering).
- The file has its own **Versions** page FIRST (identical table format to the architecture
  diagram - see `output-format.md`), then the **Data Flow** page. `<mxfile pages="2">`.
- On every modification, append a new row to this file's own Versions table (do not rewrite
  history), exactly like the architecture diagram.
- UTF-8 without BOM, ASCII-only cell text (same encoding rules as `generation-process.md`).

## Consistency rules
- The DFD file, the AWS architecture diagram, the README flow table and the DAT flow matrix
  MUST agree: same node names, same flows, same criticality and encryption values.
- Every `C?` (unknown criticality) or `C?`-style TODO on the DFD has a matching Open question in
  the README and a TBC note in the DAT, and vice versa.
- ASCII-only cell text, UTF-8 without BOM (same encoding rules as `generation-process.md`).
- Validate geometry like any other page (containment inside the application boundary, no
  overlapping nodes/edges, no orphaned edges) - see `layout-validation.md`.

## Minimal example (front-only widget)
For a front-only web component (no backend), a correct Data Flow page shows, at least (data
follows the real pull direction: the browser pulls the bundle from the CDN, which pulls from S3):
- Actor **End user (browser)** -> **Host web application** : `C1 | DCP=No | TLS 1.2+ 443 | loads host page`
- **CloudFront (CDN)** -> **Widget component** : `C1 | DCP=No | TLS 1.2+ 443 | widget bundle delivered`
- **S3 (widget bucket)** -> **CloudFront (CDN)** : `C1 | DCP=No | TLS 1.2+ (OAC) | bundle origin fetch`
- **End user (browser)** -> **Widget component** (intra, same browser) :
  `C3 | DCP=Yes | none (in-browser) | income/expenses input`
- **Widget component** -> **Host web application** (intra, same browser) :
  `C3 | DCP=Yes | none (in-browser) | pre-check inputs handed to controller`
- Legend box (C1/C2/C3/C4 + DCP + encryption + inter/intra convention).

This makes explicit that the only C3/DCP (personal/financial) data stays inside the browser and
is never transmitted to SFS - which is exactly the point a data-flow reviewer checks.
