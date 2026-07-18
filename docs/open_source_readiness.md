# Open Source Readiness Audit

Date: 2026-07-18

Goal: make a technically competent contributor able to clone, install, launch, test, understand, and propose changes in roughly one afternoon.

## Executive Assessment

Analytics Workstation has a strong product story, package runtime, release artifacts, and extensive architecture documentation. The main contributor risk is not lack of material. It is navigation: there is a lot to read, and some older documents still reflect earlier implementation phases.

This pass added missing contributor scaffolding and corrected critical install/package contradictions.

## Critical Findings

### Fixed: No GitHub contributor scaffolding

The repository had no issue templates, pull request template, discussion template, or concise contribution guide.

Implemented:

- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_proposal.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/DISCUSSION_TEMPLATE/ideas.md`
- `CONTRIBUTING.md`

### Fixed: Missing editor baseline

The repository had no shared whitespace/editor defaults.

Implemented:

- `.editorconfig`

### Fixed: Stale install narrative

The README still described a copied-source install model. The package conversion now launches from installed package resources.

Implemented:

- README installer language corrected.
- Package architecture and Windows installation docs aligned with package-installed resources.

### Fixed: Missing contributor orientation

New contributors needed to infer the architecture from many specialized docs.

Implemented:

- `docs/architecture_orientation.md`
- `docs/development_principles.md`
- `docs/contributor_roadmap.md`
- `docs/README.md`

### Fixed: Package metadata lacked public repository links

`DESCRIPTION` did not include `URL` or `BugReports`.

Implemented:

- `URL: https://github.com/AdrianAntico/AnalyticsShinyApp`
- `BugReports: https://github.com/AdrianAntico/AnalyticsShinyApp/issues`

## Recommended Findings

### Reduce `R CMD check` NSE NOTE

`R CMD check --no-manual` passes with tests OK and one NOTE from data.table-style nonstandard evaluation/global variables. This is not a runtime failure, but it creates noise for external contributors.

Recommendation: add a focused `utils::globalVariables()` cleanup or refactor high-noise data.table expressions in a separate PR.

### Add a CI status section to README

The repository references CI/CD in project history. If public workflows are active, expose the badge and name the validation command they run.

Recommendation: add badges after confirming the exact workflow names.

### Clarify release publishing flow

Release artifacts exist under `release/`, but GitHub Release creation is not yet documented as an operator checklist.

Recommendation: add `docs/release_process.md` with exact build, check, checksum, upload, and smoke-test steps.

### Add cross-platform status

The product is Windows-oriented today. Contributors on macOS/Linux should know which paths are expected to work and which are unvalidated.

Recommendation: add a compatibility matrix.

## Optional Findings

### Good first issue labels

Templates exist, but repository labels may not.

Optional: add labels such as `good first issue`, `documentation`, `package`, `ui`, `testing`, `research`, `build-week`, and `post-build-week`.

### Screenshots in contributor docs

README has media. Contributor docs are text-only.

Optional: add one architecture diagram and one installed-package flow diagram.

### Contributor-friendly test matrix

Current validation commands are documented, but a matrix of "changed X, run Y" would reduce friction.

Optional: add this to `CONTRIBUTING.md`.

## Dependency Audit

### Runtime imports

Declared runtime imports:

- AutoPlots
- AutoQuant
- data.table
- echarts4r
- htmltools
- htmlwidgets
- openxlsx
- shiny
- tools

These align with startup, UI, plotting, export, and package-resource behavior.

### Optional/suggested packages

Declared optional packages include:

- AutoNLS
- Rodeo
- arrow
- base64enc
- callr
- chromote
- commonmark
- curl
- digest
- httr
- httr2
- jsonlite
- mirai
- png
- ps
- reactable
- roxygen2
- testthat
- yaml

These should remain optional unless their absence prevents app startup. Optional analytical paths must report unavailable capability rather than fail silently.

### Simplification guidance

Do not remove dependencies solely to reduce counts. First prove that a dependency is unused in source, tests, docs, and optional workflows.

## Public Trust Review

### Open-source maintainer

Creates confidence:

- package build/check path exists
- release artifacts and checksums exist
- contributor templates now exist
- package resource model is documented

Creates doubt:

- many docs are historical and not clearly indexed
- one `R CMD check` NOTE remains

### Senior software engineer

Creates confidence:

- explicit runtime/resource path separation
- deterministic QA helpers
- service-contract documentation

Creates doubt:

- large R surface area with many concepts
- some compatibility/historical shims remain

### Data scientist

Creates confidence:

- artifacts, evidence, claim verification, and integrity review are central
- deterministic Build Week demo path exists

Creates doubt:

- contributor path through analysis modules is not yet indexed by task

### Build Week judge

Creates confidence:

- README tells the product story with exhibits
- demo guide and release artifacts exist

Creates doubt:

- media and release artifacts are bulky and should be intentionally curated

### Potential collaborator

Creates confidence:

- roadmap categories make contribution areas explicit
- development principles explain product taste and engineering expectations

Creates doubt:

- project scope is broad; issue labels and milestones will matter.

## Potential Good First Issues

1. Add CI badges after confirming workflow names. Scope: Build Week.
2. Add a Windows installer troubleshooting example for missing Rscript. Scope: Build Week.
3. Add one package-resource unit test for a new asset path. Scope: Build Week.
4. Replace one internal label in UI with user-facing language. Scope: Build Week.
5. Add a screenshot to `docs/architecture_orientation.md`. Scope: Build Week.
6. Add a test matrix to `CONTRIBUTING.md`. Scope: Build Week.
7. Fix one stale `shiny::runApp(".")` instruction where package launch should be primary. Scope: Build Week.
8. Add short "changed X, run Y" validation guidance to the docs index. Scope: Build Week.
9. Add issue labels and milestone conventions. Scope: Post Build Week.
10. Add a release process checklist. Scope: Post Build Week.
11. Add macOS/Linux package launch notes. Scope: Post Build Week.
12. Reduce one cluster of data.table NSE notes. Scope: Post Build Week.
13. Add installed-package smoke test documentation. Scope: Post Build Week.
14. Improve Electron missing-Node guidance. Scope: Post Build Week.
15. Add a docs link checker. Scope: Post Build Week.
16. Add a dependency inventory report artifact. Scope: Post Build Week.
17. Build a cross-platform screenshot QA harness. Scope: Long-term.
18. Build a formal contributor onboarding walkthrough. Scope: Long-term.
19. Add architecture diagrams generated from canonical docs. Scope: Long-term.
20. Formalize package lifecycle badges and API stability levels. Scope: Long-term.

## Current Release Coherence

The repository now consistently describes:

- package version: `1.0.0`
- product release: `1.0.0-buildweek`
- product name: Analytics Workstation
- package name: AnalyticsShinyApp
- immutable resources: installed package `app/`
- mutable state: `%LOCALAPPDATA%\AnalyticsWorkstation`
- release artifacts: `release/`

## Next Recommended Cleanup

Do not add features next. The highest-leverage cleanup is a documentation index and release-process checklist, followed by reducing `R CMD check` NOTE noise.
