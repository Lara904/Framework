# FAD - Functional Architecture Dossier (single Word .docx)

In addition to the `.drawio` diagram and the functional README, this skill produces a
**complete Functional Architecture Dossier (FAD)** as a **single** Word `.docx` file.

The FAD MUST follow the **official Stellantis template DP-MD76-EN - "Functional Architecture
Dossier"**. To be visually faithful to that template (Stellantis logo in the header, Times New
Roman `Titre1..Titre4` headings with automatic numbering, framed title, theme, footers), the
generator **clones the bundled template** `assets/templates/Functional_Architecture_Dossier_template.docx`
and only regenerates the document body. The template is therefore a **required runtime asset** of
this skill (it is bundled inside the skill, so the skill is still self-contained - no project file
is needed). The generator keeps every layout part of the template verbatim (styles, theme,
headers/footers with the logo images, numbering, fonts, page setup) and replaces only
`word/document.xml`'s `<w:body>`, written with the template's real style IDs. The structure is
three chapters:
1. The scope of the transformation project
2. The scope of the functional architecture
3. Appendix: elements of the IT Urbanisation study

> The FAD we generate is **ONE file** (`.docx`), produced by cloning the bundled template and
> injecting the body. The **section structure below is mandatory** and mirrors the DP-MD76-EN
> template. Keep the template's headings even when a section is light (write a short "Not
> applicable" / "TBC" note under a heading rather than dropping it). Do NOT modify the bundled
> template itself (it is read-only source of truth).

## Inputs the FAD needs (map them to the outline)
The FAD is a business/urbanisation document. Before generating, gather the inputs listed in
`questionnaire.md` (sections 7-9) and map them to the outline:

| Input (typical source) | Feeds FAD section |
|------------------------|-------------------|
| Project positioning / program / IT master plan link | 1.1 Positioning of project plan |
| **Backlog / statement of needs / business requirements** | 1.2 Business perimeter, 2.1 Structuring elements |
| **User journey / user flow / business processes** | 1.2 Business perimeter and processes |
| Impacted applications (ideally from ARIS) + New/Update/Existing state | 1.3 IT situation, 2.2 Master plan |
| Reference / enterprise data used, and how it is accessed | 1.4 Situation of data, 2.2 data exchanges |
| Impacted BIS and functional architects (owners) | 1.5 Entities and architects involved |
| Target functional split of functions across applications | 2.2 Functional architecture chosen - Master plan |
| New application(s) description (construction permit) | 2.3 Construction permit of the new IT application |
| Phased rollout / bundles (if any) | 2.4 Progressive implementation |
| Discarded alternatives (if any) | 3.2 / 3.3 Alternatives not chosen |

The FAD, the functional diagram and the README MUST agree: the applications, companies,
interactions and users in the diagram/README are the same as those described in the FAD (mainly
in 1.3 and 2.2). Reuse the diagram as the master-plan illustration in chapter 2.

## Document furniture (mirrors the DP-MD76-EN template)
The generator reproduces the front-of-document structure of the template so the FAD looks
official, not a bare heading list:
- **Cover page** - the title is **"Functional Architecture Dossier"** (keep this wording), the
  `subtitle` (project name), the `version`, the author and the date, then a page break.
- **Synthesis / front-matter block** (as in the template, BEFORE the TOC): "Object of the
  document / Synthesis", "Audience addressed", "Links toward related documentation" (a table,
  including the validated statement of needs), and the "Revisions index" table.
- **Table of Contents** - a real Word `TOC \o "1-4"` field. `settings.xml` sets
  `updateFields=true` so Word offers to build it (with page numbers) on first open.
- **Numbered body** - Heading 1-4 carry automatic multi-level numbering (1, 1.1, 1.1.1, 1.1.1.1)
  via `numbering.xml`, exactly like the template.

## How it is generated (no Python / Office on this machine)
Use the bundled PowerShell generator (see `assets/scripts/README.md`):
1. Build a JSON **model** describing the FAD (title, cover/front-matter fields, and an ordered `body`).
2. `build-fad.ps1 -Model <model.json> -Out "<project>_functional_architecture_document.docx"` writes a valid `.docx`.
3. `validate-fad.ps1 -Docx "<project>_functional_architecture_document.docx"` must exit 0 (OPC opens, XML well-formed).

