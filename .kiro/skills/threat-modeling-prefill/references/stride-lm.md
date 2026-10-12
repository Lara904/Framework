# STRIDE-LM reference

STRIDE-LM is the STRIDE threat taxonomy extended with **Lateral Movement**. The authoritative,
machine-readable data lives in three bundled files (never restate them here, never hard-code them
in a script):
- `prefill-logic.json` - risk matrix, countermeasure-efficiency formula, scenario-selection logic,
  NIST hint.
- `threat-catalog.json` - the real 176-scenario SFS catalog (6 categories: Applicative, CI/CD,
  Infra cloud, EKS, SaaS, LLM IA).
- `countermeasure-library.json` - the real 97-countermeasure library (CM.xxx).
- `stride-library.json` - the official STRIDE-LM definitions below, verbatim from the SFS tool.

This file is the human-readable companion.

## Categories (see `stride-library.json` for the full official definition, explanation,
cloud example and mitigation concept per code)
| Code | Category | Security property at stake |
|------|----------|----------------------------|
| S | Spoofing | Authentication |
| T | Tampering | Integrity |
| R | Repudiation | Non-repudiation |
| I | Information Disclosure | Confidentiality |
| D | Denial of Service | Availability |
| E | Elevation of Privilege | Authorization / least privilege |
| LM | Lateral Movement | Containment / segmentation |

## Risk scale (the REAL SFS scale - see `prefill-logic.json` for the canonical values)
- Occurrence: 1-3 (bare integer; the source tool does not label individual levels).
- Impact: 1-3 (bare integer; the source tool does not label individual levels).
- Risk level = matrix lookup, NOT occurrence x impact as a number:
  (1,1)=very low, (1,2)=low, (1,3)=average, (2,1)=low, (2,2)=above average, (2,3)=high,
  (3,1)=average, (3,2)=high, (3,3)=extreme.
- Countermeasure efficiency = occurrenceMitigation x impactMitigation x easeOfImplementation x
  bandWeight(highest riskLevel among the threats it mitigates). This REPLACES the old invented
  0-3 "effectiveness" scale, which had no basis in the real tool.

## Scenario selection (architecture signal -> catalog subset)
Summarised from `prefill-logic.json` (`scenarioSelection`) - replaces the old 4 generic
hand-written rules, which were far thinner than the real catalog and a cause of a reported defect:
1. Determine which of the 6 catalog categories apply to this application (Applicative almost
   always; CI/CD, Infra cloud, EKS, SaaS, LLM IA depending on the real architecture signals).
2. Within each applicable category, keep every catalog entry whose `scope[]` matches the
   application's real scope - do not pre-filter by "representative sample".
3. A signal with no catalog match becomes a CUSTOM scenario (worded via the model call, marked
   `custom: true`), scored with the same real scale - never left unscored.
4. Carry each kept scenario's real `counterMeasureIds`/`counterMeasureTitles` as the starting
   countermeasures column.

## NIST mapping (SFS/ARB-reporting addition, not part of the source catalog)
Each scenario can be mapped to NIST SP 800-53 Rev.5 control families (AC, AU, CA, CP, IA, MP, PT,
SC, SI) via the `strideToFamilyHint` in `prefill-logic.json`. This is a starting point for the
security team, not a compliance statement, and never replaces the catalog's own STRIDE-LM flags.
