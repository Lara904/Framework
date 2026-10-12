# Access Right Matrix - requirements questionnaire

Ask ONLY what is not already known from the workspace context. Before asking, check the
existing project files:
- `*_DICT_README.md` -> DICT rating (fills `dict`).
- `*_technical_architecture_README.md` / `*_functional_architecture_README.md` -> app
  name, environments, CI/CD nature.
- Any existing `*_access_right_matrix*` or REFLEX/PRD reference already recorded.

Whatever is still unknown becomes an **Open question** in the companion README and a
visible placeholder in the deliverable - never invent a value.

## 1. Application identity (APPLICATION Information sheet)
1. **PRD code** of the application (the `<PRD>` token, e.g. `ABCD` - exemple fictif). Used in
   every access-service code, LDAP target and CIQ env code.
2. **REFLEX name of the technical production application** (e.g. `MYAPP-T` - exemple fictif).
3. **REFLEX name of the functional application** (e.g. `Online My Application` - exemple fictif).
4. **DICT rating** (Disponibilite / Integrite / Confidentialite / Tracabilite). Reuse
   the DICT deliverable if present.
5. **Functional description** (one line) of the application.

## 2. REFLEX application names per environment (optional labels)
The technical-profile labels reference the DEV / PREPROD / PROD REFLEX application
names. If known, they make the labels concrete; if not, the descriptive placeholder is
kept.
6. **REFLEX name of the DEV application** (usually ending with `/D`).
7. **REFLEX name of the PREPROD application** (usually ending with `/P`).
8. **REFLEX name of the PROD application**.

## 3. Scope of profiles (documented in README, not by editing the template)
The template ships the **fixed** SFS catalogue: 15 technical profiles (CICD DEV, DEV
ADMIN, OPS, RELEASE, READ, DEVOPS + AWS Console Administrator/ReadOnly/ApplicationLead
per DEV/PRE/PRD) and a 19-column BUSINESS profile skeleton. Do not add/remove columns.
9. Does the application run on **AWS NG Landing Zone** with the standard SFS **CI/CD**
   chain (so the 15 technical profiles apply as-is)? Note any profile that is **not
   used** (e.g. no ApplicationLead) in the README rather than deleting it.
10. Are there **business profiles** to define (onglet "Matrix of BUSINESS rights"), and
    if so, for each: label, description, user type, assignment method, access service
    code, delegation level, DICT, and application features? If none for the MVP, record
    "No business profile for this scope" in the README.
11. Any **derogation** to declare (e.g. the DEV+OPS cumulative derogation from Cloud
    Center Tools flagged at the top of the technical sheet)?

## 4. Governance
12. Who is the **owner / ASL** (level of delegation is `ASL + Owner` by default in the
    template)?
13. Target **gate** (TCC / Architecture Gates) and expected completion date.