The generator copies every template part into a brand-new archive (`ZipArchiveMode.Create`, UTF-8
without BOM), swaps `word/document.xml` (rebuilt from the model using the template's real style
IDs: `Titre1..Titre4`, `Texte`, `Paragraphedeliste`, `Encadr`, `En-ttedetabledesmatires`,
`Grilledutableau`), reuses the template's exact `<w:document>` tag and its `sectPr`
(header/footer references), and sets `updateFields` in `settings.xml` so Word offers to build the
TOC. Word opens the result without "repair". The heading numbering, the Stellantis logo header and
the footers come straight from the template.

## Language & encoding
- The FAD is written in **English**, like all the other deliverables (diagram, README).
- The `.docx` is written as UTF-8 without BOM. Plain ASCII is preferred; accented characters are
  still handled correctly (proper UTF-8).

## Mandatory FAD outline (official DP-MD76-EN template)
Reproduce this exact chapter/section structure and numbering (h1 = chapter, h2/h3 = sub-sections).
Keep the headings even when a section is light; if a section does not apply, put a one-line "Not
applicable" / "TBC" note under it (mirroring the diagram TODO markers and the README open
questions) rather than removing the heading. Optional chapters are marked below.

**1. The scope of the transformation project** (h1)
- 1.1 Positioning of project plan (h2) - position the subject in the wider set (Project Plan,
  Program, IT master plan); link to the subject of the Project Plan and the Guidance Note.
- 1.2 Business perimeter and / or business processes addressed (h2) - present the subject with a
  business view: business processes / user journey / user flow, or a global view of the business
  perimeter. Feed from the backlog / statement of needs.
- 1.3 The IT situation of the impacted functional perimeter (h2) - list the impacted applications
  (label + description, ideally from ARIS), with their organizational/geographical coverage. This
  is the same application inventory as the functional diagram/README.
- 1.4 The situation of data useful in the project (h2) - useful data (reference/enterprise data
  not directly related to the subject) and how it is accessed.
- 1.5 The entities and functional architects involved (h2) - table of impacted BIS, involved
  architects (incl. the responsible DAF), and remarks.

**2. The scope of the functional architecture** (h1)
- 2.1 The structuring elements to take into account (h2) - the elements (from the business needs
  analysis) that drive the chosen architecture. Only elements that impact the decision.
- 2.2 The functional architecture chosen - Master plan (h2) - the target split of functions
  across applications (existing/new), and the resulting data exchanges/flows between applications.
  Reference the functional diagram as the illustration.
- 2.3 The construction permit of the new IT application (for each new IT application) (h2) - a more
  precise presentation of each NEW application (one sub-section per new application if several).
- 2.4 The progressive implementation of the functional architecture (if bundles needed) (h2) -
  *optional* - intermediate/phased architecture if it cannot be implemented in one phase.

**3. Appendix: elements of the IT Urbanisation study** (h1)
- 3.1 Detailed elements of guidance (if the topic requires it) (h2) - *optional* - ARIS maps/objects
  (IT needs, functional blocs) if the urbanism phase produced them.
- 3.2 Alternative functional architecture not chosen (if clarification needed) (h2) - *optional*.
- 3.3 Alternative IT application not chosen (if clarification needed) (h2) - *optional*.

