# IT costs (development, piloting, delivery - internal + outsourcing)

The IT cost is the human effort to build and deliver the solution. It is **not** a guess: it is
derived from a **backlog** and/or the Stellantis **UO effort-estimation model** (the DP_UT_01
"Dossier d'estimation UO"). It must **include outsourcing** (sous-traitance).

## What the IT line covers
- **Development + unit tests** (the core build effort).
- **Project piloting** (project management / CPI, coordination, governance).
- **Delivery**: functional analysis, general & detailed design, component integration,
  qualification, user acceptance, go-live / ramp-up, support activities, "Indus".
- Both **internal** effort and **outsourced** effort (the deck line is "IT costs - included
  outsourcing").

## Two ways to size it
### A. From a backlog (preferred when Agile / a backlog exists)
Ask the user for the **backlog** (epics / features / user stories, ideally with story points or
a T-shirt size). Convert to effort:
- points/size -> **JH** (person-days) using the team's velocity or a size->JH ratio the user gives;
- add non-dev effort (piloting, analysis, testing, delivery) as a ratio of dev effort or explicit
  estimates;
- split **internal vs outsourcing** per the sourcing plan (e.g. dev outsourced to a supplier,
  piloting internal).

### B. From the UO effort model (DP_UT_01 - provenance, not required)
The official Stellantis dossier estimates **physical Units of Work (UO)** per technology, each with
a complexity level (Simple / Moyen / Complexe) mapped to a JH baseline, adjusted by a **Facteur
d'Ajustement** (team experience, functional mastery, transversality), then split internal (PSA) vs
suppliers (BIS / SFAC / IRIS-Indus) with per-entity **daily rates** to give a cost in **k€**.
Reproduce that logic when a UO dossier is used:
1. list the functions -> pick the technology UO + complexity -> JH baseline x FA = dev+TU JH;
2. spread across cycle activities (analysis, design, integration, qualification, UAT, ramp-up,
   piloting, support, Indus) using the model's ratios;
3. apply **internal daily rate** and **supplier daily rate** to the internal vs outsourced JH;
4. sum to k€.
Do not embed or require the DP_UT_01 workbook; if the user has filled it, take its **SYNTHESE**
totals (JH and k€, internal vs suppliers) as the IT figures.

## Converting to k€ and phasing
- **k€ = JH x daily rate / 1000**. Ask the user for the internal and supplier **daily rates** (do
  not assume). Keep internal vs outsourcing visible.
- **Phase across Year-1 quarters** following the macro-planning / timeline (build effort front-
  loaded; most IT cost lands in Y1). 
- **Year 2 "recurrent"**: the maintenance / run IT effort after go-live (TMA, support), not the
  one-off build. If maintenance is not yet sized, mark `TBD`.

## Inputs to ask the user (never invent)
- The backlog (or the filled UO dossier / its SYNTHESE totals).
- Internal daily rate and supplier daily rate (k€/JH).
- Sourcing split (what is internal vs outsourced, and to which supplier).
- Timeline / macro-planning to phase effort across quarters.
- Expected Year-2 maintenance effort (for the recurrent column).
Mark any unknown as `TBD` in the costs README and ask.
