# TCC Cost Model

The TCC cost view (deck slides 22 / 59 "Cost global view", and 23 / 58 "AWS estimate") is built
on three cost families spread over two years.

## Cost families (rows of the global-view table)
| Family | What it covers |
|--------|----------------|
| **IT costs** (incl. outsourcing) | Development, project **piloting**, **delivery**. Internal effort + externalized (outsourcing / sous-traitance). Derived from a backlog / the UO effort model. See `it-costs.md`. |
| **Cloud consumption** | Infrastructure = the cloud running cost, estimated per AWS service with the AWS Calculator. See `aws-cloud-costs.md`. |
| **Investments** | **Hardware** costs (servers, ...) and **Software license** costs. See `investments.md`. |
| **Total cost** | Sum of the three families, per column. |

If a family does not apply, state it (e.g. "Investments: none - fully cloud PaaS, no hardware, no
paid license") rather than leaving blanks.

## Time distribution (columns)
- **Year 1**: detailed by quarter -> **Q1, Q2, Q3, Q4**.
- **Year 2**: a single **"Next year recurrent costs"** column (the steady-state run cost once the
  project is live - typically cloud consumption + maintenance/support, minus one-off build costs).
- All amounts in **k€** (thousands of euros). Round sensibly (e.g. 1 decimal).

So the global-view table is a grid: rows = {IT, Cloud, Investments (Hardware, Software license),
Total} x columns = {Q1, Q2, Q3, Q4, Y2 recurrent}.

## Currency
- The AWS Calculator usually exports **USD** (monthly + annual per service).
- The global-view table is in **k€**.
- Convert with an explicit FX rate agreed with the user; note the rate and date in the README.
  Never mix currencies silently on the same slide.

## Mapping to the deck slides (presentation-gates fills them)
| Slide | Title | What the cost skill provides |
|-------|-------|------------------------------|
| 23 / **58** | Costs - AWS estimate (detail) | One row per AWS service: **Region(s), Service, Monthly, Annual, Currency, Configuration summary**. Replace the template example rows (ALB/ECS/ECR/CloudFront) with the project's real services. |
| 22 / **59** | Costs - global view | The grid above (IT / Cloud consumption / Investments (Hardware + Software license) / Total, over Q1-Q4 + Y2 recurrent) + the **link to the shared AWS Calculator** and to the detailed cost document. |

Slides 22/23 are the Gate 1-PoC / Gate 2 copies; 58/59 are the later copies. Keep both copies
consistent if both are in scope; at Gate 3/4 update figures and **highlight differences vs Gate 2**
(the template explicitly asks for this on the global-view slide).

## Gate expectations
- **Gate 2**: initial estimate for the three families over the two years.
- **Gate 3**: updated planned cost; highlight what changed vs Gate 2.
- **Gate 4**: final cost before go-live; highlight differences.
