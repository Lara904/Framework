# Gates Checklist (deliverable)

Every time this skill fills or reviews a deck, it also maintains a **gates checklist**. The
checklist is structured **by gate**, and each gate lists BOTH:
- (a) its **slides** with missing data / leftover template guidance (heuristic scan), and
- (b) its required **annex deliverables** (documents behind the "Link to ..." fields) with a
  persisted status.
A trailing "General" section lists slides that apply to any gate/solution.

## File name (fixed convention)
The gates README file MUST be named `${project_name}_Architecture_Gates_README.md`, in the
per-project output folder `output/${project_name}/` (see the `output-convention.md` steering -
single source of truth for output location) - it is the gates companion README (aligned with the
deck name `${project_name}_Architecture_Gates_G<n>.pptx`, written to the same folder, and the
README convention of the other skills). Do not use per-gate names like `_missing_G1.md`; a single
file covers all gates (`-Gate all`).

## Structure (required)
```
# Architecture Gates README - <project>
Source / Generated / Scope
Hidden (non-applicable): slides ...

## Gate 1 - Demand Gate
### Slides
- [ ] Slide <n> - <title>  _(found: <markers>)_
### Annex deliverables
- [ ] <deliverable> (<gates>) - status: <status>  _(slide <n>)_

## Gate 2 - Initial Gate
### Slides ...
### Annex deliverables ...

## Gate 3 ...   ## Gate 4 ...

## General (any gate / any solution) - slides
- [ ] Slide <n> - <title> ...

---
Open slide items: <n>  |  Open deliverables: <m>
```

## When to produce / keep up to date
- After every change to the deck (each fill, image insert, edit), and before delivering.
- Regenerate with the SAME `-Out` path so deliverable statuses (persisted) are preserved.
- Generate in scope `all` when working across several gates so no gate's content is dropped.

## How to generate it
Use the bundled script (works without Python; on this machine Python is unavailable):
```
powershell -ExecutionPolicy Bypass -File assets/scripts/find-missing.ps1 \
  -Pptx "<Project>_Architecture_Gates_G<n>.pptx" -Gate all -Out "<Project>_Architecture_Gates_README.md"
```
- `-Gate all|1|2|3|4` selects the scope. `all` renders every gate (recommended for multi-gate work).
- The script never writes over the template (name guard).
- It resolves the TRUE display order from the deck's `sldIdLst` (not the physical `slideN.xml`
  name - a deck that inserts/reorders slides breaks that assumption), so items are correctly
  ordered and numbered as the user sees them in PowerPoint.
- Each `Slide <n> - <title>` line shows the slide's **real title read from the deck** (via
  `Get-SlideTitle`), so the label is correct whatever the deck's numbering or slide count. The
  V5.2 `SlideMap` is used only for gate TAGS (which gate a position belongs to) and as a fallback
  label when a slide's text yields no usable title - never to title an existing slide.
- It is a thin wrapper over `PptxGates.psm1`: the slide map, deliverables catalogue, detection
  patterns, title derivation and slide-text extraction all live in the module, so the checklist
  stays consistent.

## Automate with an agentStop hook (recommended)
An `agentStop` hook regenerates the gates README at the end of every agent execution so it never
drifts. Example (`.kiro/hooks/refresh-gates-readme.kiro.hook`):
```json
{
  "enabled": true,
  "name": "Refresh Gates Checklist",
  "version": "1",
  "when": { "type": "agentStop" },
  "then": {
    "type": "runCommand",
    "command": "powershell -ExecutionPolicy Bypass -File \".kiro/skills/presentation-gates/assets/scripts/find-missing.ps1\" -Pptx \"<Project>_Architecture_Gates_G<n>.pptx\" -Gate all -Out \"<Project>_Architecture_Gates_README.md\""
  }
}
```
Adjust the deck name and output path per project; keep `-Gate all`.

## Two parts recap
1. **Slides** - per-gate, heuristic. Hidden (non-applicable) slides are excluded and listed in a note.
2. **Annex deliverables** - per-gate; status `Not started / In progress / Provided / N/A`, read back
   from the existing file on each run so user-tracked progress survives (incl. the hook). Catalogue
   lives in the module (`Get-Deliverables`); see `deliverables.md`.

## What counts as "missing"
The scan flags text that looks unfilled or like leftover guidance, including:
`TBD`, `TODO`, `xxxx`, `Xxx K` amounts, `Yes/No`, `Y/N`, `dd/mm/yyyy`, `<<...>>`, `XX*`
version placeholders, and guidance verbs/phrases still present in a slide
(`add here`, `Link`, `Describe`, `List`, `Insert`, `Mention here`, `Example`, `Complete for`,
`See slide notes`, `#IdeaNumber`/`#demandNumber`).

Front matter, dividers and the reference/example slides are excluded (see `template-structure.md`
for which markers are legitimate template text rather than gaps).

## Caveats
- Detection is heuristic: some flags are false positives (a legitimate "Example"/"Link" in
  template structure) and some real gaps may be missed (text split across runs). Always review;
  treat it as a prompt, not a verdict. `template-structure.md` says which slide markers are real.
- Mark a slide done only when the field is filled AND the yellow guidance/highlight is removed.
