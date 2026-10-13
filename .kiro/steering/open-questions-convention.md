# Open-questions convention - who answers what

> **Why this exists.** Every generation skill correctly refuses to invent unknown values and
> marks them `TBC`/`TBD`/`<placeholder>` in its own README. But those READMEs stayed siloed: a
> real run produced 8 separate files with 100+ scattered open items and nobody - neither the tool
> nor the project owner - ever assembled "what does Lara/the PGA actually need to go find out, and
> from whom". The tool then reported the dossier as "done" while nothing was actually answerable
> as-is. This steering fixes the ROOT CAUSE: it is NOT the chat/session that should interactively
> interrogate the user turn by turn (a session may run unattended, or the answerer may not be the
> person running the tool at all) - it is a **deliverable**: a consolidated, addressed
> questionnaire that the `open-questions-consolidation` skill assembles from every other skill's
> open items, grouped by who must answer. The DELIVERY channel (SFS Assist, a dedicated app, email,
> a REUNIS/ServiceNow ticket...) is intentionally undecided and out of scope here - this convention
> only fixes the CONTENT so any future channel can consume it.

## The fixed role vocabulary
Every open item routes to exactly one or more of these roles (use these exact labels - the
consolidator matches on them):
- **PGA** - the project's chef de projet / Project Gate Analyst / project owner. Default/catch-all
  for anything only the project team can state (scale assumptions, PRD code status, REFLEX names,
  whether a pipeline/SIEM/profile exists, scope confirmations). If unsure which role, use PGA -
  they can always re-route internally.
- **MOA** - the business owner (maitrise d'ouvrage). Business-risk acceptance, DICT/CIAT
  validation, availability expectations, business-profile sign-off.
- **DPO** - personal-data / GDPR applicability and special-category data questions.
- **Security** - the SFES Cybersecurity team. Threat-model scenario/score validation,
  countermeasure confirmation, C-level sensitivity arbitration.
- **Finance** - daily rates, FX rate, license/hardware budget, backlog cost validation.
- **Cloud-Infra** - AWS Calculator figures, sizing/consumption metrics, Landing Zone / cross-account
  questions, SIEM product infra cost.
- **EA** - the Enterprise Architect. Non-applicable-domain confirmations, architecture trade-offs.

## Mandatory tagging format (going forward, in any skill a human later edits)
Every bullet in a skill's "Open questions" / "Missing information" section should end with:
```
- [ ] <plain-language question, no internal jargon> - **Ask:** <Role>[, <Role2>]
```
Example: `- [ ] What is the internal daily rate (k EUR/JH) to use for this project? - **Ask:** Finance`

## Until every script emits the tag - keyword fallback
Several existing scripts (e.g. `cost-estimation/assets/scripts/costs-readme.ps1`) still emit plain
missing-item strings with no tag (e.g. `"global IT Q1 amount"`). The consolidator
(`open-questions-consolidation`) must still work on these TODAY, so it falls back to the keyword
routing table in `open-questions-consolidation/references/role-routing.md` whenever a line carries
no explicit `- **Ask:**` tag. An explicit tag always wins over the keyword fallback. Treat adding
the explicit tag to a script's generated strings as a welcome, low-risk improvement whenever that
script is touched for another reason - never a prerequisite to running the consolidator.

## The non-negotiable consequence for every skill
No skill, and no final AGD/dossier report, may state a deliverable or the overall submission as
**"done" / "terminé" / "complete" / "ready to publish"** while it has open items reachable by this
convention. The correct status is **"Pre-fill ready - N open item(s) pending input (see the
consolidated questionnaire)"**. See `open-questions-consolidation/SKILL.md` for the deliverable that
makes this checkable rather than a matter of the agent's own honesty.
