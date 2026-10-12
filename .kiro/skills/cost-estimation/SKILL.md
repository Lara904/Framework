---
name: cost-estimation
description: Guide the user to a COMPLETE cost picture for a SIBS / Stellantis Financial Services Architecture Gates (TCC) submission and persist it. Covers the three TCC cost families - Infrastructure (Cloud, via the AWS Calculator), IT (development, project piloting and delivery, including outsourcing) and Investments (hardware, software licenses) - spread over two years (Year 1 by quarter Q1-Q4, Year 2 as next-year recurrent costs, in k€). Lists the AWS services to estimate, helps estimate the metrics/consumption per service, and turns the AWS Calculator export into the deck's cost-detail (slide 58) and cost-global (slide 59) tables. Writes a costs README that historizes every value and flags what is still missing. Self-contained - the cost model, the AWS-Calculator workflow and the IT UO-estimation model are bundled as references. For the deck itself use the presentation-gates skill.
keywords:
  - cost
  - costs
  - costing
  - coût
  - coûts
  - budget
  - estimation
  - estimate
  - AWS Calculator
  - cloud cost
  - infrastructure cost
  - IT cost
  - outsourcing
  - sous-traitance
  - license
  - hardware
  - investment
  - CAPEX
  - OPEX
  - recurrent cost
  - UO
  - JH
  - backlog
  - TCC
  - gate 2
  - gate 3
  - gate 4
  - slide 22
  - slide 23
  - slide 58
  - slide 59
---

# Cost Estimation (SIBS / Stellantis Financial Services - Architecture Gates / TCC)

This skill helps a project reach a **complete, defensible cost estimate** for the Architecture
Gates (TCC) review and keeps it up to date. The TCC expects costs in **three families**, spread
over **two years**:

1. **Infrastructure (Cloud)** - the cloud consumption, estimated service-by-service with the
   **AWS Calculator**.
2. **IT** - development, project **piloting** and **delivery**, **including outsourcing**
   (estimated from a backlog / the UO effort model -> JH -> k€).
3. **Investments** - hardware (servers, ...) and **software licenses**.

**Time distribution** (see `references/cost-model.md`): **Year 1** is detailed **by quarter**
(Q1, Q2, Q3, Q4); **Year 2** is a single **"next-year recurrent costs"** column. All amounts in
**k€**.

The skill produces and maintains a **costs README** that historizes every value and lists what is
still missing, and it prepares the numbers that fill the deck's cost slides (**slide 58** = AWS
detail, **slide 59** = global total + AWS Calculator link; the earlier Gate-1/2 duplicates are
slides 23 and 22).

## When to use this skill
- Preparing the cost slides for a Gate 2 / Gate 3 / Gate 4 TCC submission.
- Working out which AWS services to estimate and their metrics/consumption.
- Turning an AWS Calculator export into the deck's cost tables.
- Tracking what cost data is still missing and persisting the agreed values.
- For filling the actual PowerPoint, hand the numbers to the **presentation-gates** skill.

## Bundled assets (inside this skill)
- `references/` - the cost model, AWS-Calculator workflow, IT UO-estimation model, investments,
  questionnaire and the README format (loaded on demand).
- `assets/scripts/costs-readme.ps1` - seeds / refreshes the costs README from a JSON model and
  reports completeness (what is still missing) + computed totals. UTF-8 (no BOM), ASCII-safe.
- `assets/templates/costs_readme_template.md` - the README structure (source of truth for layout).

This skill is **self-contained**: it does NOT require the AWS Calculator workbook, the DP_UT_01 UO
estimation dossier, or any project file to exist. Those official tools are **provenance only** -
their structure is reproduced in `references/`. The AWS Calculator itself is an external web tool;
only its **export** (CSV/JSON/PDF or a shared link) is consumed, when the user provides it.

## Deliverables (always produce/maintain)
Written to the per-project output folder `output/${project_name}/` (create it if missing) - see the
`output-convention.md` steering (single source of truth for output location).
1. **`${project_name}_costs_README.md`** - the cost tracker & history: the three
   families over Y1 quarters + Y2 recurrent, the AWS service list with per-service monthly/annual
   estimates, the IT backlog + total (internal vs outsourcing), the investments, an **Open
   questions / Missing** section, and a **totals** line. Statuses/values are **persisted** across
   regenerations. Format in `references/readme-template.md`.
