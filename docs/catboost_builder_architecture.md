# CatBoost Builder Architecture

## Purpose

CatBoost Builder v1 is a narrow training and scoring artifact-generator workflow. It trains a CatBoost model from the active app dataset and returns standard artifacts plus scored data that can feed downstream modules:

- Model Assessment
- Regression or Binary Classification Model Insights
- Regression or Binary Classification SHAP Analysis

It is not a broad modeling workbench. The v1 goal is to create reliable model-output artifacts and handoff metadata that fit the existing Artifact Library, report plan, layout, export, and project-state systems.

## Supported V1 Problem Types

CatBoost Builder v1 supports:

- regression
- binary classification

Multiclass is out of scope for v1. Multiclass should not be added until regression and binary CatBoost Builder outputs are stable and the app has a clear multiclass model assessment / insights / SHAP path.

## Ownership Boundary

AutoQuant owns:

- CatBoost training
- CatBoost scoring
- variable importance generation
- optional SHAP column generation
- model-output artifacts
- model/scoring code generation at the AutoQuant level

Analytics Shiny App owns:

- config UI
- app-side config validation
- `service_result` wrapping
- artifact normalization into `aq_artifact`
- report plan creation
- Artifact Library storage and metadata edits
- project save/load
- layouts and export
- generated app replay code that calls AutoQuant high-level functions

shinyelectron owns:

- package/runtime installation
- local dependency source handling
- Electron launch and packaging behavior

The app should not reimplement CatBoost training, scoring, importance, SHAP, or AutoPlots rendering.

## Inputs

V1 should collect a bounded configuration:

- active dataset
- target column
- feature columns
- id/context columns
- optional `DateVar`
- optional `ByVars`
- problem type: `regression` or `binary_classification`
- train/test split settings
- seed
- bounded CatBoost parameters
- binary-only `positive_class`
- binary-only threshold
- prediction scale metadata
- whether to compute SHAP columns
- whether to produce scored train, test, and/or full data

The CatBoost parameter set should stay intentionally small in v1. Suggested controls:

- `task_type`: CPU/GPU
- `NumGPUs`
- `Trees`
- `Depth`
- `LearningRate`
- `L2_Leaf_Reg`
- `LossFunction` / `EvalMetric`
- `MetricPeriods`
- `TrainOnFull`
- `SampleSize` or row limit if needed for local runtime safety

Do not expose grid tuning, large search spaces, or every CatBoost parameter in v1.

## AutoQuant Generator Proposal

Recommended approach:

```r
generate_catboost_builder_artifacts(
  data,
  problem_type = c("regression", "binary_classification"),
  ...
)
```

Use one generator with explicit `problem_type` rather than separate public functions for regression and binary classification.

Rationale:

- The app needs one CatBoost Builder page and one adapter.
- Shared training/scoring configuration is larger than the problem-specific differences.
- One public generator makes Electron validation and app registry wiring simpler.
- Problem-specific output contracts can still be enforced internally.
- Downstream handoff metadata can branch by `problem_type`.

Internal AutoQuant helpers may still be problem-specific if that keeps implementation readable, for example:

- `build_catboost_regression_outputs()`
- `build_catboost_binary_outputs()`
- `normalize_catboost_scored_data()`

If the single generator becomes hard to maintain, split later behind the same app adapter contract. Do not start v1 with two app-facing modules.

## Outputs

The generator should return structured artifacts and metadata suitable for app normalization.

Expected artifacts:

- training config text/table
- data split summary
- model summary
- CatBoost parameter table
- train/test metrics
- variable importance table
- variable importance plot
- prediction distribution plot
- regression actual vs predicted plot
- regression residual diagnostics
- binary confusion/threshold metrics
- binary ROC / PR / calibration / lift diagnostics where available
- scored data artifact or scored-data reference
- downstream handoff metadata

All plots should be AutoPlots-backed. Tables should be `data.table` compatible. Text should be plain text or markdown content.

## Scored Output Contract

