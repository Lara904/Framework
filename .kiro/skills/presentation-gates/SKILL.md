---
name: presentation-gates
description: Fill in and complete an Architecture Gates (ARB / TCC) presentation deck for SIBS / Stellantis Financial Services, based on the official SIBS_Architecture_Gates_Template_V5.2 PowerPoint (75 slides). The template is read-only and must never be modified.
keywords:
  - presentation
  - powerpoint
  - pptx
  - architecture gates
  - arb
  - tcc
  - sibs
  - stellantis
  - gate 1
  - gate 2
  - gate 3
  - gate 4
  - demand gate
  - slides
  - deck
  - support
---

# Architecture Gates Presentation (SIBS / Stellantis Financial Services)

This skill helps produce and complete an **Architecture Gates** presentation (the ARB /
Technical Check Committee "TCC" approval deck) from the official
**SIBS Architecture Gates template** (`SIBS_Architecture_Gates_Template_V5.2.pptx`).

It fills the template's placeholder text with project-specific content, gate by gate
(Gate 1 Demand -> Gate 2 Initial -> Gate 3 after Design -> Gate 4 before Go-Live),
while preserving the template's layout, master slides, theme, and section order.

## Absolute rule — the template is READ-ONLY
> **NEVER modify the template file.** The authoritative template is bundled with this skill at
> `assets/templates/SIBS_Architecture_Gates_Template_V5.2.pptx` and is the single source of
> truth (the skill is self-contained; no external file is required). Always work on a **copy**
> saved under a new name. Never write to, rename, move, or overwrite the bundled template
> itself.

## When to use this skill
Activate this skill when the user wants to:
- Start a new Architecture Gates / TCC / ARB presentation for a project
- Fill in or complete an existing gates deck for a specific gate (1, 2, 3 or 4)
- Update a deck when moving from one gate to the next
- Review a deck against the template structure and the gate criteria

## Bundled assets (inside this skill)
- `assets/templates/SIBS_Architecture_Gates_Template_V5.2.pptx` — the authoritative,
  read-only template (V5.2, 16:9, 75 slides incl. cover, Gate 1 to Gate 4).
- `assets/scripts/` — helper PowerShell scripts for environments without python-pptx, all thin
  wrappers over one shared module `PptxGates.psm1` (in-memory zip reads, slide-order resolution,
  `<a:t>` extraction, template guard, XML escaping, slide map, detection patterns). Covers
  inspecting slides, extracting notes, batch-filling fields, and the gates checklist.
  See `references/tooling.md` and `assets/scripts/README.md`. Reuse the module; do not
  re-implement these primitives inline.

## Reference guides (load on demand)
Read the relevant reference file(s) in `references/` for the task at hand:
- `references/template-structure.md` — full slide-by-slide map of the template
  (position, title, purpose, which gate) and the section layout.
- `references/gates.md` — what each gate (1/2/3/4) requires, which slides to complete,
  and the "fill only your gate's section" workflow.
- `references/filling-guidance.md` — per-topic guidance distilled from the template's
  yellow placeholders and speaker notes (One Pager, DICT/CIAT, SLA, Data Privacy, NFR,
  Cloud, DevSecOps, Costs, Risks, SaaS specifics, etc.).
- `references/tooling.md` — how to edit .pptx (python-pptx preferred; PowerShell OpenXML
  fallback when Python is unavailable, as on this Windows machine), and the encoding rules.
- `references/gates-readme.md` — the gates README deliverable: format,
  how to generate it (`assets/scripts/find-missing.ps1`), and what counts as missing.
- `references/deliverables.md` — the required annex deliverables per gate (documents behind
  the "Link to ..." fields), how their status is tracked and persisted in the checklist.
- `references/tooling.md` also covers the **compatibility rules** (never re-serialize slide
  XML) and the mandatory `validate-deck.ps1` check that prevents "repair on open" / dropped slides.

## Core rules (always apply)
1. **The template is the source of truth and is read-only.** Copy it first; edit the copy.
2. **Keep the structure intact**: same master/layout, same theme, same section order.
   Do not add, delete or reorder sections unless the user explicitly asks.
3. **Fill only the current gate's section.** Use the same document across all gates:
   Gate 1 -> complete the Gate 1 section only; Gate 2 -> update Gate 1 if needed and
   complete Gate 2; Gates 3/4 -> complete the Gate 2-to-4 slides. See `references/gates.md`.
