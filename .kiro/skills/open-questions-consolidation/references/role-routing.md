# Role routing - keyword fallback

> Single source of truth: **`references/role-routing.json`** (roles, default role, ordered
> keyword rules). This file only explains it for a human reader - never duplicate the rules here;
> edit the JSON to add or tune a rule.

Used by `assets/scripts/build-questionnaire.ps1` when a scanned open-item line carries no explicit
`- **Ask:** <Role>` tag (see the `open-questions-convention.md` steering for the tag format and
the fixed role vocabulary: PGA, MOA, DPO, Security, Finance, Cloud-Infra, EA).

The script tests each untagged line against `role-routing.json`'s `rules`, **in array order**
(first match wins), case-insensitive substring match. If nothing matches, it routes to
`defaultRole` (**PGA** - the project owner can always re-route internally).

## Notes
- A line can legitimately match more than one role (e.g. "SIEM product not yet selected" touches
  both PGA - has the project decided? - and Cloud-Infra - what does it cost once chosen?). The
  script may emit the item under more than one role section when it matches more than one rule
  group, rather than picking one arbitrarily - duplication here is cheaper than a silently dropped
  question. (Current implementation: first-match-wins per role group as coded; revisit if real
  runs show this drops a question that genuinely needed two recipients.)
- Treat a line that keeps routing to PGA by default, when it clearly should go to a specific role,
  as a signal to add a new rule to `role-routing.json` - not as a script bug.
