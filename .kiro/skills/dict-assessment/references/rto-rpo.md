# RTO / RPO / SLA (companions to the DICT)

RTO and RPO are distinct from the DICT but are captured alongside it on the SIBS Architecture
Gates "Project Synthesis" slide, and must be aligned with the CMDB. SLA is the business-owner's
expected availability, measured end-to-end (planned maintenance counts as downtime).

## RTO - Recovery Time Objective
Duration during which the application can remain unavailable after a disaster without impacting
the company (set by the business team).
| Value | Meaning |
|-------|---------|
| 1 | 0 - 48 h |
| 2 | 2 - 4 days |
| 3 | 4 - 7 days |
| 4 | 7 days |
| 5 | Preproduction |
| 6 | Archive |
| 9 | not involved |

## RPO - Recovery Point Objective
Amount of data (time) that can be lost after a major disaster without endangering the company.
| Value | Meaning |
|-------|---------|
| 0 | zero data loss |
| 1 | 24 h max |
| 2 | 48 h max |
| 3 | 7 days |
| 4 | data can be rebuilt |
| 9 | no data involved |

## SLA (context)
- Expected availability from the business owner, measured from the end-user point of view; any
  downtime (including planned maintenance) reduces the measured SLA.
- Reference figures: digital apps for average end-users >= 99.95% (~4 h/year down); a cheap
  single-region B2B app ~99% (~3 days/year) may suffice.
- SLA computation helper: https://uptime.is/
- Relationship to Availability (D): a tighter availability need (higher D) usually implies a
  higher SLA and stronger RTO/RPO; keep them coherent.

These values are CMDB-aligned and validated by the business; propose them as assumptions to
validate when the official values are not yet known.