4. **Remove the yellow guidance once a field is filled** - both the guidance TEXT and its
   yellow HIGHLIGHT. Replacing a run's text keeps the run's `<a:highlight>` (yellow) formatting,
   so after filling/validating a slide, strip the highlight with
   `Remove-PptxHighlight -Positions <n>` (removes `<a:highlight>...</a:highlight>`). Do this on
   every validated slide so no yellow highlight remains.
   **Safety - never de-highlight light-coloured text.** Some header labels are WHITE text
   (`schemeClr bg1/bg2/lt1/lt2` or near-white `srgbClr` >= 220/220/220) sitting on a highlight/
   coloured band; removing their highlight leaves them white-on-white and illegible (this
   happened on slide 9's One Pager section labels). `Remove-PptxHighlight` therefore processes runs one by
   one and AUTOMATICALLY SKIPS such light-coloured runs (reporting them as `Skipped` vs.
   `Removed`). Keep the skip on by default; do NOT pass `-Force` on slides with white/light labels,
   and never strip highlight from a run you did not fill. If a label became unreadable, restore
   that slide's XML from the template (`Set-PptxParts`) and re-apply only your content fills.
5. **Hide non-applicable slides/domains** (per the Applicability slide), confirmed with the
   Enterprise Architect, so they are not discussed in the gate review. Hide them with
   `Set-PptxSlideVisibility ... -Visible $false` (`show="0"`) - do NOT physically delete slides
   (that renumbers positions and breaks the slide map / checklist). Hidden slides are auto-excluded
   from the gates checklist.
5b. **Flag each slide's review state with a status corner banner.** After a filling pass, mark
   every in-scope slide with a colour-coded corner band via `Set-PptxSlideBanner` (or the
   `set-banners.ps1 -Auto` wrapper): ORANGE "TO VALIDATE" = content filled, awaiting stakeholder
   validation; RED "TO COMPLETE" = data still missing / leftover guidance; and CLEAR the banner
   once a slide is validated/final. The banner is a single idempotent shape (`GateStatusBanner`),
   so re-running just updates the colour/label. Keep banners in sync with the deck's state and the
   checklist, and clear all banners before the final delivered version.
6. **ASCII-safe text, UTF-8 without BOM.** Avoid em dashes, curly quotes and bullets that
   become mojibake. See `references/tooling.md`.
6b. **Write all filled content in ENGLISH.** The audience is international; the deck must be
   English-only. Do not copy the user's wording verbatim if they brief you in another language -
   translate it to clear, professional English. (Confirm the language with the user if unsure;
   English is the default for this deck.)
7. **Never re-serialize slide XML, and never open the package in ZipArchiveMode.Update.**
   Edit via byte-level string/run replacement (`Set-PptxSlideReplacements` / `Set-PptxSlideRuns`),
   which write back by rewriting the package in Create mode (`Set-PptxParts`). Both
   `XmlDocument.Save` and `ZipArchiveMode.Update` make PowerPoint "repair" the file (and drop
   slides) - the latter even with no edits. See `references/tooling.md`.
8. **Never invent approvals, names, costs, SLA or CMDB values.** If a value is unknown,
   leave a clearly marked `TBD` / `TODO` placeholder and tell the user what is missing.
8d. **Template examples are INDICATIVE, not a source of truth.** The pre-filled example rows/items
   the template ships with (e.g. the Risks table's "Gen AI / Accessibility / Lack of training /
   Data" rows, sample cost lines, example approvers) are prompts to consider - NOT content to
   keep. For each example, decide with the project context whether it is applicable:
   - applicable -> replace the example text with the real project value;
   - NOT applicable -> **DELETE the example row/item entirely** (remove the whole `<a:tr>` / bullet),
     do NOT keep it marked "N/A" (e.g. if Gen AI is not applicable to the project, remove its row
     rather than leaving it as "N/A").
   Add project-specific rows the examples did not cover. Keep formatting UNIFORM across the
   rows/items you add (same font family and size as the existing body rows - reuse the run
   properties `<a:rPr sz=...>` already present, do not introduce a different font/size).
8a. **Put references ONLY in the template's designated placeholder field - respect the layout.**
   Each slide has specific placeholders for its links (e.g. slide 42 has one field for the
   Technical Architecture *document* link and a separate field for the *diagram* link; slide 33
   has a body area for the diagram and a "document link here" field). Fill the reference in the
   exact field the template asks for, and DO NOT add extra sentences, duplicate the reference
   elsewhere on the slide, or leave your own explanatory text in the body. Keep the template's
   field headings intact (e.g. "Technical Architecture document"). After filling, remove leftover
   guidance/"Example"/"Insert here" runs, but do not invent new text runs.
8c. **When a slide has no free space for a new picture, REPLACE the existing example image**
   (usually a placeholder thumbnail in a corner, e.g. the top-right example on slide 42) instead
   of adding another `<p:pic>`. Use `Remove-PptxImagesFromSlide` (or replace in place) and size
   the new diagram to the freed slot, preserving aspect ratio. Only use `Add-PptxImageToSlide` to
   add a picture on slides that genuinely have an empty area (e.g. slide 33's diagram zone). Never
   overlap the diagram with existing text/shapes.
8b. **On a "Link to ..." field, reference the OFFICIAL deliverable file/link, not a working copy.**
   The template's deliverable fields are meant to carry a link/reference to the authoritative
   document. Reference that official file by name/link on the slide - do NOT paste the document's
   content into the slide, and do NOT point to an intermediate/working export (e.g. a `.tsv`/`.csv`
   decisions file). **Pick the deliverable file format from what the slide expects:**
   - a **diagram / schema / map** (architecture overview, application flows, data flow, technical
     architecture view, cloud eligibility tree, enterprise/functional flow mapping) -> a
     **`.drawio`** file (export a `.png`/`.svg` for the picture embedded on the slide, but the
     referenced deliverable is the editable `.drawio`);
   - a **document / analysis / write-up** (functional or technical architecture document/DAT,
     risk analysis, security note, exit plan) -> a **`.docx`**;
   - a **spreadsheet / matrix / structured data** (NFR, cost/AWS estimate, access-rights matrix,
     GDPR self-assessment, environments/accounts list) -> an **`.xlsx`** (or `.xlsm` if it carries
     macros, as the NFR workbook does);
   - a **slide deck** deliverable -> a **`.pptx`**.
   Per-type conventions are tabulated in `references/deliverables.md`.
   **Make the reference clickable.** Keep the readable filename as the run text and attach the URL
   as an EXTERNAL hyperlink on that run with `Set-PptxHyperlink` (adds a `TargetMode="External"`
   relationship + `<a:hlinkClick>`), rather than pasting a long raw URL. **Derive the SharePoint
   URL automatically** with `Get-SyncedSharePointUrl <file>` when the deliverable lives in a
   OneDrive-synced library (it reads the local sync mount -> URL namespace mapping - no need to
   ask the user). Only if that returns `$null` (a purely local file, not synced) ask the user for
   the link, or leave the filename as plain text and note it in the README.
9. **Always keep the gates checklist up to date.** It is structured BY GATE, and each gate lists
   (a) its **slides** with missing data / leftover guidance and (b) its **required annex
   deliverables** (documents behind the "Link to ..." fields) with a persisted status. A trailing
   "General" section lists any-gate slides. The file MUST be named
   `${project_name}_Architecture_Gates_README.md` (single file, all gates). **Regenerate it after
   EVERY change** by re-running `assets/scripts/find-missing.ps1 -Gate all` with the same
   `-Out <Project>_Architecture_Gates_README.md`; deliverable statuses set by the user are preserved
   across runs. Keep statuses current as documents are provided (see `references/deliverables.md`).
   See `references/gates-readme.md`. (An `agentStop` hook automates the regeneration.)
10. **Always validate before delivery** with `assets/scripts/validate-deck.ps1` (well-formed
    parts, consistent slide counts, no re-serialization artifact, all required gate slides
    present). Do not hand over a deck that fails validation.
11. **Output** is a new .pptx saved to the per-project output folder `output/${project_name}/`
    (create it if missing - see the `output-convention.md` steering, single source of truth for
    output location; or a path the user gives), e.g. `${project_name}_Architecture_Gates_G<n>.pptx`,
    plus the gates README `${project_name}_Architecture_Gates_README.md` in the same folder. Never
    overwrite the template.

## Quick workflow
1. Confirm the target gate (1/2/3/4) and gather project inputs.
2. Copy the template to the output file name (never edit the template) — see `references/tooling.md`.
3. Identify the slides to complete for that gate — see `references/gates.md` and `references/template-structure.md`.
4. Fill each field (prefer a single batch pass via `replace-text.ps1 -Batch` / `Set-PptxSlideReplacements`),
   remove the corresponding yellow guidance, hide non-applicable domains — see `references/filling-guidance.md`.
5. Validate with `validate-deck.ps1` (integrity + required slides present); fix any failure before continuing.
6. Re-dump edited slides to confirm values landed and no mojibake / leftover placeholders remain.
7. (Re)generate the gates README to `<Project>_Architecture_Gates_README.md` (`-Gate all`) so it
   reflects the deck's current state — do this after every change — `references/gates-readme.md`.
8. Save the copy + the gates README, and report what was filled and what is still missing.
