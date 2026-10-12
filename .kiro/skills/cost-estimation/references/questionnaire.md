# Cost questionnaire (ask only what is not already known)

Group the questions; skip any already answered by the context, the DAT, the timeline or an
existing costs README. Never invent - an unanswered item becomes a `TBD` in the README.

## 0. Framing
- Which gate is this for (2 / 3 / 4)?
- Cost horizon confirmed as two years (Year 1 by quarter, Year 2 recurrent)? Start quarter?
- Reporting currency for the global view is k€. What **FX rate** should convert the AWS Calculator
  currency (usually USD) to EUR, and as of which date?

## 1. Cloud (Infrastructure) - per AWS service
- Which AWS services does the architecture use (from the DAT / data-flow)?
- For each service, the consumption metrics (see `aws-cloud-costs.md`): volumes, requests, data
  transfer, instance sizes, task profiles, retention, per environment (PROD + non-prod), Multi-AZ?
- Can you build the estimate in https://calculator.aws and share the **public link** + an
  **export** (CSV/JSON/PDF)? (The deck references the shared link.)
- Any expected growth across the quarters (ramp-up as environments go live)?

## 2. IT (development, piloting, delivery - incl. outsourcing)
- Is there a **backlog** (epics/features/stories, with sizes/points)? Can you share it?
- Or a filled **UO estimation dossier** (DP_UT_01)? If so, its SYNTHESE totals (JH and k€,
  internal vs suppliers).
- **Daily rates**: internal (k€/JH) and supplier (k€/JH)?
- **Sourcing split**: what is done internally vs outsourced, and to which supplier?
- **Timeline / macro-planning** to phase effort across Q1-Q4?
- Expected **Year-2 maintenance / run** effort (for the recurrent column)?

## 3. Investments
- Any **hardware** to purchase (servers, devices, ...), or none (cloud-only)?
- Any paid **software / licenses / SaaS** not covered by cloud consumption (product, pricing
  metric, fee, one-off vs recurrent), or all open-source / already covered?

## 4. Validation
- Who validates the cost estimate (finance / project manager / MOA)?
- Any known constraint or cap (budget envelope)?
