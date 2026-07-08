# Workflow Architecture

## Purpose

Workflow UX v1 organizes the existing Analytics Shiny App modules into a flexible analytical lifecycle:

EDA -> Feature Engineering -> Model Prep -> Model Readiness / Target Analysis -> CatBoost Builder -> Model Assessment -> Model Insights -> SHAP Insights -> Report / Export

The Workflow page is a launchpad, not a wizard. It does not run modules automatically, force a sequence, or create a second execution system.

## Lifecycle Stages

| order | stage_id | label | status | module/page | purpose |
| --- | --- | --- | --- | --- | --- |
| 1 | `eda` | EDA | implemented | `autoquant_eda` | Understand data structure, distributions, correlations, and trends. |
| 2 | `feature_engineering` | Feature Engineering | external/future | external today | Create modeling features. Rodeo/PolarsFE app integration is future work. |
| 3 | `model_prep` | Model Prep | external/future | external today | Define partitions, folds, train/test splits, and leakage-safe model data. |
| 4 | `model_readiness` | Model Readiness | implemented | `autoquant_model_readiness` | Target diagnostics, leakage/collider risk, drift, class balance, and modeling recommendations. |
| 5 | `catboost_builder` | CatBoost Builder | experimental | `autoquant_catboost_builder` | Train and score CatBoost regression or binary classification models. |
| 6 | `model_assessment` | Model Assessment | planned | post-model evaluation only | Evaluate trained/scored model performance when a true post-model assessment adapter is wired. |
| 7 | `model_insights` | Model Insights | implemented | `autoquant_regression_model_insights`, `autoquant_binary_model_insights` | Understand model behavior, diagnostics, and feature effects. |
| 8 | `shap_insights` | SHAP Insights | implemented | `autoquant_regression_shap_analysis`, `autoquant_binary_shap_analysis` | Understand prediction-surface behavior using precomputed SHAP columns. |
| 9 | `report_export` | Report / Export | implemented | Layouts and Export pages | Compose, export, and share artifacts. |

## Terminology Rule

Model Readiness is pre-model. In the current app it maps directly to the Target Analysis / readiness adapter, `autoquant_model_readiness`.

Model Assessment is post-model. It is reserved for evaluation of an already trained/scored model and must not be used as the user-facing label for target/readiness diagnostics. The current `model_assessment` registry entry is a planned placeholder. The legacy `autoquant_model_assessment` id is compatibility only and aliases to `autoquant_model_readiness`.

## Module Actions

Workflow stage buttons deep-link to the existing Analysis Modules page when a stage maps to implemented module ids. The Workflow page does not duplicate module runner logic. Analysis Modules remains the owner of:

- module-specific controls
- validation
- execution
- artifact normalization
- report plan creation
- CatBoost downstream handoff actions

## Custom Code Hooks

Every workflow stage can draft custom code through the existing Code Runner architecture:

- pre-stage code
- post-stage code
- standalone exploratory code

Hooks create draft Code Runner requests only. They must include:

- `custom_code_hook = TRUE`
- `workflow_stage`
- `hook_timing`
- `source = "manual"`
- `auto_run = FALSE`

Hooks never auto-run and never bypass `local_trusted` controls.

## Workflow State Summary

`workflow_state_summary()` summarizes existing state rather than creating new state:

- artifact counts by workflow stage
- report plan counts by workflow stage
- latest custom code hook status
- custom code hook draft/history counts
- CatBoost handoff availability when detectable

The Artifact Library remains the inventory. Report plans remain the curated report selection. Workflow is only an orientation and launch surface.

## Non-Goals

- no rigid wizard
- no DAG builder
- no automatic downstream module execution
- no second code execution system
- no new analytics
- no Rodeo/PolarsFE app integration in this pass
- no module-specific export systems