2. The **cost numbers ready for the deck** - the AWS detail rows for slide 58 and the global-view
   values (IT / Cloud / Investments / Total, per quarter + Y2 recurrent) for slide 59, plus the
   **AWS Calculator shared link**. Filling the .pptx is done by the presentation-gates skill.

## Ask before generating (never invent)
Solicit the missing inputs from the user - see `references/questionnaire.md`. **Never invent** a
price, a consumption metric, a JH/day count, a daily rate, a license fee or a headcount. Any
unknown becomes a clearly marked `TBD` in the README's "Open questions / Missing" section and a
question to the user (or MOA / finance / cloud team). Amounts are estimates to be validated.

## Reference guides (load on demand)
- `references/cost-model.md` - the TCC cost families, the Y1-quarterly / Y2-recurrent structure,
  k€ convention, and the mapping to deck slides 22/23/58/59.
- `references/aws-cloud-costs.md` - how to list the AWS services to estimate, help the user
  estimate metrics/consumption per service, complete the AWS Calculator, and turn its export into
  the slide-58 detail rows and the slide-59 "Cloud consumption" line.
- `references/it-costs.md` - the IT cost: backlog + the DP_UT_01 UO effort model (UO -> JH -> k€),
  development / piloting / delivery, internal vs outsourcing, quarter phasing.
- `references/investments.md` - hardware and software-license costs.
- `references/questionnaire.md` - the grouped questions to ask, only when not already known.
- `references/readme-template.md` - the costs README format and the JSON model it is built from.

## Core rules (always apply)
1. **Never invent a figure.** Prices, metrics, rates, JH, licenses -> ask or mark `TBD`. Every
   amount is an estimate to be validated with finance / cloud / MOA.
2. **Three families, always all considered**: Infrastructure (Cloud), IT (incl. outsourcing),
   Investments. If a family is not applicable, state it explicitly (e.g. "no hardware - fully
   cloud PaaS") rather than leaving it blank.
3. **Two-year phasing**: Year 1 by quarter (Q1-Q4), Year 2 = next-year recurrent costs. Keep the
   grand **Total** = sum of the families per column. Amounts in **k€** (round sensibly).
4. **Cloud = per-service AWS Calculator estimate.** List every service, its region, its
   metrics/consumption assumptions, monthly and annual cost, currency. The deck references the
   **shared AWS Calculator link**, not a screenshot; slide 58 carries the per-service detail.
5. **IT = from a backlog / UO effort model**, not a guess. Break down development, project
   piloting and delivery; separate **internal** vs **outsourcing**; convert JH x daily rate ->
   k€; phase across the quarters. See `references/it-costs.md`.
6. **Persist everything in the README** and keep the "Open questions / Missing" section current so
   the user always sees what blocks a complete cost picture. Regenerate after every change.
7. **English, ASCII-safe, UTF-8 without BOM** for anything written into the deck; the README may
   stay bilingual but prefer English for figures/labels used on slides.
8. **Currency**: the AWS Calculator commonly exports **USD**; the deck global view is in **k€**.
   Convert with an explicit, noted FX rate (ask the user for the rate to use) - do not silently
   mix currencies.

## Quick workflow
1. Read `references/cost-model.md` and confirm the two-year horizon and currency/FX with the user.
2. Cloud: with `references/aws-cloud-costs.md`, list the services to estimate, help set each
   service's metrics/consumption, and record the per-service monthly/annual estimate + the shared
   Calculator link (ask the user to build/share the Calculator estimate and its export).
3. IT: with `references/it-costs.md`, get the backlog and derive dev / piloting / delivery effort
   (internal + outsourcing) -> JH -> k€; phase across quarters.
4. Investments: with `references/investments.md`, capture hardware + license costs (or mark N/A).
5. Seed/refresh **`${project_name}_costs_README.md`** (`assets/scripts/costs-readme.ps1`); review
   the completeness report and ask the user for every `TBD`.
6. When complete, hand the slide-58 detail rows, the slide-59 global values and the Calculator
   link to the **presentation-gates** skill to fill the deck.
