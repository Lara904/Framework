# Steering

Steering files are always-on guidance for the AI in this workspace. This folder separates two
kinds of file, and the distinction matters for publication.

## Generic framework steering (publishable)

These describe HOW the framework works and carry no project-specific content. They ship with
the framework and are safe to publish:

- `command-execution.md` - shell timeout/retry rules and the `.kiro/.temp_ai/<agent>/` scratch convention.
- `skill-authoring.md` - requirements for authoring/maintaining skills (structure, self-containment, OPC-safe generation).
- `office-word.md`, `office-excel.md`, `office-powerpoint.md` - environment constraints for Office automation. These assume Windows/PowerShell + Office COM (no Python/Node). Verify against your environment and adjust the constraints header if it differs.
- `open-questions-convention.md` - the fixed role vocabulary (PGA/MOA/DPO/Security/Finance/
  Cloud-Infra/EA) and the `- **Ask:** <Role>` tag every skill's "Open questions"/"Missing
  information" bullets should use, so the `open-questions-consolidation` skill can assemble one
  addressed questionnaire instead of a run ending in scattered TBCs and a false "done".

## Project pilotage (NOT publishable - stays local)

- `project-context.template.md` - a depersonalized TEMPLATE. This one SHIPS with the framework.
- `project-context.md` - YOUR filled copy (identity, team, roadmap, decisions, internal paths).
  This is pilotage, not framework. It is **git-ignored by pattern** and must never be published.

### How to set up your project context
1. Copy `project-context.template.md` to `project-context.md` in this folder.
2. Replace every `${...}` placeholder and every "(example, fictional)" value with yours.
3. Keep all personal / internal content (names, team, internal URLs or paths, undecided
   governance choices, thesis/dissertation references) in `project-context.md` only.

## Rule: personal pilotage never lands in the repo

The `.gitignore` excludes personal/pilotage steering by **pattern**, not by a single file name:

- `project-context.md` and `project-context.*.md` (the filled, case-specific context);
- any `*.local.md` or `*.perso.md` (add this suffix to any steering you want kept local).

Only `project-context.template.md` is allow-listed back in. If you add another always-on
steering that carries project specifics, name it `*.local.md` (or `*.perso.md`) so it is
excluded automatically. Before publishing, run the leak-scan patterns in `PUBLISHING.md` to
confirm no pilotage content slipped into a publishable file.
