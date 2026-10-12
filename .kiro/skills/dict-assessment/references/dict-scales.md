# DICT criteria and level scales

Distilled from PSA-STSSI_003 (bundled at `assets/STSSI_003_EN-Evaluation_of_the_DICT.pdf`).
The PDF is the authority; use these tables for quick answers and cite the standard.

DICT = Disponibilite (Availability), Integrite (Integrity), Confidentialite (Confidentiality),
Tracabilite (Traceability). Same criteria as CIAT (different letter order). Each rated 1..4.

## General impact scale (context for all criteria)
Levels reflect impact on the Group across economic / client-image / legal / HR axes:
- 1 = Weak, 2 = Moderate, 3 = Strong, 4 = Critical.
(Economic guide: 1 < ~1M; 2 = 1-10; 3 = 10-50; 4 > 50 - orders of magnitude from the standard.)

## D - Availability (max tolerable duration of non-accessibility)
Consider means of substitution already in place before rating.
| Level | Max tolerable unavailability |
|-------|------------------------------|
| 1 | more than 48 hours |
| 2 | between 12 and 48 hours |
| 3 | between 4 and 12 hours |
| 4 | less than 4 hours |

## I - Integrity (importance of replacing/restoring altered/destroyed assets)
| Level | Meaning |
|-------|---------|
| 1 | Weak |
| 2 | Moderate |
| 3 | Strong |
| 4 | Critical |

## C - Confidentiality (impact of disclosure + access restriction)
| Level | Label | Meaning / access |
|-------|-------|------------------|
| 1 | Non Sensitive | No effect if disclosed; accessible without restriction. |
| 2 | PSA Sensitive | Perceptible impact (IP disclosure, short-term image damage); accessible to people within PSA/SFS or partners in the Group's activities. |
| 3 | PSA Confidential | Critical impact (loss of competitive elements, regulatory breach, image/trust loss); accessible to a limited number of named/role-identified people. |
| 4 | PSA Secret | Crippling impact on the Group/its strategy; accessible to a very limited number of named persons under strict owner control. |

Note (from the data section): if personal data is present, confidentiality is typically raised
(commonly C3), except when the VIN code is the only personal information (then C2). C4 for a data
initiative means it is automatically not approved. See `personal-data-gdpr.md`.

## T - Traceability (surveillance / control / audit-evidence need)
| Level | Meaning |
|-------|---------|
| 1 | Standard IT logs are sufficient for the traceability need. |
| 2 | Operational need for systematic surveillance/control (periodic or on-event state); must form and keep data (date, time, identities, ...). |
| 3 | High-level or regulatory need imposing systematic action; must form and keep such data. |
| 4 | Very high-level or regulatory need; must form/keep data AND preserve its integrity. |

Rules of thumb from the standard:
- A **legal/regulatory** constraint imposes **T = 4**.
- Likely T = 3 or 4 when the app must protect against fraud / erroneous use of financial data /
  loss of financial transactions; track parameter changes; recover deleted data; prove actions
  (regulatory); follow access-right attributions; or when any of D/I/C = 4.

## How the DICT is used
- It determines the risk-reduction measures to implement (per the PSA-DSSI_04 directive).
- Values must be consistent with the CMDB and validated by the business owner (MOA).
- Analysis considers interdependencies with other IT applications (a dependency with a weaker
  DICT/SLA may require a workaround: retry, design for failure).
