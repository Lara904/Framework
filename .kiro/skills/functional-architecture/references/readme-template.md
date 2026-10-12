# Functional Architecture README - template

Write `${project_name}_functional_architecture_README.md` to `output/${project_name}/` (see the
`output-convention.md` steering), in English, using the structure below. Keep it factual; put
anything unconfirmed under Assumptions / Open questions.

```markdown
# <Solution> - Functional Architecture

Version: <x.y>  |  Date: <YYYY-MM-DD>  |  Author: <name>
Diagram: <project>_functional_architecture_diagram.drawio
Dossier (FAD): <project>_functional_architecture_document.docx

## Overview
One short paragraph: what the solution does functionally and which companies are involved.

## Companies
| Company | Role | In scope |
|---------|------|----------|
| ICT | Brand websites and IT (host sites, web components) | Yes |
| SFS | Bank applications and IT (lead mgmt, catalogue, pricing, CRM) | Yes |
| <other> | <role> | <yes/no> |

## Applications
| Application | Company | State | Purpose |
|-------------|---------|-------|---------|
| <app> | ICT / SFS / <other> | New / Update / Existing / Decom | <one line> |

## Interactions
| From (initiator) | To | Exchange (business content) | Notes |
|------------------|----|------------------------------|-------|
| <app A> | <app B> | <what flows> | <sync/async, constraint...> |

## Main users
| User | Type | Uses (application) | Notes |
|------|------|--------------------|-------|
| <user> | External / Internal | <app> | <e.g. front door> |

## Functional constraints & notes
- <e.g. personal data stays local to the browser / host site; only a qualified lead is handed to SFS>

## Assumptions
- <anything drawn or stated that is not yet confirmed by the user>

## Missing information (to be provided)
A single consolidated list of everything still unknown, so the reader knows exactly what to
provide to finalize the diagram. It MUST gather every `TODO` / "to confirm" marker on the diagram
and in this README. Give each item what it unblocks and who owns it.

| # | Missing information | Needed for | Owner / source |
|---|---------------------|-----------|----------------|
| M1 | <e.g. Other brand-side applications (analytics, consent) in the ICT container> | Applications, Interactions | Brand sites |
| M2 | <e.g. As-Is only, or also a To-Be with a future flow to SFS> | Diagram scope | Product / Architecture |
| ... | ... | ... | ... |

## Open questions
- <questions still pending with the user, mirroring the on-diagram TODO notes>
```

Rules:
- English only; ASCII-safe text.
- The README, the diagram and the FAD (`<project>_functional_architecture_document.docx`) must
  agree (same companies, applications, interactions, users). The README application/interaction
  tables feed FAD sections 1.3 and 2.2.
- Every `TODO` note on the diagram has a matching Open question here, and vice versa.
- The **Missing information** table is the single place that consolidates every `TODO` / "to
  confirm" marker on the diagram and in this README; keep it in sync whenever either changes.
  Each row says what is missing, what it unblocks, and who owns it.
