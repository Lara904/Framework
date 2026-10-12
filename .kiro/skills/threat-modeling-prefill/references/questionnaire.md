# Project-team interview (structured, ~30 min)

The pre-fill is seeded from the DAT + dataflow, then confirmed with the project team in a short,
guided interview. Ask ONLY what the DAT / dataflow / existing READMEs do not already answer -
confirm deductions rather than re-asking section by section. Never invent an answer; an unknown
becomes `TBC` + an Open question in the README.

This is the **project-team panel only** (the MVP scope). The CISO panel and the pentest panel are
target-vision extensions, out of MVP scope - do not solicit or imply them here.

## 1. Scope and assets
- Which components / data stores / flows are in scope for the threat model? (confirm against the
  DAT component inventory and the dataflow)
- Which asset is the most sensitive (the "crown jewels")?

## 2. Exposure (-> S / T / E)
- Is there any API / edge endpoint exposed (public, partner, internal)? Which auth (mTLS, OAuth,
  SSO)?
- Who can call it, and how is authorization enforced?

## 3. Exchanges (-> R / D)
- Any file-based or batch exchanges (SFTP, object drops, scheduled jobs, cross-account copy)?
- Are transfers logged in a tamper-evident way (who/what/when)? Any volume/flooding concern?

## 4. Data / privacy (-> I)
- Does the system handle personal / sensitive data (PII)? (confirm with the DICT and the DPO)
- Encryption at rest / in transit? Access on a need-to-know basis? Retention / disposal?

## 5. Infrastructure coupling (-> E / L)
- Cross-account roles, shared services, trust relationships to the Landing Zone?
- Network isolation (private subnets, no internet egress, segmentation)? SCP boundaries?
- (This area is a recurrent ARB refusal motive - probe it explicitly.)

## 6. Existing countermeasures and scoring
- For each candidate scenario: what countermeasure already exists or is planned?
- Proposed occurrence (1-4) and impact (1-4)? (these are proposals to validate with security)
- Known prior incidents / audit findings relevant to a scenario?

## 7. Validation
- Who on the SFES Cybersecurity team validates the threat model, and by when?
- Remind the team: the generated TM is a pre-fill, to be reviewed and validated by security
  before use.
