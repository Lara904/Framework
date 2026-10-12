# DICT levels and the NFR filter (reference)

Distilled from the reference model and the source NFR assistant. Use this to explain WHY the
filter macro marks an NFR relevant, and to sanity-check a DICT before running the macro. The
macro remains the only authorised way to actually fill the Relevant column.

## DICT / CIAT levels (1..4)

| Level | D - Availability | I - Integrity | C - Confidentiality | T - Traceability |
|-------|------------------|---------------|---------------------|------------------|
| 1 - Weak     | > 48 h                | Impact < 1 M EUR      | Non-sensitive - public / unrestricted        | Standard IT logs sufficient |
| 2 - Moderate | 12 to 48 h            | Impact 1 to 10 M EUR  | PSA Sensitive - PSA/partners only            | Systematic data (date, time, ID) kept |
| 3 - Strong   | 4 to 12 h             | Impact 10 to 50 M EUR | PSA Confidential - limited / named access    | Regulatory / high-level systematic action |
| 4 - Critical | < 4 h                 | Impact > 50 M EUR     | PSA Secret - strict owner control            | Log integrity preservation mandatory |

Official DICT document (DocInfo): https://docinfogroupe.stellantis.com/ead/doc/ref.20596_18_00231/v.vc/pj

## How each filter column triggers an NFR

| Filter column | The NFR applies when... | Owning group |
|---------------|-------------------------|--------------|
| D1..D4 | the system's Availability level is at/above the marked digit(s) | Security |
| I1..I4 | the system's Integrity level is at/above the marked digit(s) | Security |
| C1..C4 | the system's Confidentiality level is at/above the marked digit(s) | Security |
| T1..T4 | the system's Traceability level is at/above the marked digit(s) | Security |
| RTO | the system's infrastructure/DRP class matches (1: <4h ... 4) | Technical Integration |
| Data privacy | the system processes personal data (GDPR); also forces a min DICT floor (approx x222, T>=2) | Data privacy |
| SOX | the system is in SOX scope (financial transactions, bank details, payroll) | SOX / Audit |

In the distilled `nfr-catalog.md`, a trigger like `C34` means "columns C3 and C4 are marked", i.e.
relevant when C is 3 or 4. `C1234` means all four C columns are marked, i.e. always relevant on C
(even at C=1). `DP`/`SOX` map to the Data privacy / SOX columns; `RTO=n` to the RTO class.

## Notes
- A `No dispense possible` NFR is always mandatory when relevant - it cannot be set Not relevant
  (use Status = Not feasible + contingency if truly impossible).
- Personal-data (GDPR) systems: apply the DICT floor before running the filter (see the
  `dict-assessment` skill), because a higher DICT triggers more NFRs.
- Sub-variants (e.g. NFR-6507a..i, NFR-5404a..d, NFR-5203a..d) are distinct levels/scenarios of
  the same requirement and are NOT interchangeable; the macro selects which variant is relevant
  from the DICT/RTO context.
