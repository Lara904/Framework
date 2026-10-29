---
name: open-questions-consolidation
description: After the generation skills (functional-architecture, technical-architecture, dict-assessment, nfr-requirements, cost-estimation, access-right-matrix, threat-modeling-prefill) have run, scan every deliverable README they produced and assemble ONE consolidated, addressed questionnaire of everything still missing, grouped by who must answer it (PGA/project owner, MOA, DPO, Security, Finance, Cloud-Infra, Enterprise Architect). This is a deliverable, not a chat interrogation - the delivery channel (SFS Assist, a dedicated app, email, a ticket) is not decided yet; this skill only produces the content so any future channel can send it. Never declares a dossier "ready to publish" while it has open items.
keywords:
  - open questions
  - questionnaire
  - missing information
  - consolidation
  - PGA
  - chef de projet
  - MOA
  - DPO
  - finance
  - security team
  - enterprise architect
  - architecture gates
  - ARB
  - TCC
  - gate 2
  - readiness
---

# Open-Questions Consolidation

This skill is the missing last mile of the "never invent - ask instead" rule every other skill
already follows. Each generation skill correctly refuses to invent an unknown value and marks it
`TBC`/`TBD`/a placeholder in **its own** README's "Open questions" / "Missing information" /
"Assumptions" section. But nothing ever gathered those across the 7-8 READMEs a full run
produces, so a real run shipped 100+ scattered open items while the final report said "tout est
terminé" - which is exactly backwards: **the dossier is not ready until someone outside the tool
has answered what the tool could not know**. This skill produces the single artefact that makes
that visible and actionable: one questionnaire, addressed by role.

> **This is not an interactive Q&A inside the chat.** A session may run unattended, and the person
> who can answer a question (DPO, Finance, Security team) is very often not the person who ran the
> tool. So the fix is not "stop and ask in the conversation" - it is "produce a clean, addressed
> list of what to go ask, and to whom". See `references/open-questions-convention.md`-equivalent
> steering (`.kiro/steering/open-questions-convention.md`) for the role vocabulary and the tagging
> convention every other skill's open-items should eventually use.

## When to use this skill
- After one or more generation skills have produced/updated a `*_README.md` in
  `output/${project_name}/`, to refresh the consolidated questionnaire.
- Before any report that claims the dossier/AGD is "ready" or "complete" - this skill's output is
  the evidence for or against that claim.
- When the project owner (or anyone) asks "what's still missing, and from whom?"

## Bundled assets
- `references/role-routing.json` - the fixed role vocabulary (PGA, MOA, DPO, Security, Finance,
  Cloud-Infra, EA), the default role, and the ordered keyword-fallback rules. Single source of
  truth - never duplicate the rules elsewhere.
- `references/role-routing.md` - human-readable explanation of the JSON above.
- `assets/scripts/build-questionnaire.ps1` - the scanner/renderer (see below).

## Deliverable (always produce/refresh)
`${project_name}_Open_Questions_Questionnaire.md`, written to the per-project output folder
`output/${project_name}/` (see the `output-convention.md` steering) - one section per role (PGA,
MOA, DPO, Security, Finance, Cloud-Infra, EA), each listing that role's open items in plain
language with which deliverable they block, plus a summary count table and a change-history
section. A role with zero open items still gets its section, saying so explicitly - an absent
section would read as "nobody checked", not "nothing pending".

## Core rules (always apply)
1. **Read-only on every other deliverable.** This skill only scans `*_README.md` files already
   produced by other skills; it never edits them and never invents an answer itself - it only
   routes and reformats what is already honestly marked as missing elsewhere.
2. **Explicit tag wins; keyword routing is only the fallback.** If a scanned line ends with
   `- **Ask:** <Role>`, use exactly that role (or roles). Otherwise apply
   `references/role-routing.json`'s keyword rules, in order; if nothing matches, route to the
   default role (**PGA**) rather than dropping the item.
3. **Every known role gets a section, even an empty one.** "No open question for this role right
   now" is a real, useful answer - never omit a role because it happens to have zero items this
   run.
4. **Regenerate, don't hand-patch.** Re-run the script after any upstream README changes; it
   re-scans from scratch each time, so a question that got answered (its README line removed/
   changed) automatically disappears here too. Preserve the change-history rows across runs (the
   script does this by reading its own previous output before overwriting).
5. **Never claim the dossier is ready while this file has open items.** Any report that assembles
   or summarizes the overall AGD/dossier (notably `presentation-gates`) MUST run this skill first
   and state the **total open-item count** and **which roles** still have pending items - "ready
   to publish" and a non-zero total here are mutually exclusive statements.
6. **This skill does not decide or implement a delivery channel.** Producing the questionnaire
   content is the whole scope. Whether/how it reaches SFS Assist, a standalone app, an email or a
   ticket is a separate, not-yet-designed decision - do not block on it, and do not simulate
   sending anything.
7. **English, ASCII-safe, UTF-8 without BOM.**
8. **A wrapped bullet is read as one item, not just its first physical line.** Writing a question's
   text and its `- **Ask:** <Role>` tag on one physical line is the house convention, but a real
   README defect slipped past it anyway (the question text ran long and the tag landed on an
   indented second line). Before this was fixed, `build-questionnaire.ps1` resolved each physical
   line in isolation, so the continuation line - tag included - was silently skipped and the
   bullet's first-line-only text fell through keyword routing (or further to the PGA default)
   instead of honoring its explicit tag; several real items were mis-routed this way before the
   mismatch was ever noticed. The script now buffers a bullet across any immediately-following
   **indented** line (the existing continuation convention) and resolves the joined text as one
   unit - verified by regenerating a real project's questionnaire before/after the fix (misrouted
   items moved to their correct role, total count unchanged) and by a synthetic README exercising
   both a wrapped tag and a trailing non-indented stray line (a "---"/"Totals:" footer), confirming
   the footer is correctly NOT absorbed into the previous bullet. Do not "simplify" the script back
   to resolving one physical line at a time - and do not rely on this fallback either: keep writing
   `- [ ] <question> - **Ask:** <Role>` on one physical line wherever practical, since the buffering
   is a safety net, not a license to wrap routinely.

## Quick workflow
1. Confirm `${project_name}` and its output folder `output/${project_name}/`.
2. Run the scanner/renderer:
   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File assets/scripts/build-questionnaire.ps1 `
     -ProjectDir "output/<project_name>" -Project "<project_name>" `
     -Out "output/<project_name>/<project_name>_Open_Questions_Questionnaire.md"
   ```
3. Read the summary line it prints (total + per-role counts) and report it to the user plainly -
   e.g. "47 open items: 18 PGA, 12 Finance, 9 Cloud-Infra, 5 Security, 3 MOA. Dossier is NOT ready
   to publish until these are answered."
4. If any item was mis-routed (kept landing on PGA by default when it clearly belongs to a named
   role), add a new rule to `references/role-routing.json` rather than hand-editing the generated
   file.
5. Point the user at the questionnaire file as the thing to actually send onward (channel TBD),
   not at the 7 individual deliverable READMEs.
