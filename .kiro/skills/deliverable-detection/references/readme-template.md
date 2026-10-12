# Deliverable Detection README - deliverable template

Write `${project_name}_deliverables_detection_README.md` to the per-project output folder
`output/${project_name}/` (see the `output-convention.md` steering - single source of truth for
output location), in English, using the structure below. It is the audit trail of the detection
pass: what was found, mapped to which consumer skill, with what confidence and evidence, and what
is missing or ambiguous.

The category list and the category -> consumer-skill mapping come from
`references/categories.json` (single source of truth). Do NOT retype that table here from memory;
render it from the JSON so the two never drift.

```markdown
# <Project> - Deliverable Detection

Version: <x.y>  |  Date: <YYYY-MM-DD>  |  Author: <name>
Scanned folder: <path> (read-only)   |   Categories source: references/categories.json
Status: <Draft / Reviewed with user>

## Coverage summary
| Category | Consumer skill | Required | Status | Best confidence |
|----------|----------------|----------|--------|-----------------|
| <label> | <skill> | yes/no | Detected / Missing / Ambiguous | High/Medium/Low/- |
<one row per category in categories.json, in that order>

Detected: <n>/<total>  |  Required missing: <n>  |  Open questions: <n>

## Detected files (mapping)
For each file that mapped to at least one category:
- `<relative/path/file.ext>` -> **<category>** (<consumer skill>) - confidence **<level>**
  - evidence: <name/path/ext signals that matched>
  - <optional note: what the consumer skill should take from it>

## Missing categories
Expected categories with no file found:
- [ ] **<label>** (<consumer skill>) - required: <yes/no> - _no source file detected_

## Open questions (ambiguous - ask the user, do NOT guess)
- `<file>` could be **<category A>** or **<category B>**: <why ambiguous>. Question: <the exact
  question to put to the user before mapping it>.

## Assumptions
- <any Medium/Low mapping accepted provisionally, and why - clearly marked "to confirm">

## Change history
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1 | <YYYY-MM-DD> | <name> | Initial detection pass. |
```

Rules:
- English only, ASCII-safe (use `-` and straight quotes; no mojibake).
- Never mark a file High-confidence without a cited piece of evidence (name/ext/path).
- Never silently resolve an ambiguous file: it goes under "Open questions", not "Detected".
- Read-only: this README is the ONLY artefact produced; nothing under the scanned folder is
  moved, renamed or modified.
- Keep the category rows in sync with `references/categories.json` (render, don't duplicate).
- Every re-run appends a change-history row; keep user-set resolutions across runs.
