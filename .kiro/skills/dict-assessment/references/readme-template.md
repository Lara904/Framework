# DICT README - deliverable template

Write `${project_name}_DICT_README.md` to the per-project output folder `output/${project_name}/`
(see the `output-convention.md` steering), in English, using the structure below. It historizes
the DICT estimate and its rationale. Put unconfirmed values under Assumptions and
mark them `TBD - to validate with MOA/DPO`. Append a change-history row on every update; never
rewrite history.

```markdown
# <Application> - DICT / CIAT Assessment

Version: <x.y>  |  Date: <YYYY-MM-DD>  |  Author: <name>
Standard: PSA-STSSI_003 (Evaluation of the DICT)
Status: <Draft / Proposed - to validate / Validated by MOA>

## Summary
| Criterion | Value (1..4) | Basis |
|-----------|--------------|-------|
| D - Availability | <n> | <standard-risk / GDPR floor / max> |
| I - Integrity | <n> | ... |
| C - Confidentiality | <n> | ... |
| T - Traceability | <n> | ... |

DICT (D/I/C/T): **<d>/<i>/<c>/<t>**   |   RTO: <v>   RPO: <v>   SLA: <value>
Computation: DICT = max( standard-risk DICT <d/i/c/t> , GDPR DICT <d/i/c/t> )

## Rationale per criterion
- **Availability (D=<n>)**: max tolerable unavailability <...>; substitution means <...>.
- **Integrity (I=<n>)**: <importance of restoring altered/lost data ...>.
- **Confidentiality (C=<n>)**: <disclosure impact + access level; personal data effect ...>.
- **Traceability (T=<n>)**: <surveillance/audit/regulatory need; legal constraint -> T=4? ...>.

## Personal data / GDPR
- Personal data processed: <yes/no/uncertain - what data>.
- GDPR applicability: <confirmed/to confirm with DPO>.
- Privacy risk level: <C-Serious / D-Important / E-Severe / n-a> -> GDPR floor <d/i/c/t>.

## RTO / RPO / SLA
- RTO = <v> (<meaning>), RPO = <v> (<meaning>), SLA = <value>. CMDB-aligned: <yes/no>.

## Assumptions (to validate)
- <proposed values and why, clearly marked TBD - to validate with MOA/DPO>

## Open questions
- <questions pending with MOA / DPO / CMDB>

## Change history
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1 | <YYYY-MM-DD> | <name> | Initial proposed estimate. |
```

Rules:
- English only, ASCII-safe (avoid mojibake; use `-` and straight quotes).
- Never present proposed values as final; the MOA validates, aligned with the CMDB.
- Every update appends a change-history row (do not edit past rows).
- Keep this README consistent with the value entered on the gate's Project Synthesis slide.
