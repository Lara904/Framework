# Technical Stack & Frameworks Diagram

This skill also manages the **technical stack** of the application (products, frameworks, runtimes
and OS with their **versions**) and renders it as a **Frameworks diagram** in draw.io
(`<project>_technical_architecture_frameworks.drawio`). It is the "building blocks" view that
complements the AWS infrastructure diagram: where the architecture diagram shows *where things
run* (AWS services, VPCs, flows), the Frameworks diagram shows *what the application is built
with* (front-end framework, back-end framework, libraries, runtime, container base image, build /
test / quality tooling).

The same stack information is the single source that feeds three deliverables and MUST stay
consistent across all of them:
- the **Frameworks diagram** (`<project>_technical_architecture_frameworks.drawio`),
- the **DAT** section **2.1.2 Applicative components** (the "Technical stack" table - see
  `dat-document.md`),
- the **gates Deck** slides **30 "Technical stack (1/2)"**, **44 "Technical stack (2/2)"** and,
  if the app is containerized, **43 "Container orchestrator - technical stack"** (see the
  `presentation-gates` skill). Slide 30/44 wording is "Products / frameworks / OS with versions
  (CMS, back-end, front-end, DB, OS)", "TO BE COMPLETED AT GATE 3".

## Source template (source of truth)
`assets/templates/FMK_Diagram_template.drawio` is the authoritative Stellantis CIQ / PSA reference
framework stack (Angular front-end + OpenJDK / Spring back-end, Corretto, Paketo container base
image, quality / testing / documentation tooling). It is the recommended standard stack. **Start
from it** (Strategy A: copy + adapt) and tailor it to the application's real stack. Never modify
the template in place - copy it to `output/${project_name}/` under the deliverable name and edit
the copy (see the `output-convention.md` steering).

## Stack categories (layers of the diagram)
Reproduce the template's layered layout. Adapt each layer to the project; keep the layer heading
even when it does not apply and mark it "Not applicable" rather than deleting it (same rule as the
DAT). Typical layers, top to bottom:

| Layer | What it captures | Example (CIQ standard) |
|-------|------------------|------------------------|
| Front End | UI framework + version, i18n, styling/layout, date/format libs, language | Angular 21 LTS, ngx-translate, angular-material, luxon, TypeScript |
| Parent POM / build baseline | Corporate build baseline / release management | PSA `ciq-java-parent` 4.0.0 |
| Runtime | Language runtime + distribution + version | OpenJDK 21 - Corretto |
| Core | Base framework | Spring Core 7.0, Spring Boot 4.0 |
| Cloud Ready | Cloud SDK / integration | Spring Cloud AWS 4.0 |
| Security | AuthN/AuthZ, dependency scanning | Spring Security (LDAP/OIDC), dependency-check-owasp, spring-security-oauth2-resource-server |
| Web | Web / API layer | Spring Web 7.0 |
| Messaging | Async / broker | N/A or MSK/Kafka client |
| Data layer | Persistence / ORM / cloud data | Spring Data JPA 4.0, Spring Cloud AWS |
| Data pipeline | Batch / ETL | Spring Batch 6.0 |
| Logging | Log framework + shippers | Logback, logstash-logback-encoder, slf4j, micrometer-tracing-bridge-brave |
| Supervision | Metrics / actuator | Spring Actuator, micrometer-registry-cloudwatch2 |
| Utils | Common libs | Apache Commons, Lombok, MapStruct |
| Documentation | API docs | springdoc-openapi-ui |
| Quality | Static analysis / security report | sonar-maven-plugin, Checkmarx |
| Testing | Test frameworks | spring-boot-starter-test, spring-security-test, spring-batch-test, h2, wiremock |
| Container base image | Base image / buildpacks + layers | Paketo builder-noble-java-tiny, ca-certificates, amazon-corretto, java |

Plus the two recurring notes from the template (keep them, they are corporate guidance):
- "Frameworks to be upgraded **at least yearly** - recommended half-yearly; use start.spring.io;
  define your Maven BOM to manage versions."
- "Cloud best practice: use in priority the BOM of Spring Cloud relative to the Cloud provider."

## Tailoring rules (per project)
- **Front-only app (e.g. a JS/UMD web widget, no backend):** keep the Front End layer with the
  real framework and version, the build/test/quality/documentation tooling that applies (e.g.
  bundler, linter, unit-test runner, SonarQube, Checkmarx), and the container base image only if
  containerized. Mark the Spring/Java back-end layers (Core, Cloud Ready, Web, Data, Messaging,
  Data pipeline, Supervision, Runtime/Corretto) **"Not applicable"** - do not delete them, so the
  reader sees they were considered. If the widget is pure static hosting (S3+CloudFront, no
  container), mark "Container base image" Not applicable too.
- **Full Java back-end app:** keep the standard CIQ layers and fill the real versions.
- Always show **versions**. A version that is not yet decided becomes `XX*` (the template's
  "version to fill" marker) or `TBC`, plus an Open question / Missing-information entry in the
  README - never invent a version.
- Keep the corporate baseline rows (parent POM, "upgrade yearly" note, container base image
  provenance) whenever they apply; they are expected by the gate reviewers.

## Deliverable format
- File: `<project>_technical_architecture_frameworks.drawio` in **`output/${project_name}/`**
  (see the `output-convention.md` steering).
- `<mxfile pages="2">`: a **Versions** page first (same table format as the other diagrams, see
  `output-format.md`), then a **Frameworks** page with the layered stack.
- Reuse the template's box style (rounded rectangles, `fillColor=#DBDBDB` for standard layers,
  `#dae8fc` for the front-end band, `#ffe6cc` for the cloud-best-practice note, `#e1d5e7` for the
  container base image). Front-end band on top, runtime baseline bands, then the functional
  layers grid, then the notes.
- **Encoding:** UTF-8 without BOM, **ASCII-only** cell text (no em dash / bullet / curly quotes -
  use `-`, straight quotes, `&#10;` for newlines). Self-contained - no external image references.
- Validate geometry per `layout-validation.md` (no overlaps, no orphaned edges).

## Consistency
The Frameworks diagram, the DAT "Technical stack" table (DAT 2.1.2) and the Deck slides 30/44 (and
43 if containerized) MUST list the **same products/frameworks with the same versions**. Any `XX*`
/ `TBC` version appears identically in all three and in the README **Missing information** table
with an owner. When the stack changes, update all three plus the README.
