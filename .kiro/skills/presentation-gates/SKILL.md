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
5c. **Hide the "Reference & examples" section (positions 71-75) before every delivery.** These five
   slides (the divider, Subject Matter Experts, Flow mapping guideline, and the two "- EXAMPLE"
   slides) are author-facing reference material, tagged SKIP so nothing in this skill ever fills
   or content-checks them (rule 10's leftover-highlight/instruction-text check explicitly excludes
   SKIP slides). That is correct for the WORKING copy, but it means they are never automatically
   hidden either - rule 5 only covers domain-applicability, not this section, which is irrelevant
   to every project without exception. A real delivery once shipped with the EXAMPLE As-Is/To-Be
   diagram and EXAMPLE macro-schedule timeline fully visible to the ARB because of exactly this
   gap. Before saving the final deliverable, always run
   `Set-PptxSlideVisibility -Positions 71,72,73,74,75 -Visible $false`. `validate-deck.ps1` now
   fails the build if any of 71-75 is still visible, so there is no "I'll remember to hide it"
   step left to skip (same philosophy as rule 10).
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
   **A marked placeholder beats a silently empty field.** A real IT Go-Live committee (a later,
   separate meeting from these Architecture Gates, but filled the same way - body text typed
   straight onto a slide) was presented with bullets reading "Validated Date of GO-Live:" and
   "General view of the committee:" with nothing after the colon - not TBD, not a dash, just
   empty. An empty field reads as "forgotten," not "deliberately unknown," and nobody in the room
   can tell the difference between an oversight and a genuine open question. If a field has no
   value yet, write `TBD` (or `n/a` when it is genuinely not applicable, as the same deck did
   correctly elsewhere) rather than leaving the line visually blank.
8g. **Synthetic test/QA content is not exempt from rule 8 - and has an extra rule of its own:
   never use a real, identifiable person's name.** This skill (and its scripts/validators) are
   sometimes stress-tested by filling a COPY of the template with deliberately realistic-looking
   fictional content - not for a real delivery, but to exercise table overflow, autosize, and
   similar logic under real-world conditions. That is a legitimate and valuable way to find real
   bugs (see `assets/scripts/PptxGates.psm1`'s own commit history for examples), but it is
   filling in people-looking fields (names, roles, approvers) that rule 8 says must never be
   invented for a real deck - so a synthetic test pass carries its own, stricter obligations:
   - **Never reuse a real person's name, initials or identity as a fictional value** - including
     the repository owner, the account/session user, or anyone else named anywhere in the
     project's context (git config, file metadata, prior conversation). A real pass once
     generated a fictional "Data PM" / TCC-approver name that happened to match the actual
     project owner's own name, assigning them a role and responsibilities they have nothing to
     do with - confusing and unacceptable even in throwaway test material. Draw fictional names
     from a fixed, obviously-synthetic pool (common given name + surname combinations with no tie
     to the project) and do not derive or "improvise" one from anything already present in the
     repo or session.
   - **Never call the result "the deck" or deliver/send it as if it were usable output.** A
     synthetic test deck - especially one covering only some of the slides the real target gate
     would require - must be named and described in a way that cannot be mistaken for a real,
     deliverable Architecture Gates deck (e.g. a filename suffix like `_TEST_SYNTHETIC`, and
     saved outside `output/${project_name}/`, never inside it). State plainly, every time such a
     file is shared, that it is synthetic test material for exercising the automation, not a
     deck anyone should review, approve, or treat as reflecting a real project or real people.
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
   **Some of a row's cells ship genuinely empty** (e.g. the Risks table's Impact/Likehood/
   Mitigation plan/Comments columns for the example rows are blank `<a:p><a:endParaRPr/></a:p>`,
   not placeholder text) - `Set-PptxSlideRuns` has no `<a:t>` to target there. Use
   `Add-PptxTableCellText -Cells @(@{Position=<n>; TableIndex=0; Row=<r>; Col=<c>; Text='...'})`
   instead, which inserts a new run anchored on the cell's own `<a:endParaRPr>` (so it inherits
   that cell's font size automatically). After filling a row this way, apply rule 8e's
   `Set-PptxTableRowAutosize` and re-render - a row that was one short line of placeholder text
   is now several real sentences across multiple cells, and is exactly the kind of growth that can
   push a fixed-position shape below the table into overlap.
