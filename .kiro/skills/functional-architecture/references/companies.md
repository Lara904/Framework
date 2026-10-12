# Companies, Applications, Interactions, Users (the functional model)

The functional diagram is organised around **companies**. Every application sits inside exactly
one company container. Interactions are arrows between applications (possibly across company
boundaries). Users are actors attached to the applications they use.

## The two default companies
- **ICT** - the brands' websites and IT.
  - Owns brand-facing / web assets: host websites, brand e-commerce or marketing sites, CMS,
    embedded web components (widgets) running in the browser on ICT pages.
  - Think "the digital storefront and the brand web IT".
- **SFS** (Stellantis Financial Services) - the bank's applications and IT.
  - Owns financial/business applications: lead management, product/offer catalogue, pricing or
    simulation/eligibility engines, CRM, back-office, contract systems.
  - Think "the bank's business applications".

Add another company container ONLY if the user confirms it (external partner, JV, third-party
SaaS provider). Name it exactly as the user states.

## Modelling rules
- **Company = container** (a labelled box / swimlane). Give it a clear header with the company
  name. Use a distinct fill per company for readability (functional, not technical colours).
- **Application = node inside its company container.** Label with the application name and,
  optionally, a state tag: `(New)`, `(Update)`, `(Existing)`, `(Decom <date>)`.
- **Interaction = directed edge** between two applications. The arrowhead shows direction
  (initiator -> receiver). Label with the business content of the exchange, e.g.:
  - "lead data", "eligibility result", "product catalogue", "customer consent",
    "simulation inputs", "offer personalisation".
  - Keep labels business-level; do NOT write protocols/ports (that is the technical skill).
- **User = actor shape** (person) connected to the application(s) they use. Distinguish:
  - external users (end customer, dealer, partner) vs internal users (sales agent, marketing,
    back-office operator).
- **Front door**: make it visually clear which application the primary user interacts with
  first (e.g. the host website / widget on the ICT side).

## Cross-company interactions
- The most important arrows usually cross the ICT <-> SFS boundary (e.g. a widget on an ICT
  host site sending lead data to an SFS lead-management application). Emphasise these.
- If a functional constraint matters (e.g. "personal data stays local to the browser / on the
  host site, only qualified lead handed to SFS"), show it as a labelled note near the flow.

## What NOT to include (this is the functional view)
- No VPC/subnet/account boxes, no AWS/Azure service icons, no gateways, no protocols/ports,
  no CI/CD toolchain. Those belong to the technical-architecture skill.
- If the user asks for those, point them to the technical skill.
