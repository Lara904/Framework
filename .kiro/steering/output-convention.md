---
inclusion: always
---

# Deliverable output convention (single source of truth)

This file is the ONE place that defines WHERE skills write the deliverables they produce. Every
skill references this convention instead of hard-coding an output location, so the rule can change
in one place and stay consistent across the whole framework.

## The rule

Every skill that produces a deliverable (document, workbook, diagram, deck, model JSON, or its
audit-trail README) writes it under a per-project output folder at the project root:

```
output/${project_name}/
```

- `${project_name}` is the framework's existing naming variable - the SAME prefix every skill
  already uses for its deliverable filenames (e.g. `${project_name}_functional_architecture_document.docx`).
  It is obtained generically from the active project context, never hard-coded in a skill or script.
- A skill creates `output/${project_name}/` if it does not exist, then writes there.
- The deliverable filename convention is unchanged: `${project_name}_<domain>_<kind>`. Only the
  **location** moves, from the bare project root to `output/${project_name}/`.
- The companion audit-trail README of each deliverable goes in the SAME folder as the deliverable.

### Why a per-project subfolder

The framework is meant to run across several projects in the same workspace. Writing every
deliverable to the bare project root does not scale: files from different projects collide (shared
names) and the root becomes unreadable. Scoping outputs to `output/${project_name}/` gives each
project an isolated, predictable home and keeps the root clean.

## What this convention does NOT change

- **Scratch / transient files** still go to `.kiro/.temp_ai/<agent>/` (see `command-execution.md`),
  NEVER to `output/`. `output/` holds finished deliverables only.
- **Read-only sources** (`sources/`) and **bundled skill assets** (`.kiro/skills/**/assets/`) are
  untouched: this convention is about generated OUTPUT, not inputs or templates.
- The **naming** of deliverable files (prefix, domain, kind) is defined by each skill and unchanged.

## How scripts receive the path (stay generic)

The bundled generators/validators (`build-*.ps1`, `*-readme.ps1`, `find-missing.ps1`, ...) take the
output path as a parameter (typically `-Out`) and resolve a relative path against the current
directory. They do NOT embed any output folder. The CALLER (the skill, per this convention) passes
`output/${project_name}/<filename>` as the target. This keeps the scripts reusable with any path
and keeps the location decision in this single source of truth.

## Publication

`output/` holds real, project-specific deliverables and is **never published**. It is excluded by
pattern in `.gitignore` (`output/`), the same way `sources/` is. Nothing under `output/` is
framework material.

## Migrating an existing project (informational - not automatic)

Deliverables created before this convention may still sit at the bare project root. Moving them is
a manual, human decision (it can break links already posted elsewhere). To migrate, create
`output/${project_name}/` and move the existing `${project_name}_*` deliverables and their READMEs
into it. The framework will not move existing files on its own.