8a. **Put references ONLY in the template's designated placeholder field - respect the layout.**
   Each slide has specific placeholders for its links (e.g. slide 42 has one field for the
   Technical Architecture *document* link and a separate field for the *diagram* link; slide 33
   has a body area for the diagram and a "document link here" field). Fill the reference in the
   exact field the template asks for, and DO NOT add extra sentences, duplicate the reference
   elsewhere on the slide, or leave your own explanatory text in the body. Keep the template's
   field headings intact (e.g. "Technical Architecture document"). After filling, remove leftover
   guidance/"Example"/"Insert here" runs, but do not invent new text runs.
   **A link field left as bare text is as bad as an unfilled one.** A real Go-Live deck shipped
   a diagram slide with its reference field reading only the single underlined word "link" - the
   label was there, the hyperlink never was. `Set-PptxHyperlink` must actually run and attach a
   `TargetMode="External"` relationship before a slide with a link field is considered filled;
   underlined/colored placeholder-looking text is not evidence a link exists, so check the
   relationship, not just the run's formatting.
8c. **When a slide has no free space for a new picture, REPLACE the existing example image**
   (usually a placeholder thumbnail in a corner, e.g. the top-right example on slide 42) instead
   of adding another `<p:pic>`. Use `Remove-PptxImagesFromSlide` (or replace in place) and size
   the new diagram to the freed slot, preserving aspect ratio. Only use `Add-PptxImageToSlide` to
   add a picture on slides that genuinely have an empty area (e.g. slide 33's diagram zone). Never
   overlap the diagram with existing text/shapes. **Enforce this by eye, not just by rule**: this
   script does not compute shape geometry, so nothing catches an overlap automatically. On slide
   17 specifically, a real deck once added the functional-architecture diagram picture directly on
   top of a template text paragraph that should have been deleted first (the paragraph was faint
   enough behind the image to go unnoticed in a text-only review) - after placing or resizing any
   picture, re-open the slide (render it, e.g. via LibreOffice `--convert-to png`) and visually
   confirm nothing is hidden behind the new image before moving on, rather than trusting the XML
   diff alone.
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
8e. **After filling any table slide (e.g. Technical stack, slide 32/47), run
   `Set-PptxTableRowAutosize -Positions <n>`.** A pre-built table's rows are sized for the
   template's own short placeholder text; real project content is usually longer, and a taller
   table can grow down into a standalone shape below it (a caption/footnote box does not move
   out of the way on its own - this is true in PowerPoint too, not a rendering quirk). A real
   pass found exactly this on slide 32: replacing "Debian XX*" / a 66-character comment with
   real content overlapped a fixed "All the software and libraries..." note box sitting below
   the table. `Set-PptxTableRowAutosize` estimates each row's needed height from the text
   actually filled in, finds the nearest shape below the table and how much room is free before
   it (and how much further that shape could still move down before running off the 16:9
   slide), and uses that room first; only if the content still doesn't fit even using all the
   slide's free room does it shrink the table's font (uniformly, floor 9pt) as a last resort -
   which is a sign the content itself may be too dense and worth shortening instead. Re-render
   the slide afterward and look at the PNG; this function's own report (FontScale, ShapeShiftedEmu)
   says what it did, but is not itself proof the fix landed - see rule 10's rendering requirement.
8f. **`Set-PptxTableRowAutosize`'s report (FontScale, ShapeShiftedEmu, StillOverflowsEmu) is a
   measured result, not a guarantee - always re-render and look (rule 10/8c), because a stress
   test (filling real, edge-case-length content into every WARN-flagged table slide and actually
   rendering the result, not just trusting the heuristic) found three distinct root-cause bugs in
   this function and in `Test-PptxTableOverflowRisk`'s pre-render heuristic, now fixed in
   `PptxGates.psm1`:
   - **The font floor can silently fail to fit even after flooring.** Shrinking to the 9pt floor
     plus shifting the neighbor shape as far down as the slide allows is still sometimes not
     enough room for a genuinely dense table (found on a 16-row Applicability table with no
     neighbor shape to push). When that happens the function now reports it honestly via the
     `StillOverflowsEmu` field (> 0 EMU still needed) and an explicit Reason string, instead of
     silently claiming `Applied=true, "...to fit"` while rows actually run off the bottom edge of
     the canvas and are never rendered. `Test-PptxTableOverflowRisk` mirrors this with
     `UnfixableAtAutosizeFloor` (measured at the real 0.6-floor scale, not a linear guess), which
     `validate-deck.ps1` fails the build on - but only when the floor was genuinely reached
     (`scale -le 0.6`); a residual from the ordinary heuristic-vs-render rounding gap in the
     (0.6, 0.95] range is ordinary and stays a WARN, not an ERROR.
   - **The "shape below the table" the function shifts out of the way must actually BE below the
     table, not merely lower on the slide or merely intersecting its left edge.** The original
     neighbor search only checked that a candidate shape's `y` was at or below the table's own
     top `y`. That missed two real cases, both found by rendering an autosized slide and
     comparing it against the raw template's render: (a) a shape positioned beside the table (a
     free-floating "Business Capabilities" guidance box on slide 9) got treated as "the next
     shape" and shifted ~2.9in down into an unrelated box further down the slide; (b) a narrow
     free-floating label box meant to sit alongside a specific row (e.g. a "SIBS tribe lead"
     left-margin annotation on slide 35) has a `y` that falls INSIDE the table's own declared
     vertical span, not below it, and got shifted away from the row it was labelling. The
     candidate filter now requires (1) the candidate's top to be at or below the table's own
     declared BOTTOM, not just its top, and (2) the candidate's horizontal span to overlap the
     table's by at least half of whichever is narrower - not merely touch it.
   - **The 9pt font floor must never ENLARGE a run that was already smaller than 9pt by the
     author's own deliberate choice.** The shrink-to-fit code clamped every run's new size to
     `Max(9pt, computed)`, which is correct when starting from a larger font but silently grows a
     run that was already set to e.g. 7pt (common on a dense sample table, such as the Costs
     slide's "Example" table) up to 9pt - enlarging text that already fit and pushing a table that
     rendered cleanly in the raw template into genuine overflow after "autosizing" it. Found by
     rendering an autosized slide whose `FontScale` was reported as a harmless 95% (i.e. looked
     like a shrink) and comparing it against the raw template's render: the actual `sz` in the XML
     had gone from 700 to 900. The clamp is now `Min(origSz, Max(9pt, computed))` per run - the
     floor still prevents shrinking below 9pt, but never raises a run above where it already was.
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
    present, **plus leftover-highlight and leftover-template-instruction-text checks on every
    visible, non-SKIP slide**). Do not hand over a deck that fails validation. A real delivered
    deck once shipped 420 unstripped highlight runs and several literal "Insert here..." /
    "[PROJECT NAME]" slides because nothing enforced rules 4 and 8 - `validate-deck.ps1` now
    FAILS on exactly that, so there is no "I'll remember to strip it" step left to skip. If it
    fails: for highlight, call `Remove-PptxHighlight` on the reported slides; for leftover
    instruction text, actually replace or delete it (rule 8) - never hide the slide to dodge
    the check unless it is genuinely not applicable (then hide it per rule 5, which excludes it
    from the check entirely).
    **If a flagged slide cannot be filled because the real content is unknown (not because it was
    skipped), that is NOT a reason to leave it failing or to report the deck as "done anyway" - it
    is an open question for `open-questions-consolidation` (rule 12) to route to whoever has the
    answer (PGA / MOA / Finance / Cloud-Infra / Security / DPO / EA). A real delivery once reported
    a deck as complete while ~50 slides still failed this exact check, with the content gap simply
    narrated in a chat summary instead of routed anywhere actionable - do not repeat that.**
