# NFR FAQ - common questions and precise answers

**What is the NFR repository?**
The Stellantis (ex-PSA) reference `DP-MD18-EN` lists all Non-Functional Requirements a system
must implement to work correctly in RUN. It is classified per ISO 25010 (8 chapters). The
requirements are fixed; a project only rates each one (Relevant + Status) and justifies it.

**Who owns it?**
The IT-PM owns the repository during BUILD, the PGA during RUN. Each NFR names the responsible
and producer roles for BUILD and RUN (see `roles-glossary.md`).

**Which columns can I edit?**
Only four: Relevant, Status, Last update / Last control dates, and Comments / Valorization.
Everything else (title, description, dispensation, roles, milestones, triggers) is read-only.

**What are the statuses and when are they due?**
`Proposed` (initial) -> `Accepted` (project commits; required for all relevant NFRs by end of
pre-study) -> `Implemented` (done, before the Production milestone) -> `Verified` (implemented
and checked, before the Control milestone). Plus `Not relevant` and `Not feasible`.

**How is "Relevant" decided?**
It is COMPUTED by the model's filter macro, not judged. Crossing the system parameters (DICT,
RTO, SOX, Data privacy) with each NFR's triggers: a generic NFR (no trigger) is always relevant;
an NFR with triggers is relevant if at least one trigger matches the context. The skill
reproduces this in `Test-NfrRelevant` (validated to match the macro exactly). Your applicability
opinion goes into Status, not Relevant. Trap: `C1234`/`D1234` cover all levels (relevant even at
level 1). See `workflow.md`.

**I disagree with a computed Relevant - can I force it?**
No. Relevant reflects the referential filter. If the NFR is relevant but you judge it
inapplicable, keep Relevant = Yes and set Status = `Not relevant` with a justification (only when
the dispensation allows it). That is the audited, correct way.

**What does "No dispense possible" mean?**
The NFR is mandatory - it cannot be set Not relevant. If it genuinely cannot be met, set Status
= Not feasible, justify it, and set up a contingency/risk plan. Never silently drop it.

**What is the difference between "Relevant = No / Not relevant" and "Relevant = Yes / Not
relevant"?**
- `No` + `Not relevant`: the filter excluded it (context does not trigger it). Not counted in the
  synthesis.
- `Yes` + `Not relevant`: the filter kept it but the project judges it inapplicable. A comment is
  mandatory. Also excluded from the synthesis, but visible as a project decision.

**How does DICT drive the NFRs?**
Each security/availability NFR carries level flags per criterion (e.g. `C34` = triggered when
Confidentiality is 3 or 4). A higher DICT triggers more (and stronger) requirements - e.g.
strong authentication, encryption, network segmentation, DRP class. Use the `dict-assessment`
skill to settle the DICT first; remember the GDPR floor raises the DICT when personal data is
processed.

**What about SOX and data privacy?**
NFRs flagged `SOX` apply only when the app is in SOX financial-reporting scope. NFRs flagged
`DP` (data privacy) apply when the app processes personal data (GDPR) - these are typically "No
dispense possible" (NFR-1401..1407).

**Can I generate the Excel deliverable automatically?**
Yes - `new-nfr-workbook.ps1` copies the reference model, writes the parameters and applies your
decisions. See `tooling.md`.

**What if the DICT/RTO/SOX inputs are unknown?**
Do not invent them. Mark them `TBD - to validate with MOA/DPO`, produce a best-effort draft, and
list the open questions. The final rating is validated by the business.
