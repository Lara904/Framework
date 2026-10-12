# Project-team interview (structured, ~30 min)

The pre-fill is seeded from the DAT + dataflow + the real catalog (`references/threat-catalog.json`,
176 scenarios), then confirmed with the project team in a short, guided interview. Ask ONLY what
the DAT / dataflow / existing READMEs do not already answer - confirm deductions rather than
re-asking section by section. Never invent an answer; an unknown becomes `TBC` + an Open question
in the README.

This is the **project-team panel only** (the MVP scope). The CISO panel and the pentest panel are
target-vision extensions, out of MVP scope - do not solicit or imply them here.

## 1. Scope and assets
- Which components / data stores / flows are in scope for the threat model? (confirm against the
  DAT component inventory and the dataflow)
- Which asset is the most sensitive (the "crown jewels")?
- Which elements genuinely do NOT exist in this architecture (e.g. no "Data store" because the app
  is stateless, no "External entity")? Only an explicit "does not apply" here may exclude a catalog
  element - never exclude one by default.

## 2. Category applicability (-> which of the 6 catalog categories apply)
Confirm each category of `threat-catalog.json` against the real architecture - keep every
applicable category's full scenario subset, do not pre-select a "representative sample":
- **Applicative** - almost always applies (any application has flows/stores/processes).
- **CI/CD** - does the project have its OWN pipeline/supply-chain steps beyond the shared SFS
  chain (custom build steps, third-party actions, artifact signing)?
- **Infra cloud** - AWS account-level / Landing Zone signals (cross-account roles, shared
  services, SCPs)?
- **EKS** - is Kubernetes / EKS used?
- **SaaS** - is a third-party SaaS integrated (data shared with or received from it)?
- **LLM IA** - does the application call or embed an LLM / GenAI component (prompt handling,
  model access, generated-content handling)?

## 3. Exposure, exchanges, data, infra coupling (cross-check, not re-derive)
The catalog scenarios already cover these signals in depth (API/edge exposure, file/batch
exchanges, PII, Landing Zone coupling and more) - use this step only to CONFIRM scope, not to
invent new scenario text:
- Any API / edge endpoint exposed (public, partner, internal)? Which auth?
- Any file-based or batch exchanges? Logged in a tamper-evident way?
- Does the system handle personal / sensitive data (PII)? (confirm with the DICT and the DPO)
- Cross-account roles, shared services, trust relationships to the Landing Zone? (a recurrent ARB
  refusal motive - probe it explicitly, it is covered by the "Infra cloud" category)
- Any signal here with NO match in the catalog becomes a CUSTOM scenario (see
  `prefill-logic.json`'s `scenarioSelection` step 3) - say so explicitly rather than silently
  folding it into an existing scenario.

## 4. Existing countermeasures and scoring
- For each selected scenario, the catalog already lists real countermeasures
  (`counterMeasureIds`/`counterMeasureTitles`) - confirm which are ALREADY implemented, which are
  PLANNED, and which do not apply to this architecture (say why, do not just drop them).
- Proposed occurrence (1-3) and impact (1-3) per scenario? (these are proposals to validate with
  security - a catalog scenario's `sampleOccurrence`/`sampleImpact`, when present, is only an
  illustrative starting point from a past rated project, never a default to reuse silently)
- Known prior incidents / audit findings relevant to a scenario?

## 5. Validation
- Who on the SFES Cybersecurity team validates the threat model, and by when?
- Remind the team: the generated TM is a pre-fill, to be reviewed and validated by security
  before use.
