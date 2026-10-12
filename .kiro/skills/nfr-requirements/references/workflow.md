# NFR Assessment Workflow

How to assess the Stellantis (ex-PSA) Non-Functional Requirements repository `DP-MD18-EN`
for one application, from system context to a filled deliverable.

## 1. The model in one paragraph
The repository is a fixed list of NFRs classified per ISO 25010 (8 chapters: Functional
Suitability, Performance efficiency, Compatibility, Usability, Reliability, Security,
Maintainability, Portability). You never add, modify or remove an NFR. For each NFR you only
decide two things and justify them:
- **Relevant** = Yes / No (does this requirement apply to the application?)
- **Status** = Proposed -> Accepted -> Implemented -> Verified (life-cycle), plus Not relevant /
  Not feasible.
You also write the reasoning in **Comments / Valorization**. These are the only editable columns.

## 2. Gather the system context (the filter inputs)
The relevance of most NFRs is driven by the system parameters entered on the **Synthesis** sheet:
- **DICT** (4 digits, D/I/C/T, each 1..4) - the security-need rating. Use the `dict-assessment`
  skill if it is not settled yet.
- **RTO** class (1..8, or 9 = not involved).
- **SOX** (Yes / No) - is the application in SOX financial-reporting scope?
- **Data privacy risk level** (No / A / B / C / D) - does it process personal data, and at what
  risk level? (This also raises a GDPR floor on the DICT - see the `dict-assessment` skill.)

Also note the application's functional/technical nature (batch? database? user sessions?
internet-exposed? cloud-hosted? multilingual UI? on-call?) because many generic NFRs are
assessed on applicability, not on DICT.

## 3. Relevance is COMPUTED BY THE MACRO, not judged
The `Relevant` column is filled ONLY by the reference model's **filter macro**
(`RequirementsFilter`) from the system parameters crossed with each NFR's triggers. This is the
sole authorised method - never hand-set Relevant and never substitute another calculation. The
rule the macro applies (also mirrored by the explain-only `Test-NfrRelevant`, validated to
0 mismatch against a human-filled reference at DICT 1111):

- **Generic NFR (no trigger)** -> always `Relevant = Yes`.
- **NFR with triggers** -> `Relevant = Yes` if AT LEAST ONE trigger matches the context:
  - DICT flag `<crit><levels>` matches when the system's level for that criterion is listed:
    `C34` matches C=3 or C=4; `C1234` matches ANY C level (so it is always relevant on C);
    `D1234` is always relevant on D, etc.
  - `RTO=n` matches when the system RTO class equals n.
  - `DP` matches when the system processes personal data (Data privacy level A/B/C/D, not "No").
  - `SOX` matches when the system is in SOX scope.
- Otherwise `Relevant = No`.

Common trap: `C1234` / `D1234` / `I1234` / `T1234` list ALL four levels, so they are relevant
even at level 1. Do not read them as "only high levels".

## 3bis. The project judgement goes into STATUS, not Relevant
Your applicability opinion ("no batch", "no IP service", "no user rights") is expressed through
**Status + Comment**, never by overriding the computed `Relevant`:

- **Relevant = No** (filtered out) -> Status = `Not relevant` (set automatically). Add a comment
  if useful.
- **Relevant = Yes** -> set the project Status using the dispensation rule:
  - `No dispense possible` -> mandatory; drive it to `Accepted`/`Implemented`/`Verified`. If truly
    impossible, `Not feasible` + justification + contingency (never silently drop it).
  - `<Role> can set "Not relevant" if <condition>` -> you MAY set Status = `Not relevant` (with
    Relevant still computed Yes) **only** when the condition holds; record the condition in the
    comment.
  - `... can set "Verified" if <condition>` (e.g. hosting internal or on the 3 main cloud
    providers) -> Status = `Verified` when the condition holds.
- Always add a one-line justification tied to the trigger and/or dispensation.

## 4. Set the status
- Default template status is `Proposed`. During the pre-study, every relevant NFR must reach at
  least **Accepted** (the project commits to implement it).
- `Implemented` before the "Production milestone", `Verified` before the "Control milestone".
- For a filtered-out NFR: Relevant = No, Status = `Not relevant`.
- If relevant but the project judges it not applicable: Relevant = Yes, Status = `Not relevant`
  + mandatory comment explaining why.
- If relevant but impossible: Status = `Not feasible` + reason + contingency.

## 5. Produce the deliverable
Generate the filled workbook with `assets/scripts/new-nfr-workbook.ps1` (see `tooling.md`): it
copies the reference model, writes the system parameters on Synthesis, **computes** the
`Relevant` column for every NFR from those parameters (reproducing the model's filter macro),
then applies your per-NFR project Status + Comment from the decisions file. The Synthesis sheet
then recomputes the status charts. Report what is relevant/not relevant and what still needs
MOA/business input.

This mirrors the human process (1. enter DICT + Data privacy, 2. click the filter button,
3. review the filtered NFRs and set Status/date/comment). The script runs the model's own macros
`RequirementsFilter` (fills Relevant + Status) and `ShowHideRequirements` (hides Not-relevant
rows) via `Application.Run` with `AutomationSecurity = Low`, auto-confirming the macro's Oui/Non
MsgBox with a background watcher (`Dismiss-FilterDialog.ps1`).

**The macro is the only authorised way to compute Relevant** - no other calculation method is
permitted. If the macro cannot run, the script saves the parameter-filled workbook and STOPS,
asking the user to: open the file, complete/verify the parameters, run the filter macro manually
(click Oui), save, and come back so you can analyse the filtered NFRs. Never compute Relevant
yourself in that case. Use `-NoHideFiltered` to keep all rows visible.

## 6. Golden rules
- **Relevant is computed, never judged.** Do not hand-set it; let the filter decide from the
  system parameters. Put your applicability opinion in Status + Comment.
- Never invent the DICT, RTO, SOX or data-privacy inputs - get them from the MOA / DPO / the
  `dict-assessment` deliverable. If unknown, mark `TBD - to validate` and say so.
- Never drive a `No dispense possible` NFR to Not relevant (via Status); use Not feasible +
  contingency if truly impossible.
- Always justify each Not relevant / Not feasible in the comment (audited at the gate).
- A relevant Security NFR left unimplemented at Go-Live must be validated by the right CRIS
  member (and RDMI if DICT >= 3) - flag it, don't hide it.