Scored output is the most important v1 product. Downstream modules should be able to consume it without needing the raw model object.

### Regression

Scored regression data should include:

- target column
- `Predict`
- `residual`
- id/context columns
- `DateVar` when supplied
- `ByVars` when supplied
- optional `Shap_<feature>` columns when SHAP is requested

Metadata should include:

- `problem_type = "regression"`
- `target_col`
- `prediction_col = "Predict"`
- `residual_col = "residual"`
- `feature_cols`
- `id_cols`
- `DateVar`
- `ByVars`
- `prediction_scale`
- SHAP source/status

### Binary Classification

Scored binary data should include:

- target column
- `Predict`
- `PredictedClass`
- `threshold`
- id/context columns
- `DateVar` when supplied
- `ByVars` when supplied
- optional `Shap_<feature>` columns when SHAP is requested

Metadata should include:

- `problem_type = "binary_classification"`
- `target_col`
- `prediction_col = "Predict"`
- `predicted_class_col = "PredictedClass"`
- `positive_class`
- `threshold`
- `feature_cols`
- `id_cols`
- `DateVar`
- `ByVars`
- `prediction_scale`
- SHAP source/status

## Downstream Handoff

CatBoost Builder should return metadata and generated code that tell the app how to run downstream modules:

- Model Assessment
- Regression Model Insights
- Binary Classification Model Insights
- Regression SHAP Analysis
- Binary Classification SHAP Analysis

V1 should not automatically run those downstream modules. It should provide handoff metadata such as:

```r
metadata = list(
  downstream_handoffs = list(
    model_assessment = list(
      enabled = TRUE,
      data_ref = "scored_test",
      target_col = "...",
      prediction_col = "Predict",
      problem_type = "..."
    ),
    model_insights = list(...),
    shap_analysis = list(
      enabled = TRUE,
      requires_shap_columns = TRUE,
      shap_prefix = "Shap_"
    )
  )
)
```

The app offers Workflow Handoff UX v1 actions after a successful CatBoost Builder run. These actions are explicit user-triggered buttons, not automatic downstream execution:

- Run Model Assessment
- Run Regression or Binary Model Insights
- Run Regression or Binary SHAP when `Shap_` columns exist

The app builds a handoff object from the CatBoost Builder scored output and metadata. The handoff stores:

- `source_module`
- `source_run_id`
- `problem_type`
- `scored_data`
- scored row/column/SHAP summary
- target, prediction, predicted-class, positive-class, threshold, feature, id, date, and by-variable settings
- available downstream module IDs
- recommended downstream configs

When a handoff action runs, the app passes the scored output and recommended config to the existing `run_analysis_module()` path. The downstream result returns normal artifacts and report plans, and those outputs are added to the Artifact Library/report-plan state through the same accepted-result flow used by direct module runs.

The CatBoost Builder run itself must not auto-run downstream modules, mutate downstream page state, or hide downstream failures. If a downstream action fails, it should return a normal `service_result()` failure while preserving the original CatBoost Builder output.

## Artifact And Report Plan Integration

The app adapter should return `service_result()` with:

- `status`
- `artifacts`
- `messages`
- `warnings`
- `errors`
- `metadata`
- `diagnostics`
- `code`

AutoQuant artifacts should be normalized into `aq_artifact` objects with stable run-scoped IDs. Suggested prefix:

- `aq_cb_`

Recommended report plans should reference artifact IDs only. Suggested plans:

- Recommended CatBoost Training Report
- Full CatBoost Training Report
- Diagnostics Only
- Downstream Handoff Summary

Plans must not duplicate artifacts or mutate downstream module state.

## Model Persistence

V1 should not persist raw model objects by default.

Preferred default:

- store model metadata
- store training/scoring configuration
- store generated reproducible code
- store scored data or a scored-data reference
- store artifact summaries and report plans

Optional user-selected behavior:

- save model object to a chosen local path
- store the saved model path in metadata
- validate that the path is local and user-controlled

