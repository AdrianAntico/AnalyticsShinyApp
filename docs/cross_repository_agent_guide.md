# Cross-Repository Agent Guide

## Purpose

Analytics Workstation is implemented across several sibling repositories. This guide describes how an agent should discover those repositories, respect ownership boundaries, and validate cross-repository compatibility without converting the ecosystem into a monorepo or inventing a separate build system.

The owning coordination repository is `AnalyticsShinyApp`.

## Repositories

| Repository | Role | Owner Boundary |
| --- | --- | --- |
| `AnalyticsShinyApp` | Product shell, Shiny UI, workflow orchestration, project state, Artifact Studio, collector, GenAI action layer, remediation, campaigns, and cross-repo validation. | May coordinate and validate external contracts. Should not copy package internals. |
| `Rodeo` | Feature engineering, model preparation, and fit/apply transformation contracts. | Owns feature transformation implementation. App may call exported artifacts/contracts only. |
| `AutoQuant` | Analytical artifact generators for EDA, readiness, model assessment, model insights, SHAP, and CatBoost Builder. | Owns analytical computation and package-level artifact generation. |
| `AutoPlots` | Production chart functions, themes, composite views, display helpers, and widget output. | Owns rendering APIs and chart internals. |

## Manifest

The canonical workspace manifest is:

```text
config/cross_repo_workspace.json
```

It records expected repository names, environment variable overrides, relative/sibling fallback paths, repo roles, documentation entry points, validation suites by mode, expected package exports, and cross-repository contracts.

The manifest is intentionally explicit. Do not invent QA function names in a task prompt. If a QA function is not implemented or exported, record that as a skip, warning, or contract failure.

## Path Resolution

The orchestrator resolves paths in this order:

1. Repository-specific environment variable, such as `AUTOQUANT_REPO`.
2. Manifest-relative path, such as `../AutoQuant`.
3. Sibling directory next to `AnalyticsShinyApp`.

Missing optional validation should be skipped honestly. Missing required repositories should be classified as environment failures.

## Validation Modes

The entry function is:

```r
cross_repo_validate(mode = "fast")
```

Supported modes:

| Mode | Intent |
| --- | --- |
| `fast` | Discover repos, capture git/package metadata, source the app, run orchestrator QA, and check package load where available. |
| `standard` | Includes fast checks plus selected implemented QA entry points that are useful for cross-repo compatibility. |
| `full` | Includes standard checks plus heavier package/app QA where available. It may be skipped or warn when optional local dependencies are absent. |

Command-line entry:

```powershell
Rscript scripts/cross_repo_validate.R fast
Rscript scripts/cross_repo_validate.R standard
Rscript scripts/cross_repo_validate.R full
```

Package install isolation can be explicitly requested:

```powershell
Rscript scripts/cross_repo_validate.R standard --install-packages
```

The default does not install packages.

## Temporary Library Policy

When package installation is requested, the orchestrator uses a temporary library path and does not silently fall back to the user library for that isolated install check.

Package install failures are environment failures unless the package installed successfully and its QA then fails.

## Failure Classification

| Classification | Meaning |
| --- | --- |
| `environment` | Missing repo, missing package, missing dependency, package install failure, unavailable Rscript, or path issue. |
| `contract` | Missing expected export, unavailable declared QA function, or contract mismatch. |
| `product` | Required validation code executed and failed. |
| `not_applicable` | Intentional skip or no suite declared. |

Agents should preserve this distinction in final reports.

## Outputs

Every validation run writes:

```text
exports/cross_repo_validation/<run_id>/result.json
exports/cross_repo_validation/<run_id>/summary.md
```

These outputs are partial-result friendly. A missing optional repository or unavailable optional QA should not prevent the rest of the validation from running.

## Agent Workflow

1. Read this guide and `docs/ecosystem_operating_model.md`.
2. Read `config/cross_repo_workspace.json`.
3. Run `cross_repo_validate(mode = "fast")`.
4. Inspect environment and contract failures before editing code.
5. Make changes only in the owning repo.
6. Re-run the narrow repo QA.
7. Re-run cross-repo validation at the smallest mode that proves the contract.
8. Report exact passes, warnings, skips, failures, and remaining gaps.

## Current Limitations

- The orchestrator is not a monorepo build tool.
- It does not infer hidden QA entry points.
- It does not install packages unless requested.
- It does not resolve remote repositories.
- It does not replace package-specific QA suites.
- It validates package exports through installed namespaces, so source-only changes in sibling repos require an explicit isolated install or local package install before export checks can pass against those changes.
