# Ecosystem Operating Model

## Purpose

This document defines how one developer plus Codex can keep the Analytics Shiny App ecosystem moving without losing the product philosophy.

This is not a multi-agent architecture. It is a single product ecosystem operating model.

For cross-repository validation across AnalyticsShinyApp, Rodeo, AutoQuant, and AutoPlots, use `docs/cross_repository_agent_guide.md` and the manifest at `config/cross_repo_workspace.json`.

## Operating Loop

1. Define the product goal.
2. Identify the owning repo.
3. Read the relevant architecture docs.
4. Make the smallest contract-preserving change.
5. Add or update targeted QA.
6. Update docs/backlog/status if the architecture or roadmap changed.
7. Run the safe validation set.
8. Summarize results, limitations, and the next task.

The loop should favor steady, reviewable steps over broad rewrites.

## Pre-Product Overhaul Rule

When the ecosystem is still pre-product, prefer API clarity over compatibility inertia.

Breaking changes are worth considering when they:

- reduce the number of public paths
- make the preferred workflow obvious
- simplify copy/paste examples
- protect artifact-first contracts
- keep repo ownership boundaries clean
- remove generic legacy names that confuse users

Do not preserve an API solely because it already exists. Preserve legacy paths only when they help transition users to the preferred path.

## Workflow Lifecycle

The product lifecycle is:

EDA -> Model Readiness -> Feature Engineering / Model Preparation -> CatBoost Builder -> Model Assessment -> Model Insights -> SHAP Insights -> Report / Export

The Workflow page is a launchpad across that lifecycle. It is not a wizard and not an automation engine.

Stage ownership:

| lifecycle stage | primary owner | app responsibility |
| --- | --- | --- |
| EDA | AutoQuant | configure, run adapter, normalize artifacts, create plans |
| Model Readiness | AutoQuant | target/readiness adapter, artifacts, plans |
| Feature Engineering / Model Preparation | AnalyticsShinyApp | deterministic preparation controls, prepared-data artifacts, transformation lineage, report plan |
| CatBoost Builder | AutoQuant | config UI, service_result wrapping, artifacts, scored data handoff |
| Model Assessment | AutoQuant | post-model evaluation adapter |
| Model Insights | AutoQuant | regression/binary insight adapters |
| SHAP Insights | AutoQuant | regression/binary SHAP adapters |
| Report / Export | AnalyticsShinyApp | library, plans, layouts, exports, project state |

## Artifact Flow

The standard flow is:

1. A generator module validates inputs.
2. The generator returns `service_result()` with artifacts, code, metadata, and optional report plans.
3. AnalyticsShinyApp normalizes artifacts with `create_artifact()`.
4. Artifacts enter the Artifact Library.
5. Report plans curate artifact IDs into sections and order.
6. Layouts render visible selected artifacts.
7. Export writes report outputs and reproducible code.
8. Project save/load persists state that can be reconstructed locally.

Artifacts are the bridge between analytical generation and report composition.

## Module Flow

Analysis modules are artifact generators. They may collect configuration, validate inputs, run analytical logic, preview artifacts internally, and return artifacts.

They may not own final layout, export orchestration, project-level display decisions, or global state mutation.

Modules should return:

- `service_result()`
- `artifacts`
- `metadata`
- `code`
- `metadata$report_plans` when plans are useful

## Report Plan Flow

Report plans are curated views over the Artifact Library.

They should:

- reference artifact IDs only
- support preview without applying
- validate missing/hidden/duplicate artifacts
- preserve Artifact Library separation
- persist through project save/load

Removing an artifact from a plan must not delete it from the Artifact Library.

## Code Runner Flow

Code Runner is the only execution system.

Custom code may be:

- pre-stage code
- post-stage code
- standalone exploratory code between stages

Custom code may produce:

- modified datasets
- plots
- tables
- text artifacts
- handoff notes

Custom code must be user-triggered, use existing local trusted execution controls, create immutable history records, and support duplicate/rerun through the existing Code History workflow.

## Repo Selection Rules

Use the owning repo first:

- product UX or state: AnalyticsShinyApp
- analytical generator or report renderer: AutoQuant
- plot function/theme/display helper: AutoPlots
- R feature engineering/model prep: Rodeo
- Python feature engineering/model prep: PolarsFE
- performance evidence: Benchmarks
- Electron packaging/runtime: shinyelectron

If a task spans repos, implement the upstream contract first, then the app adapter, then runtime packaging only if needed.

## Documentation Expectations

Docs should move with the code. A task that changes architecture should update at least one of:

- `architecture_constitution.md`
- `repo_contracts.md`
- module-specific architecture docs
- status docs
- product backlog
- smoke test docs

Codex final responses should report docs touched and QA run.

## Future Codex Task Framing

Good Codex tasks should include:

- target repo
- owning boundary
- explicit non-goals
- files or docs to inspect
- expected contract
- QA commands or helper names
- documentation updates
- final response requirements

Use `docs/agent_task_template.md` as the starting point.

## Deferred Areas

Current deferred areas:

- multiclass SHAP
- Spark benchmarks
- Model-Based Features redesign
- broad model registry
- automatic workflow execution

Deferred work should stay visible in backlog/status docs but should not leak into current implementation scope.
