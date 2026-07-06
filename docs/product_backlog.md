# Analytics Shiny App Product Backlog

Every feature must help the user create, improve, organize, explain, export, or reuse analytical report artifacts.

## Purpose

This backlog keeps Analytics Shiny App focused as a local-first analytical report builder. The app should grow through artifact generators, the Artifact Library, report plans, display pages, export services, and carefully gated automation. It should not become a catch-all analytics platform with one-off workflows, module-specific export systems, or duplicated AutoPlots/AutoQuant logic.

## Current Focus

Near-term development should stabilize the artifact/report-plan foundation before adding more large analytical modules. The next useful work is:

- make AutoQuant EDA artifacts and recommended report plans feel reliable end to end
- stabilize CatBoost Builder v1 app adapter against the AutoQuant generator contract
- keep CatBoost Builder narrow: training/scoring artifacts plus downstream handoff metadata
- harden project save/load for artifacts, report plans, and future code runs
- polish Artifact Library and Layouts report display

## Status Key

- `Done`: implemented or documented enough to serve as a foundation
- `In Progress`: partially implemented and still being stabilized
- `Planned`: intended work with a clear product fit
- `Deferred`: valid idea, but intentionally later
- `Blocked`: cannot proceed without an upstream decision or dependency

## Priority Key

- `P0`: required to keep the current app reliable
- `P1`: next meaningful product capability
- `P2`: important but later
- `P3`: speculative or deliberately delayed

## Backlog

