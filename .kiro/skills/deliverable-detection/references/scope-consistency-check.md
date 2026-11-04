# Scope consistency check - one project, not several

## Why this exists

The per-file category signals in `categories.json` answer "what KIND of document is this
file" (functional architecture? NFR? cost estimate?). They never ask the more basic question:
"do all these files describe the SAME application?". A source folder can be internally
consistent on category (a clean functional doc, a clean technical doc, a clean flow inventory)
while still describing two different real-world systems - for example because a folder was
seeded from the wrong project's export, a brief was copy-pasted from a similar prior project and
only partially edited, or two projects share a generic folder name. Every downstream skill
(`functional-architecture`, `technical-architecture`, `dict-assessment`, `nfr-requirements`,
`cost-estimation`, `threat-modeling-prefill`, `presentation-gates`) trusts whatever it reads with
no way to detect this on its own - each one only ever sees its own slice of the sources, in
isolation, and faithfully transcribes it. The result is a complete, internally-coherent,
well-sourced, "never invented a value" set of deliverables that is entirely about the wrong
application. Nothing in the normal per-file, per-category checks catches this; it needs its own
pass, run once, across every file, before any deliverable is generated.

## When to run it

After Pass 2 (content check) of `detection-method.md`, using whatever file content was already
read during that pass (do not re-open files solely for this check; reuse what Pass 2 already
has). Run it once per detection run, across ALL files that carry a narrative (a brief, a
functional/technical doc, an NFR input file, a project summary) - not on pure data tables (a flow
CSV with no prose, a plain cost export) which carry no independently-checkable identity signal of
their own.

## What to extract from each narrative file

For each file with prose content, extract (when present - not every file states all four):
1. **Project/application name(s)** - every distinct name used to refer to "the thing this
   document is about" (a formal name, a nickname, a demand ID, an acronym).
2. **Business purpose in one sentence** - what the application actually does for the business
   (e.g. "routes insurance claim payments to back-office systems" vs "stores and serves vehicle
   residual-value data").
3. **Core technical nature** - the handful of facts that most strongly fingerprint an
   architecture family: does it have a UI? Does it expose or consume APIs? Does it have a
   database? Is it a batch/scheduled job or a request-driven service? Real-time or
   asynchronous/file-based?
4. **Named upstream/downstream systems** - the other applications/systems this one talks to.

## The check

Compare these four extractions pairwise across all narrative files:
- **Name check**: do all files use the same name (or clearly compatible names - an acronym and
  its expansion, a demand ID and its application name) for "the thing"? A name that appears
  nowhere else, or a second unrelated name introduced without explanation, is a signal, not proof
  by itself.
- **Purpose check**: does the one-sentence purpose from file A sound like the same business
  activity as the one-sentence purpose from file B? This is a judgment call for the agent running
  the skill, not a string match - restate both purposes in your own words and compare them
  directly before deciding.
- **Technical-nature check**: do the UI/API/database/batch-vs-realtime facts agree? This is the
  single strongest and cheapest signal. A file that states "no UI, no API, no database, batch"
  and another that states "REST API, web UI, managed database" are near-certainly not the same
  application, almost regardless of what name each one uses.
- **Named-systems check**: do the upstream/downstream system names overlap or at least not
  contradict? Two files naming completely disjoint sets of integration partners, with no
  explanation (no "the systems changed between phases" note), is a secondary signal.

**A single disagreeing name is not, by itself, a blocker** - people genuinely use a demand ID,
an acronym and a full name interchangeably for one real project, and a folder is sometimes named
after the demand rather than the application. Treat a name-only mismatch as an ordinary "Open
question" (ask which name should prefix the deliverables) UNLESS it is accompanied by a purpose
or technical-nature disagreement - then it stops being a naming question and becomes a blocker.

**The technical-nature check and the purpose check are the ones that matter.** If either of them
disagrees between two files that are both meant to describe the "main" application of this
project (not a dependency or an integration partner mentioned in passing), that is the mismatch
this check exists to catch.

## STOP protocol - what to do when a mismatch is found

1. Do **not** proceed to resolve any file into "Detected" for this run. Do not hand off to any
   consumer skill.
2. Write the detection README anyway, but:
   - Set `Status: BLOCKED - scope mismatch` on the header line (not `Draft`, not `Reviewed`).
   - Add a new top section, before "Coverage summary", titled
     `## BLOCKER - project identity mismatch` containing:
     - The conflicting extractions side by side (name / purpose / technical nature per file),
       each with the exact file it came from.
     - A one-paragraph plain-language statement of why this blocks the run (not "files are
       ambiguous" - say concretely what disagrees, e.g. "file A describes a real-time API-backed
       web application; file B describes a batch file-transfer job with no UI; these cannot be
       the same system").
     - The exact question to ask the user: which of the conflicting narratives is the actual
       project this run should document, or are these genuinely two different projects that were
       dropped into the same folder by mistake.
3. Still produce the "Coverage summary" and "Detected files" sections below the blocker (useful
   context for whoever resolves it) but prefix the README's top line and the run's final report
   to the user with the blocker - never report a coverage percentage or a "ready for the next
   skill" status as the headline while this is unresolved.
4. The run ends here. The user's answer to the blocking question is itself the fix - either a
   corrected/completed source folder, or a confirmation that one of the conflicting files should
   simply be ignored for this project. Only after that confirmation does detection re-run from
   Pass 1.

## What this check deliberately does NOT do

- It does not try to auto-resolve which of two conflicting narratives is "correct" - that is a
  human call, not a content-matching heuristic the agent can win by reading more carefully.
- It does not replace the per-file category/confidence logic in `detection-method.md` - it runs
  in addition to it, as an extra pass over the same Pass-2 reads.
- It does not fire on legitimate multi-system projects (a migration project naming both the old
  and the new system, an integration project describing two applications that will talk to each
  other) - those files will describe DIFFERENT systems but will say so explicitly and
  consistently (e.g. "Project X migrates system A to system B"; both A and B appear by name in
  every file, with a consistent migration narrative). The check is about undisclosed,
  unexplained disagreement on what the MAIN subject of the project is, not about a project
  legitimately involving more than one system.