## JSON model schema
```json
{
  "title": "Functional Architecture Dossier",
  "subtitle": "<Project name>",
  "version": "1.0",
  "author": "<name>",
  "date": "YYYY-MM-DD",
  "objectOfDocument": "This document presents the functional architecture to answer the needs of the <project> transformation project.",
  "audience": "TCC and CO, functional architects, project team, impacted BIS",
  "relatedDocuments": [
    { "title": "Validated statement of needs", "reference": "<link or TBC>" },
    { "title": "Functional architecture diagram", "reference": "<project>_functional_architecture_diagram.drawio" }
  ],
  "revisions": [
    { "version": "1.0", "date": "YYYY-MM-DD", "chapters": "All", "motives": "Initial creation of the FAD", "authors": "<name>" }
  ],
  "body": [
    { "type": "h1", "text": "The scope of the transformation project" },
    { "type": "h2", "text": "Positioning of project plan" },
    { "type": "p",  "text": "..." },
    { "type": "h2", "text": "Business perimeter and / or business processes addressed" },
    { "type": "p",  "text": "..." },
    { "type": "h2", "text": "The IT situation of the impacted functional perimeter" },
    { "type": "table", "header": ["Application", "Company", "State", "Description"], "rows": [
      ["<app>", "ICT / SFS", "New / Update / Existing", "<one line>"]
    ] },
    { "type": "h2", "text": "The situation of data useful in the project" },
    { "type": "p",  "text": "..." },
    { "type": "h2", "text": "The entities and functional architects involved" },
    { "type": "table", "header": ["Impacted BIS", "Involved architect (incl. responsible DAF)", "Remark"], "rows": [
      ["<BIS>", "<architect>", "<remark>"]
    ] },

    { "type": "h1", "text": "The scope of the functional architecture" },
    { "type": "h2", "text": "The structuring elements to take into account" },
    { "type": "p",  "text": "..." },
    { "type": "h2", "text": "The functional architecture chosen - Master plan" },
    { "type": "p",  "text": "See the functional architecture diagram (<project>_functional_architecture_diagram.drawio) for the applicative view." },
    { "type": "table", "header": ["From (initiator)", "To", "Exchange (business content)", "Notes"], "rows": [
      ["<app A>", "<app B>", "<what flows>", "<sync/async, constraint>"]
    ] },
    { "type": "h2", "text": "The construction permit of the new IT application (for each new IT application)" },
    { "type": "p",  "text": "..." },
    { "type": "h2", "text": "The progressive implementation of the functional architecture (if bundles needed)" },
    { "type": "p",  "text": "Not applicable." },

    { "type": "h1", "text": "Appendix: elements of the IT Urbanisation study" },
    { "type": "h2", "text": "Detailed elements of guidance (if the topic requires it)" },
    { "type": "p",  "text": "Not applicable." },
    { "type": "h2", "text": "Alternative functional architecture not chosen (if clarification needed)" },
    { "type": "p",  "text": "Not applicable." },
    { "type": "h2", "text": "Alternative IT application not chosen (if clarification needed)" },
    { "type": "p",  "text": "Not applicable." }
  ]
}
```

### body node types
| type | fields | renders as |
|------|--------|-----------|
| `h1` | `text` | Heading 1 (numbered outline level) |
| `h2` | `text` | Heading 2 |
| `h3` | `text` | Heading 3 |
| `h4` | `text` | Heading 4 |
| `p` | `text` | normal paragraph |
| `bullets` | `items` (string[]) | bulleted list |
| `table` | `header` (string[]), `rows` (string[][]) | bordered table, shaded header row |
| `pagebreak` | - | page break |

### Front-matter fields
| field | shape | renders as |
|-------|-------|-----------|
| `title` | string | cover title - keep **"Functional Architecture Dossier"** |
| `subtitle` | string | cover subtitle (project name) |
| `version` | string | cover "Version x.y" line |
| `author`, `date` | string | cover author / date line + docProps |
| `objectOfDocument` | string | "Object of the document / Synthesis" paragraph |
| `audience` | string | "Audience addressed" paragraph |
| `relatedDocuments` | `[{title, reference}]` | "Links toward related documentation" table |
| `revisions` | `[{version, date, chapters, motives, authors}]` | "Revisions index" table |

### Rules
- `title`, `author`, `date` are mandatory. The other front-matter fields are optional but
  recommended so the FAD matches the official template; a missing section falls back to a sensible
  default ("TBC" / a single initial revision row).
- Keep tables rectangular: every row has the same number of cells as the header.
- Escaping is automatic (`&`, `<`, `>`, quotes) - put raw text in the model.
- Never invent applications, flows, BIS, architects or data. Unknowns become a visible "TBC" in
  the FAD, an entry in the README **Missing information (to be provided)** table, and an open
  question to the user.
- Save the model file as UTF-8. Write the content in English.

## Output
- File name: `${project_name}_functional_architecture_document.docx` in **`output/${project_name}/`**
  (see the `output-convention.md` steering), next to the `.drawio` and the README.
- One file only. Always validate with `validate-fad.ps1` before delivery.
- The intermediate `<project_name>_functional_architecture_document.model.json` may be kept next
  to the docx (useful to regenerate / version the FAD) or removed; if kept, it is the source of
  truth for the next revision.
