# AutoQuant Model Assessment Module

## Purpose

The AutoQuant Model Assessment module is the second analysis-module adapter for Analytics Shiny App. It is designed to generate model assessment artifacts from existing actual and prediction columns when AutoQuant exposes a model assessment artifact generator.

## Ownership Boundary

AutoQuant owns model assessment generation. Analytics Shiny App must not reimplement assessment metrics, ROC/PR logic, residual diagnostics, calibration, lift/gains, or segment diagnostics.

Analytics Shiny App owns:

- dependency and function checks
- user configuration collection
- config validation before calling AutoQuant
- `tryCatch` error handling around AutoQuant calls
- conversion of AutoQuant outputs into `aq_artifact` objects
- recommended report-plan creation
- Artifact Library storage
- Layouts page display and final composition
- project save/load of module artifacts and plans

If AutoQuant does not expose a model assessment artifact generator, the adapter returns a friendly `service_result` error and does not run app-side assessment logic.

## Output Contract

When the AutoQuant generator is available, the module returns a `service_result` with:

- generated artifacts
- user-facing status messages
- generated code skeleton
- run metadata
- recommended report plans in `metadata$report_plans`

Artifacts use:

- `source_module = "autoquant_model_assessment"`
- `artifact_id` prefix `aq_ma_`
- readable labels
- model assessment sections
- `module_run_id` metadata
- run timestamp metadata
- model name metadata
- problem type metadata
- actual and prediction column metadata

## Report Plans

The adapter can create:

- Recommended Model Assessment Report
- Full Model Assessment Report
- Diagnostics Only

Regression sections may include:

- Model Overview
- Performance Metrics
- Prediction Diagnostics
- Residual Diagnostics
- Segment / Time Diagnostics
- Appendix

Binary classification sections may include:

- Model Overview
- Classification Metrics
- Threshold Diagnostics
- ROC / PR Analysis
- Calibration
- Lift / Gains
- Segment / Time Diagnostics
- Appendix

Report plans reference artifact IDs only. They do not own artifacts and must not delete artifacts from the Artifact Library.

## Display Flow

1. User uploads data that already contains actual and prediction columns.
2. User configures AutoQuant Model Assessment.
3. The adapter validates column existence and basic column types.
4. If available, AutoQuant generates model assessment outputs.
5. The app converts outputs into artifacts.
6. The Artifact Library stores all artifacts.
7. The adapter creates recommended report plans.
8. The Layouts page previews and applies selected plans.

## QA Helper

`qa_autoquant_model_assessment_integration()` creates synthetic binary classification and regression data.

If AutoQuant exposes a model assessment artifact generator, the helper verifies:

- artifacts are returned
- report plans are returned
- artifact labels are non-empty
- artifact sections are non-empty
- `artifact_summary()` works
- `report_plan_summary()` works

If AutoQuant does not expose the generator, the helper verifies a friendly not-implemented `service_result`.

## Anti-Patterns

Avoid:

- building CatBoost training in this module
- building SHAP in this module
- reimplementing model assessment logic in the app
- creating model-assessment-specific export systems
- creating model-assessment-specific layout systems
- bypassing `service_result`
- bypassing `create_artifact()`
- using `DT`
