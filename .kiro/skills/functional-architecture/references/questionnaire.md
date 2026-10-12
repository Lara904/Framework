# Clarifying Questions (ask before drawing)

Ask these to the user, adapting to what is already known from the conversation or the project.
Group them; do not dump all at once if a few answers already settle most of the diagram. Record
every answer in the README; mark anything unresolved as an assumption + open question.

## 1. Scope & companies
- Which companies are involved? Confirm the split:
  - **ICT** - brands' websites and IT (host websites, brand marketing/e-commerce, CMS...).
  - **SFS** - the bank's applications and IT (financing, CRM, lead management, pricing...).
  - Any other party (external partner, JV, third-party SaaS) that must appear?
- Which company "owns" the solution being presented?

## 2. Applications per company
- For ICT: which applications/sites are in scope? (e.g. host website, widget host page.)
- For SFS: which applications are in scope? (e.g. lead management, product catalogue, pricing
  engine, CRM, eligibility/simulation service.)
- For each application: is it New, Updated, or unchanged/existing? Is any being decommissioned?

## 3. Interactions between applications
- For each pair that exchanges something: who initiates (direction), and what flows in business
  terms? (e.g. "widget sends lead data to SFS lead management", "SFS returns product catalogue
  to the host site".)
- Are any exchanges one-off vs continuous? Synchronous (user waits) vs asynchronous? (optional,
  only if the user cares - keep it functional.)

## 4. Main users
- Who are the primary users and which application do they interact with?
  (e.g. end customer -> host website/widget; sales agent -> CRM; marketing -> catalogue.)
- Internal (Stellantis/SFS employees, with ID) vs external (customers, dealers, partners)?

## 5. Boundaries & data (light, functional)
- Where does the user interaction happen (which company's application is the front door)?
- Any notable functional constraint to show (e.g. "personal data stays on the host site",
  "no direct customer access to SFS back-office")? Keep it business-level.

## 6. Naming & meta
- Solution name (for file names and the diagram title)?
- Author name for the Versions page?
- As-Is, To-Be, or both?

## FAD inputs (Functional Architecture Dossier .docx)
The FAD is a business/urbanisation document following the Stellantis template DP-MD76-EN. Ask
these only if the FAD is requested and the answer is not already known. Each maps to a FAD
section (see `references/fad-document.md`). Do NOT invent any of this.

### 7. Project context & needs
- How does this project position within a wider Project Plan / Program / IT master plan? (FAD 1.1)
- Is there a **backlog / statement of needs / validated business requirements** to reference? Link? (FAD 1.2, related docs)
- Is there a **user journey / user flow / business process** description to summarize? (FAD 1.2)

### 8. IT & data situation
- Which applications are impacted, and (ideally from **ARIS**) their label + short description +
  New/Update/Existing state? (FAD 1.3 - same inventory as the diagram)
- Any organizational/geographical coverage worth noting for those applications? (FAD 1.3)
- Which useful **reference/enterprise data** does the project rely on, and how is it accessed? (FAD 1.4)

### 9. Governance & target
- Which **BIS** are impacted, and which **functional architects** (incl. the responsible DAF) are
  involved? (FAD 1.5)
- What are the **structuring elements** (from the needs analysis) that drive the chosen
  architecture? (FAD 2.1)
- What is the **target master plan**: how are functions split across existing/new applications,
  and what data exchanges result? (FAD 2.2 - illustrated by the diagram)
- For each **new application**: a more precise description (construction permit)? (FAD 2.3)
- Any **phased rollout / bundles**, or **discarded alternatives** to document? (FAD 2.4 / 3.2 / 3.3 - optional)

## When answers are missing
- Do NOT invent applications, company names, or flows.
- Draw what is confirmed; for gaps, add a visible `TODO: confirm ...` note near the relevant
  area and list the open question in the README. Then ask the user.