| id | category | feature | priority | phase | status | source | risk |
|---|---|---|---|---|---|---|---|
| BL-001 | Extraction | Extracted app from AutoPlots repo | P0 | Foundation | Done | New App | Low |
| BL-002 | Structure | Flat R/package-like structure | P0 | Foundation | Done | New App | Low |
| BL-003 | Structure | Page modules | P0 | Foundation | Done | New App | Medium |
| BL-004 | UI | UI component layer | P1 | UI/UX | Done | New App | Low |
| BL-005 | UI | Light/dark/pimp theme foundation | P1 | UI/UX | Done | New Idea | Low |
| BL-006 | Artifacts | Custom plot artifacts | P0 | Report Builder | Done | AutoPlots | Medium |
| BL-007 | Artifacts | Custom text artifacts | P1 | Report Builder | Done | New App | Low |
| BL-008 | Tables | Table framework with reactable themes | P1 | Report Builder | Done | New App | Medium |
| BL-009 | Artifacts | Table artifacts | P1 | Report Builder | Done | New App | Medium |
| BL-010 | Artifacts | Artifact model | P0 | Foundation | Done | New App | Medium |
| BL-011 | Artifacts | Artifact Library | P0 | Report Builder | Done | New App | Medium |
| BL-012 | Layouts | Mixed artifact layouts | P0 | Report Builder | Done | New App | Medium |
| BL-013 | Project | Project save/load | P0 | Foundation | Done | New App | High |
| BL-014 | Project | Project bundles | P1 | Platform | Done | New App | Medium |
| BL-015 | Export | Export HTML/R code/export all | P0 | Report Builder | Done | AutoPlots | Medium |
| BL-016 | Tables | Table CSV/XLSX export | P1 | Report Builder | Done | New App | Low |
| BL-017 | Modules | Analysis module registry | P1 | Analysis Modules | Done | New App | Low |
| BL-018 | Modules | AutoQuant EDA adapter | P1 | Analysis Modules | In Progress | AutoQuant | High |
| BL-019 | Plans | Report plan model | P0 | Report Builder | Done | New App | Medium |
| BL-020 | Plans | AutoQuant EDA recommended report plan | P1 | Analysis Modules | In Progress | AutoQuant | High |
| BL-021 | Plans | Report plan editing | P1 | Report Builder | In Progress | New App | Medium |
| BL-022 | Docs | Electron smoke test doc | P1 | Platform | Done | New App | Low |
| BL-023 | Docs | Service contract doc | P0 | Foundation | Done | New App | Low |
| BL-024 | Docs | GenAI architecture doc | P2 | GenAI | Done | New Idea | Medium |
| BL-025 | Docs | UI architecture doc | P1 | UI/UX | Done | New App | Low |
| BL-026 | Docs | Report artifact UX doc | P1 | Report Builder | Done | New App | Low |
| BL-027 | Docs | Analysis module architecture doc | P1 | Analysis Modules | Done | AutoQuant | Low |
| BL-028 | Docs | Table framework doc | P1 | Report Builder | Done | New App | Low |
| BL-029 | Docs | Report plan architecture doc | P1 | Report Builder | Done | New App | Low |
| BL-030 | QA | Stabilize AutoQuant EDA adapter/report plan workflow | P0 | Analysis Modules | Planned | AutoQuant | High |
| BL-031 | Modules | AutoQuant EDA full section support | P1 | Analysis Modules | Planned | AutoQuant | High |
| BL-032 | Modules | AutoQuant Model Readiness adapter | P1 | Analysis Modules | Planned | AutoQuant | High |
| BL-033 | Plans | Model Readiness recommended report plan | P1 | Analysis Modules | Planned | AutoQuant | Medium |
| BL-034 | Code Runner | Code Runner architecture doc | P0 | Code Runner | Planned | New App | Medium |
| BL-035 | Code Runner | code_run_model.R | P0 | Code Runner | Planned | New App | High |
| BL-036 | Code Runner | Manual local trusted code runner prototype | P1 | Code Runner | Planned | New App | High |
| BL-037 | Code Runner | Output-to-artifact conversion | P1 | Code Runner | Planned | New App | High |
| BL-038 | Code Runner | Code history UI | P1 | Code Runner | Planned | New App | Medium |
| BL-039 | UI | Report display polish | P0 | UI/UX | Planned | New App | Medium |
| BL-040 | UI | Artifact Library polish | P0 | UI/UX | Planned | New App | Medium |
| BL-041 | Project | Project save/load QA for artifacts/plans/code runs | P0 | Release | Planned | New App | High |
| BL-042 | Platform | Electron smoke test after module additions | P0 | Platform | Planned | New App | Medium |
| BL-043 | Modules | Target Analysis adapter | P2 | Analysis Modules | Planned | AutoQuant | High |
| BL-044 | Modules | Model Insights adapter | P2 | Analysis Modules | Planned | AutoQuant | High |
| BL-045 | Modules | SHAP Analysis design | P2 | Analysis Modules | Planned | AutoQuant | Medium |
| BL-046 | Modules | SHAP Analysis module | P2 | Analysis Modules | Planned | AutoQuant | High |
| BL-047 | Modules | CatBoost Builder module | P1 | Analysis Modules | In Progress | AutoQuant | High |
| BL-048 | Modules | Forecasting module | P2 | Analysis Modules | Planned | New Idea | High |
| BL-049 | Plans | Recommended report plans for each module | P2 | Analysis Modules | Planned | New App | Medium |
| BL-050 | GenAI | Data profile object | P1 | GenAI | Planned | New App | Medium |
| BL-051 | GenAI | GenAI settings page | P2 | GenAI | Planned | New Idea | Medium |
| BL-052 | GenAI | GenAI action registry | P1 | GenAI | Planned | New Idea | High |
| BL-053 | GenAI | GenAI policy object | P1 | GenAI | Planned | New Idea | High |
| BL-054 | GenAI | Proposal object | P1 | GenAI | Planned | New Idea | High |
| BL-055 | GenAI | Permission gate hooks | P1 | GenAI | Planned | New Idea | High |
| BL-056 | GenAI | Plot recommendations | P2 | GenAI | Planned | New Idea | Medium |
| BL-057 | GenAI | Title/caption generation | P2 | GenAI | Planned | New Idea | Medium |
| BL-058 | GenAI | Section summaries | P2 | GenAI | Planned | New Idea | Medium |
| BL-059 | GenAI | Report reviewer | P2 | GenAI | Planned | New Idea | High |
| BL-060 | GenAI | Starter report generator | P2 | GenAI | Planned | New Idea | High |
| BL-061 | GenAI | GenAI proposed code with approval | P2 | GenAI | Planned | New Idea | High |
| BL-062 | GenAI | Agent Mode | P3 | GenAI | Deferred | New Idea | High |
| BL-063 | Code Runner | Code execution policy object | P0 | Code Runner | Planned | New App | High |
| BL-064 | Code Runner | Permission hooks | P0 | Code Runner | Planned | New App | High |
| BL-065 | Code Runner | Code run request/result model | P0 | Code Runner | Planned | New App | High |
| BL-066 | Code Runner | Code tracker record model | P1 | Code Runner | Planned | New App | Medium |
| BL-067 | Code Runner | Captured logs/warnings/errors | P1 | Code Runner | Planned | New App | Medium |
| BL-068 | Code Runner | Rerun previous code | P2 | Code Runner | Planned | New App | Medium |
| BL-069 | Code Runner | Export reproducible script | P2 | Code Runner | Planned | New App | Medium |
| BL-070 | Code Runner | GenAI proposed code approval | P2 | Code Runner | Planned | New Idea | High |
| BL-071 | UI | Plot Builder polish | P1 | UI/UX | Planned | New App | Medium |
| BL-072 | UI | Artifact Library card/list toggle | P2 | UI/UX | Planned | New App | Low |
| BL-073 | UI | Report Plan preview polish | P1 | UI/UX | Planned | New App | Medium |
| BL-074 | UI | Layout preview polish | P1 | UI/UX | Planned | New App | Medium |
| BL-075 | UI | Better empty states | P1 | UI/UX | Planned | New App | Low |
| BL-076 | Settings | App settings page | P2 | UI/UX | Planned | New App | Medium |
| BL-077 | Settings | Theme selector | P2 | UI/UX | Planned | New App | Low |
| BL-078 | Settings | App theme persistence | P2 | UI/UX | Planned | New App | Medium |
| BL-079 | Layouts | Carousel display mode | P2 | Report Builder | Planned | New Idea | Medium |
| BL-080 | Layouts | Canvas/drag-drop layout | P3 | Report Builder | Deferred | New Idea | High |
| BL-081 | UI | Resizable cards | P3 | UI/UX | Deferred | New Idea | Medium |
| BL-082 | Platform | Permissions contract | P1 | Platform | Planned | New App | High |
| BL-083 | Platform | Role model | P2 | Platform | Planned | New Idea | High |
| BL-084 | Platform | App settings persistence | P2 | Platform | Planned | New App | Medium |
| BL-085 | Platform | Audit log | P2 | Platform | Planned | New App | Medium |
| BL-086 | Platform | GenAI audit log | P2 | Platform | Planned | New Idea | High |
| BL-087 | Platform | Code execution audit log | P1 | Platform | Planned | New App | High |
| BL-088 | Platform | Security review | P1 | Release | Planned | New App | High |
| BL-089 | Platform | Packaged Electron release workflow | P2 | Platform | Planned | New App | High |
| BL-090 | Docs | Installer/build docs | P2 | Platform | Planned | New App | Medium |
| BL-091 | Release | Sample datasets | P1 | Release | Planned | New App | Low |
| BL-092 | Release | Smoke test scripts | P1 | Release | Planned | New App | Medium |
| BL-093 | Docs | README polish | P1 | Release | Planned | New App | Low |
| BL-094 | Release | Dependency check | P0 | Release | Planned | New App | Medium |
| BL-095 | Release | Release checklist | P1 | Release | Planned | New App | Low |
| BL-096 | Release | Electron smoke test | P1 | Release | Planned | New App | Medium |
| BL-097 | Docs | Known limitations doc | P1 | Release | Planned | New App | Low |
| BL-098 | Modules | SHAP Phase 1 scaffolding | P2 | Analysis Modules | Done | AutoQuant | Medium |
| BL-099 | Modules | Regression SHAP app adapter | P1 | Analysis Modules | Done | AutoQuant | Medium |
| BL-100 | Modules | Binary Classification SHAP app adapter | P1 | Analysis Modules | Done | AutoQuant | Medium |
| BL-101 | Docs | CatBoost Builder architecture doc | P1 | Analysis Modules | Done | AutoQuant | Medium |
| BL-102 | Modules | AutoQuant CatBoost Builder generator contract | P0 | Analysis Modules | Done | AutoQuant | High |
| BL-103 | Modules | Analytics Shiny App CatBoost Builder adapter | P1 | Analysis Modules | Done | AutoQuant | High |
| BL-104 | Modules | CatBoost downstream handoff UX | P1 | Analysis Modules | Done | New App | Medium |
| BL-105 | Code Runner | Custom code hooks for workflow stages | P1 | Code Runner | Done | New App | High |

See `docs/product_backlog.csv` for the sortable backlog with descriptions, dependencies, and notes.

## Do Not Do Yet

- Do not build broad CatBoost workbench features before the narrow v1 generator contract is stable.
- Do not add GenAI Agent Mode before proposal/action/policy scaffolding.
- Do not build drag/drop canvas before grid/sections/report plans are stable.
- Do not create module-specific export systems.
- Do not reimplement AutoQuant logic in the app.
- Do not use DT as the core table framework.
- Do not allow GenAI or code runner to bypass permissions/policies.

## Execution Notes

- Prefer small vertical passes: model, UI wiring, project persistence, smoke test, documentation.
- New analysis modules should return standard artifacts and optional report plans.
- New display modes should consume artifacts and plans; they should not create new artifact state.
- New automation must pass through policy, permission, and audit hooks before it can mutate app state.
