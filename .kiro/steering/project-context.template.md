---
inclusion: manual
---

# Project context - TEMPLATE (fill a local copy, do not publish the filled one)

<!--
NOTE ON FRONT-MATTER: this template is `inclusion: manual` on purpose, so the AI does not load
a file full of `${...}` placeholders as live guidance. Your FILLED copy, `project-context.md`,
should instead use `inclusion: always` so it is always on. (The filled copy is git-ignored.)
-->


> HOW TO USE THIS FILE
> 1. Copy this file to `project-context.md` in the same folder (`.kiro/steering/`).
> 2. Fill the `${...}` placeholders with YOUR project's values.
> 3. The filled `project-context.md` is PILOTAGE, not framework: it is git-ignored by
>    design (see `.gitignore` -> "Personal / project pilotage steering") and must never be
>    published. Only THIS `*.template.md` ships with the framework.
> 4. Keep personal identity, team names, people, internal URLs/paths and undecided
>    governance choices in the filled copy ONLY - never in a skill, a reference or this template.
>
> All `${...}` tokens below are placeholders. All sample values are marked "(example, fictional)"
> and must be replaced; do not ship the examples.

## Who I am / what I am building

I am ${author_role} on the ${team_name} team at ${organization}. I am building
`${project_name}` (working name), a tool that ${project_one_line_goal}.

- Problem it addresses: ${problem_statement}
- Primary outcome: ${primary_outcome}
- Scope boundary (what it is explicitly NOT): ${out_of_scope}

> Example (fictional): "I am a security engineer on the Governance team at ExampleCorp. I am
> building `arb-readiness`, a tool that guides a project team from an idea to a complete,
> auditable architecture-review dossier."

## Functional modules (target scope)

List the modules of the target product. Mark clearly which are in the MVP and which are
target-vision only, so nothing out-of-scope is ever presented as delivered.

1. ${module_1} - MVP: ${yes_no}
2. ${module_2} - MVP: ${yes_no}
3. ${module_3} - MVP: ${yes_no}
   - If a module has several facets, say which single facet is built/tested at MVP and which
     are target-vision extensions (never present extensions as committed).
4. ${module_4} - MVP: ${yes_no}
5. ${module_5} - MVP: ${yes_no}

## Reference pattern (if the `.kiro` is seeded from an existing one)

If this `.kiro` started as a copy of someone else's folder, record it here and treat that
content as REFERENCE describing THEIR project, not yours:

- Source pattern: ${reference_pattern_name_or_none}
- Rule: each inherited skill/steering must be re-read and adapted (goal, inputs, output
  template) before reuse. Do not assume an inherited skill is ready as-is.
- Frozen copy location (read-only, never executed directly): ${reference_folder_or_none}

Principles to keep from the pattern:
- source folder read-only (`sources/`), never modified by the AI;
- isolated scratch folder for transient files (`.kiro/.temp_ai/<agent>/`);
- deliverables written to a per-project output folder `output/${project_name}/` (see the
  `output-convention.md` steering), never work files there;
- specialized, self-contained skills (zippable from one project to another);
- every skill ends by updating its own README as an audit trail.

## Write-scope (read-only / forbidden areas)

Adapt the paths to your project. Keep this list generic - no internal absolute paths.

- `sources/` (and any real-case subfolder): READ-ONLY for every skill, hook and task.
- `${reference_folder_or_none}` (frozen inherited pattern, if any): read-only, never executed.
- Any PERSONAL pilotage folder OUTSIDE this Kiro project (notes, thesis, dissertation,
  personal planning): never read, written or referenced by a skill, a hook or steering.
- No work file at the project root: everything transient goes under `.kiro/.temp_ai/<agent>/`
  (mechanics in the `command-execution` steering).
- Before any publication: confirm the `.gitignore` excludes real sources, generated
  deliverables, personal pilotage files and (per decision) internal binary assets. See
  `PUBLISHING.md`.

## Roadmap (phases)

- ${phase_0} - status: ${status}
- ${phase_1} - status: ${status}
- ${phase_2} - status: ${status}
- ... add phases as needed. Keep decisions and dates in THIS filled copy, not in skills.

## Technical decisions already taken (to respect)

Record only decisions that constrain the work. Keep provider/vendor/product names and internal
service names in this filled copy, never baked into a skill.

- ${decision_1}
- ${decision_2}
- Open (not yet decided), do NOT hard-code a dependency on any option until arbitrated:
  - ${open_decision_1}
  - ${open_decision_2}
- Data classification: ${data_classification_rule}

## Working conventions

- Documentation language - two levels:
  - ${pilotage_language} for what you produce yourself for project steering (plans, notes,
    this steering).
  - ${deliverable_language} for everything the pattern's skills output when they follow an
    official template (these outputs are language-locked by the skills themselves).
- A skill always ends by updating its own README (audit trail).
- Never write a work file at the project root: use the scratch folder.
