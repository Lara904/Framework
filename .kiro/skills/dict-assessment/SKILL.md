---
name: dict-assessment
description: Estimate and explain the DICT / CIAT security-need rating (Availability, Integrity, Confidentiality, Traceability) of an application, based on the official PSA-STSSI_003 standard bundled with the skill. Answers DICT/CIAT questions and writes a README that historizes the estimate and its rationale.
keywords:
  - DICT
  - CIAT
  - DICT/CIAT
  - security need
  - availability
  - integrity
  - confidentiality
  - traceability
  - RTO
  - RPO
  - STSSI_003
  - risk rating
  - GDPR
  - personal data
---

# DICT / CIAT Assessment

This skill estimates and explains the **DICT** security-need rating of an application, and
answers questions about DICT/CIAT. DICT = **D**isponibilite (Availability), **I**ntegrite
(Integrity), **C**onfidentialite (Confidentiality), **T**racabilite (Traceability). It is the
same set of criteria as **CIAT** (Confidentiality, Integrity, Availability, Traceability) - only
the letter order differs.

Authoritative source: **PSA-STSSI_003 - Evaluation of the DICT** (ISS technical standard),
bundled at `assets/STSSI_003_EN-Evaluation_of_the_DICT.pdf`. Each criterion is rated on a scale
of **1 (weak) to 4 (critical)**. The DICT is a mandatory deliverable of the preliminary study,
validated by the business owner (MOA) and kept up to date; it feeds the SIBS Architecture Gates
"Project Synthesis" slide (RTO/RPO/SLA are related but distinct - see the reference).

## When to use this skill
- Estimate the DICT/CIAT (D, I, C, T levels) of an application.
- Explain what a criterion or a level means, or how to choose a level.
- Handle the personal-data (GDPR) floor rule and the `DICT = max(standard, GDPR)` rule.
- Produce or update the DICT README that historizes the estimate and its rationale.

## Reference (bundled - load on demand)
- `assets/STSSI_003_EN-Evaluation_of_the_DICT.pdf` - the authoritative standard (source of truth).
- `references/dict-scales.md` - the four criteria and their 1..4 level tables, distilled from
  the standard (use this for quick answers; cite the PDF as the authority).
- `references/personal-data-gdpr.md` - the GDPR floor rule for personal data and
  `DICT = max(DICT standard risks, DICT GDPR)`.
- `references/rto-rpo.md` - RTO/RPO scales (CMDB-aligned) that accompany the DICT on the gate.
- `references/readme-template.md` - the DICT README deliverable format.
- `references/faq.md` - common DICT/CIAT questions and precise answers.

## Deliverable (always produce/update it)
`${project_name}_DICT_README.md` in the per-project output folder `output/${project_name}/`
(create it if missing - see the `output-convention.md` steering, single source of truth for output
location): historizes the estimate (D/I/C/T values, RTO/RPO,
SLA), the rationale per criterion, the GDPR check, assumptions, open questions, and a change
history. Use `references/readme-template.md`. Regenerate/update it whenever the estimate changes.

## Core rules (always apply)
1. **The standard is the authority.** Answer from `references/dict-scales.md` for speed, but the
   bundled `assets/STSSI_003...pdf` is the source of truth; cite it.
2. **Never invent the final rating.** D/I/C/T levels are validated by the business owner (MOA)
   and aligned with the CMDB. You may PROPOSE a value as an explicit "assumption to validate"
   (clearly marked `TBD - to validate with MOA/DPO`), with the reasoning, but never present it
   as final. Tag each open item `- **Ask:** MOA`/`DPO` per
   `.kiro/steering/open-questions-convention.md` so `open-questions-consolidation` routes it to
   the right person instead of it waiting, unasked, in this README.
3. **Apply the GDPR floor.** If the application processes personal data, apply the minimum DICT
   from `references/personal-data-gdpr.md`, then `DICT = max(standard-risk DICT, GDPR DICT)`.
4. **A legal/regulatory traceability constraint forces T = 4.**
5. **Explain, don't just score.** For every proposed level, give the one-line justification tied
   to the standard's scale.
6. **English only, ASCII-safe.** Write the README and answers in English; avoid mojibake
   characters (use `-`, straight quotes; write accented French terms without accents if needed).
7. **Historize.** Every change to the estimate appends a row to the README change history
   (version, date, author, what changed and why). Never rewrite history.

## Quick workflow
1. Gather inputs: what the app does, data handled (esp. personal data), availability need,
   integrity/confidentiality stakes, traceability/regulatory needs, CMDB references.
2. Rate each criterion 1..4 using `references/dict-scales.md` (propose values as assumptions to
   validate when the business input is missing).
3. Apply the GDPR floor and `max()` rule - `references/personal-data-gdpr.md`.
4. Add RTO/RPO/SLA context - `references/rto-rpo.md`.
5. Write/update `${project_name}_DICT_README.md` in `output/${project_name}/` -
   `references/readme-template.md` - with rationale, assumptions, open questions and a
   change-history row.
6. Report the estimate, the rationale, and what still needs MOA/DPO validation.
