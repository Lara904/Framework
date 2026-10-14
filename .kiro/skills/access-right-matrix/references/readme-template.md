# Companion README template (transient - delete after completion)

The README is a **temporary working file** used ONLY to gather missing information and
track open questions. Name it `${project_name}_access_right_matrix_README.md`. Once all
information is collected and the `.xlsx` deliverable is fully filled (no unresolved
required placeholder), **delete this README** - the only deliverable is the `.xlsx`.

Use the structure below.

```markdown
# <Project> - Access Right Matrix - working notes (transient)

> Transient file. The deliverable is `<Project>_access_right_matrix.xlsx`.
> Delete this README once all information below is resolved and written to the .xlsx.

## Status
- Deliverable: `<Project>_access_right_matrix.xlsx`
- Template: SFS Right matrix v2.6 (2026-03), ref SIBS_M2C_DIR_OPE_DEL_AWS_001
- Last generated: <YYYY-MM-DD>

## Collected information (APPLICATION Information)
| Field | Value | Source |
|---|---|---|
| PRD code | <PCHK / TBD> | <who> |
| REFLEX technical name | <... / TBD> | |
| REFLEX functional name | <... / TBD> | |
| DICT | <D I C T / TBD> | *_DICT_README.md |
| Functional description | <... / TBD> | |
| REFLEX name DEV / PRE / PROD | <... / TBD> | |

## Profile scope decisions
- AWS NG Landing Zone + standard SFS CI/CD: <yes/no>
- Technical profiles not used for this scope: <list or "none">
- Business profiles: <list, or "No business profile for this scope">
- Derogations: <e.g. DEV+OPS cumulative from Cloud Center Tools: yes/no>

## Open questions (must be empty before deleting this README)
- [ ] <question 1>
- [ ] <question 2>
```

## Rule
- Every `TBD` / unchecked open question here corresponds to a placeholder still visible
  in the `.xlsx`. The README may be deleted only when this section is empty and the
  deliverable carries no unresolved **required** value (a `<PRD>` token must be gone; a
  REFLEX_NAME descriptive placeholder may remain if the org keeps it deliberately).
- **If an "Arbitrary default choices" section was added** (per
  `.kiro/steering/open-questions-convention.md`, for any value that could not be sourced and was
  given an explicit reasoned placeholder instead of staying blank) - **that section must ALSO be
  empty, or every one of its rows resolved and removed, before this README is deleted.** An
  arbitrary default is not a confirmed fact: deleting a README that still has open rows there
  would silently remove those items from `open-questions-consolidation`'s questionnaire with no
  trace, since the consolidator can only see what is still written in a `*_README.md` file. This
  is the one skill in the framework whose own template says to delete its working file, so it is
  the one place this silent-loss risk can actually happen - check both sections, not just "Open
  questions", before deleting.
