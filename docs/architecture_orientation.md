# Architecture Orientation

This document is for contributors who need to understand the repository before changing it. It is not a full architecture reference.

## What This Is

Analytics Workstation is an evidence-governed analytical workstation. The app preserves an investigation: objectives, uncertainty, competing explanations, evidence, belief revision, recommendations, claim verification, and integrity review.

The package name is `AnalyticsShinyApp`. The product name is Analytics Workstation.

## How The Application Is Organized

```text
R/
  app shell, pages, services, QA helpers, contracts
inst/app/
  installed UI assets, config defaults, deterministic demo data
scripts/
  dependency installation, release packaging, validation
tests/testthat/
  deterministic package and workflow checks
docs/
  product, architecture, demo, release, and research documentation
release/
  release candidate artifacts
```

The source-tree app is still launchable with `shiny::runApp(".")`, but the supported distribution contract is package-first:

```r
library(AnalyticsShinyApp)
run_workstation()
```

## Foundational Concepts

- Project: the user-owned analytical workspace.
- Artifact: a durable analytical evidence object, not just an output.
- Evidence: artifact plus meaning, provenance, quality, and relevance.
- Investigation: the path from question to recommendation.
- Claim: a statement that should be traceable to evidence.
- ReportContract: semantic reporting structure before rendering.
- Runtime bundle: compact, deterministic knowledge used to guide bounded AI behavior.

If you change any of these concepts, expect broad consequences.

## Stable Contracts

These should change rarely:

- package launch API: `run_workstation()`, `launch_workstation()`
- package diagnostics: `workstation_diagnostics()`, `workstation_installation_info()`
- package QA: `qa_package_distribution()`, `qa_electron_distribution()`
- resource paths: `workstation_resource_path()`, `workstation_user_path()`
- service result shape: success/status/message/value/error style objects
- explicit degradation for optional capabilities

## Extension Areas

Good places to extend:

- documentation and examples
- deterministic QA coverage
- UI polish that keeps page purpose clear
- additional ReportContract adapters
- new artifact preview or rendering helpers
- clearer diagnostics for optional dependencies
- release packaging hardening

Be careful in:

- project persistence
- GenAI action/mutation paths
- evidence routing and runtime compilation
- package resource path handling
- Windows installer logic

## Core Runtime Rule

The installed package may be read-only. Mutable state belongs under:

```text
%LOCALAPPDATA%\AnalyticsWorkstation
```

Do not write projects, logs, caches, exports, screenshots, or generated runtime state into the package library.

## AI Boundary

Deterministic services compute evidence. GenAI helps with bounded framing, synthesis, explanation, claim verification, and guidance. It should not silently create evidence, mutate state, or execute unsupported actions.

## Where To Read Next

- `docs/development_principles.md`
- `docs/package_architecture.md`
- `docs/build_week_demo_guide.md`
- `docs/reporting_system_architecture.md`
- `docs/knowledge_compilation_runtime_architecture.md`
- `docs/contributor_roadmap.md`

