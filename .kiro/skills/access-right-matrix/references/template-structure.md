# Reference template structure (provenance)

Source of truth (bundled): `assets/templates/SFS_right_matrix_for_ciq_and_CI_CD_AWS_NG_v2026_03.xlsx`
(SFS/SIBS "Right matrix model for CIQ, CI-CD and AWS Console", v2.6 March 2026, ref
`SIBS_M2C_DIR_OPE_DEL_AWS_001`, classification C2 - PSA Sensitive). Reproduced here so
the skill is self-contained; the template file itself is READ-ONLY.

This matrix MUST be completed before any request to create or modify an access service
in **REUNIS**. It records, per application, all access rights, the user types who may
receive them, and how they are assigned.

## Sheets (6)

| # | Sheet name | Internal part | Role | Edited by generator |
|---|---|---|---|---|
| 1 | `index` | sheet1.xml | Cover page + template versioning | No (verbatim) |
| 2 | `Guide` | sheet2.xml | How-to and the 3 information types | No |
| 3 | `APPLICATION Information` | sheet3.xml | App identity | **Yes** (cells C3..C7) |
| 4 | `Matrix of BUSINESS rights` | sheet4.xml | Up to 19 business profiles (skeleton) | No (documented in README) |
| 5 | `AWS NG - TECHNICAL rights` | sheet5.xml | 15 predefined technical profiles | Token `<PRD>`/REFLEX only |
| 6 | `Parameters` (hidden) | sheet6.xml | Drop-down lists / data validation | No |

## Sheet 3 - APPLICATION Information (cells written)
- B3 `REFLEX name of the technical production application` -> C3
- B4 `REFLEX name of the functional application` -> C4
- B5 `DICT` -> C5
- B6 `PRD Code` -> C6
- B7 `Functional description of the application` -> C7

## Sheet 4 - Matrix of BUSINESS rights (row headers, columns B..T = Profile 1..19)
Label, Description, User type, Assignment method, Access service code, Level of
delegation, Confidentiality, Integrity, Sensitivity, Valorization, Incompatibilities,
Technical targets, Application functionalities (Feature 1..n). Generic skeleton - the
project fills it manually if business profiles are in scope; the generator does not
populate it.

## Sheet 5 - AWS NG - TECHNICAL rights (the 15 predefined profiles)
Columns B..P. Top flag: "Have you derogation from Cloud Center Tools for DEV+OPS being
cumulative?" Environment bands: DEV / PRE / PRD.

| Col | Profile | LDAP target value | Env |
|---|---|---|---|
| B | CICD DEV | `<PRD>.CICD.DEV` | DEV |
| C | CICD DEV ADMIN | `<PRD>.CICD.DEV.ADMIN` | DEV/PRE |
| D | CICD OPS | `<PRD>.CICD.OPS` | DEV/PRE |
| E | CICD RELEASE | `<PRD>.CICD.RELEASE` | PROD |
| F | CICD READ | `<PRD>.CICD.READ` | DEV/OPS (view) |
| G | AWS Console Administrator DEV | `<PRD>.BPF.AWS.DEV.ADMIN` | DEV |
| H | AWS Console ReadOnly DEV | `<PRD>.BPF.AWS.DEV.READONLY` | DEV |
| I | AWS Console ApplicationLead DEV | `<PRD>.BPF.AWS.DEV.APPLEAD` | DEV |
| J | AWS Console Administrator PRE | `<PRD>.BPF.AWS.PRE.ADMIN` | PRE |
| K | AWS Console ReadOnly PRE | `<PRD>.BPF.AWS.PRE.READONLY` | PRE |
| L | AWS Console ApplicationLead PRE | `<PRD>.BPF.AWS.PRE.APPLEAD` | PRE |
| M | AWS Console Administrator PRD | `<PRD>.BPF.AWS.PRD.ADMIN` | PRD |
| N | AWS Console ReadOnly PRD | `<PRD>.BPF.AWS.PRD.READONLY` | PRD |
| O | AWS Console ApplicationLead PRD | `<PRD>.BPF.AWS.PRD.APPLEAD` | PRD |
| P | CICD DEVOPS | `<PRD>.CICD.DEVOPS` (LDAP `<PRD>.SCM.DEVOPS`) | DEV/PRE |

Per-profile rows: Label, Description, User type, Assignment method (REUNIS access
service), Access service code (`<PRD>X`, X given by seculogiq), Level of delegation
(`ASL + Owner`), Confidentiality/Integrity/Sensitivity, Valorization, Incompatibilities
(e.g. RELEASE not cumulative with DEVOPS/DEV ADMIN/DEV), Technical environments
(Development / Pre-production / Production), Applicative & Terraform sources, CI, CD
per env, Access to production business data, Technical targets (LDAP group + value),
CIQ access per env (`<PRD>00**`..`<PRD>05**`), GitHub access, and Tasks.

Key incompatibility rules preserved from the template:
- RELEASE is **not cumulative** with DEV, DEV ADMIN, DEVOPS.
- Console profiles: affectation forbidden on the primary ID of a user (secondary ID
  only).
- The CI is managed by the OPS profile, so a single DEV+RELEASE person cannot deploy to
  production without an OPS deploy (segregation of duties).

## Placeholders resolved by the generator
- `<PRD>` -> `prdCode` (everywhere).
- `<REFLEX_NAME of the DEV/PREPROD/PROD Application ...>` and `<Reflex_Application>`
  -> optional REFLEX names (kept as-is if not provided).
