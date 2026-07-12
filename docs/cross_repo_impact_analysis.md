# Cross-Repository Impact Analysis

Phase 40 adds deterministic planning support for cross-repository changes. The goal is to help an agent answer, before editing code:

- which repository owns the capability
- which repositories consume it
- which contracts are affected
- which documentation is affected
- which QA should run
- what order implementation and validation should follow
- what compatibility or migration risks exist

This is not a generic dependency manager or AI planner. It uses the existing repository manifest, package metadata, contract declarations, and architecture ownership rules.

## Sources Of Truth

| Source | Used For |
| --- | --- |
| `config/cross_repo_workspace.json` | repository discovery, validation suites, expected exports, declared cross-repo contracts |
| package `DESCRIPTION` files | local package dependency ordering |
| `docs/repo_contracts.md` | repository ownership and boundary rules |
| `docs/package_qa_surface.md` | stable installed package QA contracts |
| capability ownership map | deterministic owner/consumer/validation/doc mapping for major product capabilities |

## Core Functions

| Function | Purpose |
| --- | --- |
| `cross_repo_dependency_graph()` | Builds observed repository, package, contract, and capability dependency edges. |
| `cross_repo_capability_ownership()` | Lists primary owners, consumers, public contracts, validation contracts, and docs for major capabilities. |
| `cross_repo_contract_consumer_analysis()` | Identifies providers, consumers, required exports, compatibility expectations, and migration sensitivity for declared contracts. |
| `cross_repo_change_categories()` | Defines deterministic change categories and their default validation scope. |
| `cross_repo_impact_plan()` | Produces a structured implementation and validation plan for a proposed change. |
| `cross_repo_impact_report()` | Renders an impact plan as a compact Markdown planning report. |
| `qa_cross_repo_impact_analysis()` | Validates dependency graph, ownership map, contract analysis, classification, blast radius, migration guidance, and report generation. |

## Change Categories

The planner recognizes the following categories:

- `documentation_only`
- `internal_implementation`
- `public_api_additive`
- `public_api_breaking`
- `contract_update`
- `workflow_update`
- `operator_change`
- `artifact_change`
- `campaign_behavior`
- `ui_only`
- `qa_only`

When a category is not supplied, the planner infers one from the change summary and file hints. Explicit category selection is preferred for high-stakes work.

## Validation Scope

Validation scope is selected from the category and affected repositories.

Examples:

| Change | Validation |
| --- | --- |
| Documentation only | `source("app.R")`, targeted docs checks where applicable, `git diff --check`, fast cross-repo validation |
| Package public API additive | regenerate metadata, build/install package, installed package QA, consumer contract validation |
| Public API breaking | package rebuild, installed QA, consumer migration, full cross-repo validation |
| Contract update | manifest contract validation, upstream package QA, downstream adapter QA, full cross-repo validation |
| Campaign behavior | campaign QA, remediation QA, improvement ledger QA, Mission Control/cross-system QA |
| UI only | affected page QA, UI consistency QA, source app, diff check |

## Blast Radius

Blast radius is explainable and intentionally conservative:

- `local`: docs, UI, or one small app area
- `repository`: one repository implementation surface
- `cross-package`: package-owned change with app or package consumers
- `cross-system`: manifest contracts, workflows, artifact contracts, or public API breaks
- `campaign`: governed campaign/remediation/ledger behavior
- `mission-critical`: reserved for future production operations that affect execution safety or persisted project integrity

## Planning Workflow

1. Describe the proposed change.
2. Identify or infer the change category.
3. Resolve affected repositories.
4. Lookup owned capabilities and declared contracts.
5. Estimate blast radius.
6. Select validation scope.
7. Determine package rebuild order from local package dependencies.
8. Determine consumer validation order from manifest contracts.
9. Generate migration guidance.
10. Run the recommended QA after implementation.

## Limitations

- The graph contains declared and observed dependencies only.
- Runtime-only dependencies that are not represented in the manifest, package metadata, docs, or capability inventory may be missed.
- The planner does not execute code changes.
- The planner does not replace architectural judgment for ambiguous ownership decisions.
- The planner intentionally avoids speculative future repositories or capabilities.

## Agent Rule

For broad cross-repository work, call `cross_repo_impact_plan()` before editing code. The plan should be included in the task notes or final report when the change touches package contracts, public APIs, artifact behavior, workflow behavior, or campaign/remediation behavior.
