# STRIDE-LM reference

STRIDE-LM is the STRIDE threat taxonomy extended with **Lateral Movement**. The authoritative,
machine-readable list (codes, properties, risk scales, the pre-fill rules and the NIST mapping)
lives in `prefill-logic.json`; this file is the human-readable companion.

## Categories
| Code | Category | Security property at stake |
|------|----------|----------------------------|
| S | Spoofing | Authentication |
| T | Tampering | Integrity |
| R | Repudiation | Non-repudiation |
| I | Information Disclosure | Confidentiality |
| D | Denial of Service | Availability |
| E | Elevation of Privilege | Authorization |
| L | Lateral Movement | Containment / segmentation |

## Risk scales (see `prefill-logic.json` for the canonical values)
- Occurrence: 1 Rare / 2 Unlikely / 3 Possible / 4 Likely.
- Impact: 1 Negligible / 2 Moderate / 3 Serious / 4 Severe.
- Risk level = occurrence x impact (1..16): 1-3 Low, 4-7 Medium, 8-11 High, 12-16 Critical.
- Countermeasure effectiveness: 0 None / 1 Weak / 2 Moderate / 3 Strong.

## Pre-fill rules (architecture signal -> candidate STRIDE-LM)
Summarised from `prefill-logic.json` (`prefillRules`) - the project-team pre-fill logic:
- **API / edge exposure** -> Spoofing / Tampering at the edge, broken access control (S, T, E).
- **File / batch exchanges** -> Repudiation, Denial of Service (R, D).
- **Personal data (PII / DCP=Yes)** -> Information Disclosure + a linked Data Privacy requirement (I).
- **Infra / Landing Zone coupling** -> Elevation of Privilege, Lateral Movement (E, L). DEDICATED
  ALERT: this is a recurrent ARB refusal motive - always surface it and flag it high.

## NIST mapping
Each scenario is mapped to NIST SP 800-53 Rev.5 control families (AC, AU, CA, CP, IA, MP, PT, SC,
SI). The family list and names are in `prefill-logic.json` (`nistReference`). The mapping is a
starting point for the security team, not a compliance statement.
