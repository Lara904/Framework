# Fallback rule when a DICT criterion has NO business input

## The problem this fixes

Rule 2 ("propose a value as an assumption to validate") is the right rule when there is SOME
business signal to reason from, even an indirect one (the app handles financial data, so
Integrity is probably not 1; the app has end users who would notice an outage, so Availability is
probably not 4). It breaks down silently when a criterion has genuinely nothing to reason from -
the source material simply never addresses it (common for **Traceability**, which almost no
project brief mentions unless it is already a known regulatory item; occasionally for one of the
other three on a very thin brief). Left to "propose a value" with no anchor, the agent ends up
picking a number from general plausibility, and - because that reasoning is produced fresh each
time - a different run, a different day, or a different agent can land on a different number for
the exact same kind of gap, with no way for anyone reviewing the output to tell "the business told
us this" from "the tool guessed this, and here is what it happened to guess today".

That inconsistency has a direct, non-symmetric cost: a guessed-low value silently understates the
true risk-reduction need (the application ships under-protected relative to what a correct rating
would have required), while a guessed-high value only costs some extra, harmless diligence. The
fallback rule below is deliberately **conservative in the direction of flagging more need, not
less** - it is not trying to guess the "most likely true" value, it is trying to guess the value
least likely to leave an under-protected gap unnoticed.

## The rule

When, after genuinely checking the brief, the NFR inputs, any functional/technical README already
produced for this project, and the CMDB reference if available, a DICT criterion has **no stated
business value of any kind** (not a vague one - a complete absence):

1. **Availability (D)**: fall back to the level implied by whatever RTO/RPO value the sources DO
   state (see `rto-rpo.md` for the CMDB-aligned mapping) - Availability and RTO/RPO answer closely
   related questions, so a stated RTO is usually a usable proxy even when D itself was never
   named. If RTO/RPO is also absent, fall back to **level 2** (12-48h), not level 1 - level 1
   (more than 48h tolerable) is a strong claim ("this can be down for two full days with no
   business impact") that should be stated, not assumed by default; level 2 is the more
   defensible silent default for an application important enough to be going through an
   architecture gate at all.
2. **Integrity (I)**: fall back to **level 2** (Moderate) by default. If the sources describe the
   data as feeding any financial, contractual, or downstream-automated-decision process (even
   without naming Integrity explicitly), fall back to **level 3** instead - the standard's own
   rule of thumb already ties I=3/4 to exactly this kind of data (see `dict-scales.md`).
3. **Confidentiality (C)**: do not apply a no-input fallback in isolation - Confidentiality should
   already be derivable from the flow inventory's own per-flow classification (if flows are
   classified C1-C4 anywhere in the sources, the application-level C is at least the maximum of
   those) and from the GDPR floor rule (`personal-data-gdpr.md`) if personal data is present. If,
   unusually, truly nothing classifies any flow or data at all, fall back to **level 2** (PSA
   Sensitive) rather than level 1 - silently assuming "no effect if disclosed" for data nobody has
   actually characterized is the understatement direction this rule exists to avoid.
4. **Traceability (T)**: this is the criterion most likely to have zero input. Fall back to
   **level 2** (Operational need for systematic surveillance/control), not level 1. Level 1
   ("standard IT logs are sufficient") is itself a claim that should be actively stated, not
   assumed by silence - and the standard's own rule of thumb (`dict-scales.md`) flags T=3/4 as
   likely whenever financial data, parameter changes, or access-right tracking are in play, which
   describes a large share of the applications this framework is used for. Level 2 is the
   middle ground that does not silently commit to "nothing special needed" by default, while not
   jumping to a regulatory-strength T=4 that nothing in the sources supports either. **Do
   escalate past level 2** when the apparent nature of the data makes level 2 obviously
   understated for the SAME reasons described in rule 4 of the main SKILL.md (any genuine
   legal/regulatory traceability constraint still forces T=4, source or no source) - this fallback
   sets the floor when there is truly nothing to go on, it does not cap the rating when there is.

## How to record it (mandatory format)

This is NOT a bare `TBD` line in "Missing information", and it is NOT silently written into the
Summary table as if it were a normal proposed-from-evidence value (rule 2). Per
`.kiro/steering/open-questions-convention.md`'s "Arbitrary default choices" section:

1. Add (or append to) a `## Arbitrary default choices (pending validation - explicit placeholders,
   NOT confirmed facts)` section in the DICT README, with one row per criterion that used this
   fallback:

   | Criterion | Default applied | Why no business input was found | Ask |
   |-----------|------------------|-----------------------------------|-----|
   | Traceability (T) | 2 (no-input fallback - see `no-input-fallback.md`) | Checked the brief, the NFR inputs, and the functional/technical READMEs; none states a traceability need or constraint. | - **Ask:** MOA |

2. The Summary table in the README still shows the fallback number (so every downstream
   calculation - the NFR relevance filter, the `max()` rule, the gate deck - has a usable value to
   work with), but its row is annotated, e.g. `T | 2 (fallback - see Arbitrary default choices) |
   No business input found`.
3. Do NOT also list the same criterion under "Open questions" or "Missing information" - per the
   steering convention, an item lives in exactly one of the three section types, and a fallback
   value is an "Arbitrary default choice" by definition, not a blank.
4. If `nfr-requirements` or any other downstream skill consumes this DICT value, it should treat
   it exactly like any other DICT value for computation purposes, but its own README should note
   that the relevance/status decisions resting on this criterion inherit the "pending validation"
   status - a stricter true value discovered later (through rule 4, "a legal/regulatory
   traceability constraint forces T=4", or through the MOA actually answering) can change which
   NFRs are relevant, and that recomputation should be flagged, not silently skipped (see the
   `nfr-requirements` README's own notes mechanism for this).

## What this rule deliberately does not do

- It does not replace rule 2 (reasoned proposals from indirect evidence) - use this fallback only
  when there is truly no evidence to reason from, not as a shortcut to skip the reasoning in rule
  2 when evidence does exist.
- It does not pretend to know the true value - it picks the specific number that a wrong guess is
  least costly to be wrong about, given the understate/overstate asymmetry described above. A
  human (MOA, DPO, or Security as appropriate) confirming or correcting this value remains
  mandatory; this rule only makes the interim number predictable and auditable instead of
  freshly-invented per run.
