# Detection method

How `deliverable-detection` turns a pile of dropped files into a mapping checklist, without ever
touching the sources.

## Single source of truth
All categories, their consumer skill, and the detection signals (name keywords, path keywords,
expected extensions, notes) live in **`references/categories.json`**. The scan script
(`assets/scripts/detect-deliverables.ps1`) reads that file; the README renders its rows from the
same file. There is no second copy of the mapping anywhere - do not hard-code it in the script or
retype it in a `.md`. To add/change a category, edit `categories.json` only.

## Pass 1 - cheap signals (the script)
`detect-deliverables.ps1 -Path "<drop folder>" [-Out <result.json>]` walks the folder recursively
(read-only) and, for every file, scores each category on three signals:
- **name keyword** in the file name -> strong signal;
- **path keyword** in the relative path/folder -> context signal;
- **extension** in the category's expected list -> type signal.

Confidence (per `confidence.rule` in the JSON):
- **High** - a name keyword matched, or both a path keyword and an expected extension matched;
- **Medium** - only a path keyword, or only an expected extension matched;
- **Low** - a loose hint only.

A file is flagged **ambiguous** when it has no candidate, or when two or more categories tie at
the top confidence rank and that rank is not High.

## Pass 2 - content check (the agent, only when needed)
The script never opens file contents. When Pass 1 is ambiguous or only Medium/Low, read the file
(or its text) to confirm or reject - e.g. open a `.docx`/`.xlsx`, inspect a `.drawio`'s labels,
check whether a diagram folder is "flow/acquisition" (dataflow-mapping) vs a general technical
diagram (technical-architecture). Use the category `notes` in the JSON to guide the check. Promote
to High only with a concrete, citable piece of evidence.

## Pass 3 - resolve, never guess
- Clear High mapping -> list under "Detected files".
- Still ambiguous after a content check -> list under "Open questions" with the exact question to
  ask the user. Do NOT pick one silently (the "never invent" guardrail).
- Required category with no file -> list under "Missing categories" (checkbox).

## Disambiguation notes (common cases)
- **technical-architecture vs dataflow-mapping**: both are diagrams/docs and both feed the
  `technical-architecture` skill. Route a file to **dataflow-mapping** when the name/path says
  flow / acquisition / pipeline / data flow; otherwise to **technical-architecture**. When a
  folder mixes both, map per file, not per folder.
- **functional vs technical diagrams**: a `.drawio`/`.png` under a "Functional architecture"
  folder is functional; under "Technical architecture & stack" it is technical. The path keyword
  carries the decision.
- **nfr-requirements**: a workbook named NFR is High on name alone; prefer the `.xlsm`/`.xlsx`
  over any exported `.csv`.
- **presentation-gates**: an ARB/TCC `.pptx` is a base to COMPLETE, flagged `role: base-to-complete`
  in the JSON - never propose rebuilding it.
- **embedded signals**: a PRD/REFLEX code or a DICT value may sit INSIDE another document. If
  Pass 2 finds one, record a secondary mapping (e.g. access-right-matrix / dict-assessment) with
  the evidence, rather than forcing a single category per file.

## Output
One README in the per-project output folder `output/${project_name}/`
(`${project_name}_deliverables_detection_README.md`, `references/readme-template.md` - see the
`output-convention.md` steering, single source of truth for output location). The optional
`result.json` from the script is a work artefact, not a deliverable - keep it under
`.kiro/.temp_ai/`, never in `output/`.
