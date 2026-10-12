# Personal data (GDPR) floor rule

From PSA-STSSI_003, section 7 "Consideration of personal data". When an application processes
personal data (PD - data relating to private life), it is subject to GDPR, and a MINIMUM DICT
applies based on the privacy risk to the individuals concerned (impact matrix on the privacy of
individuals). Then the final DICT is the max of the standard-risk DICT and the GDPR floor.

## GDPR minimum DICT (privacy risk -> D I C T)
| Privacy risk on the processed PD | Minimum DICT (D/I/C/T) |
|----------------------------------|------------------------|
| No risk higher than "C - Serious" on any processed PD | 2 / 2 / 2 (T per standard need) |
| At least a maximum risk of level "D - Important" on one PD | 3 / 3 / 3 |
| At least an "E - Severe" risk on any PD | 3 / 4 / 3 |

(The standard writes these floors as x222 / x333 / x343, where the leading letter is the
criterion order used in the source; interpret as the D/I/C values above. Confirm the exact
mapping and the privacy-risk level with the DPO.)

## The governing rule
```
DICT = max( DICT (standard risks) , DICT (GDPR) )
```
Compute the DICT from the standard-risk analysis (see `dict-scales.md`), compute the GDPR floor
from the table above, then take the element-wise maximum. If needed, raise further to reflect the
most structuring security need.

## Practical guidance
- Determine WHETHER personal data is processed. If unsure, ask the DPO (Data Privacy Officer).
- Distinguish "collects/handles personal data" from "processes/stores it". A component that only
  collects data in the browser and hands it to another controller without storing/transmitting it
  itself may carry a lower processing footprint - but GDPR applicability and the resulting floor
  must be confirmed with the DPO; do not decide this unilaterally.
- Confidentiality with personal data is commonly C3; exception: VIN as the only PII -> C2.
- Never finalize the GDPR risk level yourself; it is assessed with the DPO. Propose it as an
  assumption to validate, with reasoning.