The scored data is more important than the raw model object for v1 because it enables Model Assessment, Model Insights, and SHAP Analysis without forcing the app to serialize runtime-heavy objects.

## Dependency Implications

Analytics Shiny App:

- should not fail startup if CatBoost Builder is unavailable
- should detect missing AutoQuant generator support and return a friendly `service_result`
- should expose CatBoost Builder as an experimental adapter while the AutoQuant generator continues to stabilize
- should expose downstream handoff actions only when the scored output validates for those modules

AutoQuant:

- should own `generate_catboost_builder_artifacts()`
- should use `catboost` only inside the generator/runtime path
- should expose QA helpers for regression, binary classification, and aggregate CatBoost Builder checks

shinyelectron:

- already supports `catboost` as a URL package in `_shinyelectron.yml`
- should validate `generate_catboost_builder_artifacts()` only when that export is expected in the installed AutoQuant source
- should not force Analytics Shiny App startup to fail when optional experimental module exports are absent unless the app config marks them required

## QA Plan

Future AutoQuant QA:

- `qa_generate_catboost_builder_artifacts_regression()`
- `qa_generate_catboost_builder_artifacts_binary()`
- optional aggregate `qa_generate_catboost_builder_artifacts()`

Future Analytics Shiny App QA:

- `qa_autoquant_catboost_builder_integration()`
- `qa_catboost_downstream_handoff()`
- confirm artifacts normalize into `aq_artifact`
- confirm scored data metadata is present
- confirm report plans reference artifact IDs only
- confirm Workflow Handoff UX v1 exposes only valid downstream actions
- confirm user-triggered handoff actions add downstream artifacts and report plans through the standard accepted-result flow
- confirm project save/load preserves builder artifacts, plan metadata, and scored-data references

Downstream smoke tests:

- builder output feeds Model Assessment
- regression builder output feeds Regression Model Insights
- binary builder output feeds Binary Classification Model Insights
- regression builder output feeds Regression SHAP when SHAP columns are requested
- binary builder output feeds Binary Classification SHAP when SHAP columns are requested

Electron smoke:

- catboost URL dependency installs/loads
- AutoQuant local package exposes the generator after implementation
- app can run the module without Electron-only path issues

## Non-Goals

V1 does not include:

- multiclass
- hyperparameter tuning grids
- broad model registry
- deployment API
- automatic downstream module execution
- arbitrary model families
- broad recipe framework
- GenAI modeling agent
- drag/drop modeling workflows
- direct model-object editing inside the app

## Implementation Phases

### Phase 1: AutoQuant Generator Contract And Fixtures

- define `generate_catboost_builder_artifacts()` signature
- create small regression and binary fixtures
- define scored output contract
- define artifact sections and metadata
- define QA helpers

### Phase 2: AutoQuant CatBoost Training And Scoring Artifacts

- call existing AutoQuant CatBoost training/scoring functions
- return training config, split summary, metrics, importance, diagnostics, scored outputs, and handoff metadata
- optionally generate SHAP columns when requested

### Phase 3: Analytics Shiny App Adapter

- add CatBoost Builder module adapter
- add bounded UI config
- normalize artifacts
- store scored output metadata/reference
- create recommended report plans
- generate reproducible code

### Phase 4: Downstream Handoff QA

- verify builder output can feed Model Assessment
- verify builder output can feed Regression/Binary Model Insights
- verify builder output can feed Regression/Binary SHAP when SHAP columns exist
- expose user-triggered handoff actions in the Analysis Modules page
- verify the CatBoost Builder run does not auto-run downstream modules

### Phase 5: Electron Dependency Smoke

- verify `catboost` URL install
- verify local AutoQuant generator availability
- run focused Electron smoke after module implementation

## First Implementation Task

Start in AutoQuant with Phase 1:

- create the generator contract and fixtures
- implement no app UI yet
- return structured warnings if `catboost` is unavailable
- prove the scored output contract for regression and binary classification

Only after the AutoQuant generator contract is stable should Analytics Shiny App add the CatBoost Builder adapter.
