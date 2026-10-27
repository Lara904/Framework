# The Four Architecture Gates (ARB / TCC)

Architecture Gates are the mandatory internal SIBS approval of an IT solution, part of the
Strategic Portfolio Management (SPM) Demand & Project process in DigitalMe. The Architecture
Review Board (ARB, formerly TCC) reviews the deck for approval / recommendations.

**One document, all gates.** Use the same deck from Gate 1 to Gate 4. For each gate, complete
that gate's section; update earlier sections only if something changed (highlight deltas).

## Golden workflow (from the template user guide)
- **Gate 1**: complete only the "Gate 1" section.
- **Gate 2**: update Gate 1 if needed, then complete the "Gate 2" slides.
- **Gate 3 to 4**: modify/include slides in the "Gate 2 to 4" section; add the info specific
  to that gate.
- Read the yellow guidance and the speaker notes, then remove the yellow text once filled.
- Rely on the official criteria list (Criteria per Gates) to know what is mandatory.
- Indicate the validation date of the gate being submitted when sending to stakeholders.
- Record each gate submission in the template "Revisions index" (pos 2). (V5.2 removed the
  separate "your document" revisions slide; there is a single revisions index now.)

## Deliverable at every gate: the gates checklist
After filling (or reviewing) the deck, always (re)generate the gates README - structured by
gate, each gate listing its slides AND its annex deliverables. Generate it with
`assets/scripts/find-missing.ps1 -Gate all -Out <Project>_Architecture_Gates_README.md`; see
`gates-readme.md` for the required format and naming.

> **Slide positions below are V5.2** (75-slide template). V5.2 shifted most positions vs V5.1
> and added Exit plan for SaaS (14), Exit plan for make cloud/AWS (15), SOX/CAC stock-flow (20)
> and DATA MODEL (43). See `template-structure.md` for the full map.

## Gate 1 — Demand Gate (mandatory for all Demands)
Purpose: validate the demand overview and applicability before deep design.
Complete at least:
- Objectives (pos 8) — points to validate.
- Architecture One Pager (pos 9) — demand type, build type, business capabilities, impacted
  applications, related records (GenAI/BrightIdea/DigitalMe/RPA ids), regulatory compliance,
  technologies, cloud implementation type, API re-use/new, platform re-used, scope, end users,
  DigitalMe Demand ID, primary/other business domains.
- Architecture Overview Diagram (pos 10) — As-Is / To-Be.
- Applicability (pos 11) — mark each domain Yes/No; hide non-applicable domains.
- Data Privacy (pos 13) — if personal data is involved.
- "Gate 1 PoC": if a PoC is done, also complete Risks (23/65), Costs (24/25), Data Privacy,
  DevSecOps (38), Cloud (29), Application Flows (33), and other slides labelled "Gate 1 PoC".

## Gate 2 — Initial Gate
Purpose: validate the target solution, its architecture, NFR, costs, timeline and risks.
Complete at least:
- Project information / Synthesis (pos 12) — DICT/CIAT, RTO/RPO, SLA, SOX, DORA, suppliers.
- NFR (pos 18), Functional (pos 17) and Enterprise architecture (pos 19, 22, 40, 41).
- Cloud (pos 29), DevSecOps (pos 38, 39), API (pos 44), GenAI (pos 45) if applicable.
- Technical architecture global view (pos 42), Application flows (pos 33).
- Costs (pos 24/25), Timeline (pos 26), Risks (pos 23), Residual risks (pos 65).
- Summary of the Solutions (pos 27) and TCC initial approval + actions + approvers (pos 68-70).
- If applicable: Exit plan for SaaS (pos 14) / for make cloud (pos 15), SOX/CAC stock-flow
  (pos 20), DATA MODEL (pos 43), Threat modeling report (pos 63, tagged Gate 2 in V5.2).
Note: the Technical Check Committee initial gate is mandatory before presenting to DOPCO/CIO.

## Gate 3 — After Design Gate
Purpose: validate the detailed design after build design phase.
Complete / update:
- Technical stack with versions (pos 32, 47), Container orchestrator (pos 46).
- DevSecOps environment + deployment (pos 39), quality gate thresholds (pos 38).
- GenAI API keys per environment (pos 45), Monitoring updates (pos 58).
- Cloud Build & Run organization + operating model (pos 30).
- Costs: update planned cost and highlight differences vs Gate 2.
- TCC after Design approvers (pos 66).

## Gate 4 — Before Go-Live Gate
Purpose: validate readiness before go-live.
Complete / update:
- Threat modeling report (pos 63) validated with Cybersecurity.
- SonarQube report (Quality Gate validated) and Checkmarx scan + action plan (pos 38).
- Costs update (pos 24/25), Residual risks (pos 65), Monitoring (pos 58).
- Confirm environments, backup, DRP, exit/reversibility plan (pos 48).
- **Security scan action plan, in the format a later committee will actually want**: a real
  go-live readiness review (a separate, later committee from these Gates) did not accept "Quality
  Gate passed" alone - it listed each remaining Critical/High finding individually (reference,
  description, priority, current status such as "To be done" / "Partially done", and a
  realization target date), and explicitly marked confirmed false positives as such (e.g.
  "Proposed Not exploitable - awaited feedback from Vulnerability team") rather than leaving them
  ambiguous among the real open items. Apply the same standard to the pos 38 Checkmarx/SonarQube
  action plan here: a finding count with no per-item detail is not an action plan.

## SaaS-specific reminders (apply across gates when solution is a SaaS)
- Exit plan strategy and reversibility are mandatory and must be reflected in the contract.
- Maintain an up-to-date functional + flow inventory for the exit plan (DORA).
- Detail SLA and shared-responsibility (RACI) with the supplier; track pricing drivers (FinOps).
- For an exit-plan execution project: present the new target, the migration + transition
  phases, and the disengagement of the old SaaS, with milestones and organization.
- A "SaaS" service is an external function used by or interacting with the Bank/Insurance/JV,
  not residing on a Stellantis resource. Add SaaS Manager as "informed" in the committee.

## Applicability domains (pos 12)
API, Cloud, Data, Data privacy, DevSecOps, Enterprise Architecture (Yes), Gen AI,
Infrastructure, Cybersecurity (Yes), Accessibility, IOT, RPA, LowCode/NoCode,
Services Contracts, Hardware & Software Contracts.
Non-applicable domains are hidden/removed and not discussed during the gate.
Applicability must be confirmed by the Enterprise Architect against the Global Criteria List.