11b. **Every TBD/placeholder this skill leaves on a slide must also exist as an open question
    somewhere `open-questions-consolidation` can see** - either on this deck's own
    `${project_name}_Architecture_Gates_README.md` (the deliverables-status table already serves
    this for annex links) or by adding a short note here if the gap is slide-content-only and not
    already tracked by another skill's README. A placeholder that exists only inside the `.pptx`
    XML, invisible to every README-scanning tool, is a silent gap - never create one.
11. **Output** is a new .pptx saved to the per-project output folder `output/${project_name}/`
    (create it if missing - see the `output-convention.md` steering, single source of truth for
    output location; or a path the user gives), e.g. `${project_name}_Architecture_Gates_G<n>.pptx`,
    plus the gates README `${project_name}_Architecture_Gates_README.md` in the same folder. Never
    overwrite the template.
12. **Never declare the dossier/AGD "done", "ready to publish" or "complete" without running
    `open-questions-consolidation` first and reporting its total.** This skill sits at the end of
    the pipeline (it aggregates everyone else's deliverables), which makes it the natural place
    where a false "all done" verdict gets stated - and where a real delivery stated exactly that
    while `validate-deck.ps1` was failing and 100+ items were open across the other 7 READMEs.
    Before any final report: run `open-questions-consolidation`'s
    `build-questionnaire.ps1` against `output/${project_name}/`, and state the total open-item
    count and which roles still have pending items. A non-zero total and "ready to publish" are
    mutually exclusive sentences - say "pre-fill ready, N open items pending (see the
    questionnaire)" instead. See the `open-questions-convention.md` steering.

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
8. Run `open-questions-consolidation` (`build-questionnaire.ps1`) against
   `output/${project_name}/` to refresh `${project_name}_Open_Questions_Questionnaire.md` across
   ALL deliverables, not just this deck — rule 12.
9. Save the copy + the gates README, and report what was filled, what `validate-deck.ps1` still
   flags, and the questionnaire's total open-item count by role. Never say "done"/"ready to
   publish" while either is non-zero — say what is pre-filled and what is pending, and from whom.
