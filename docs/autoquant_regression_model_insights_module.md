# AutoQuant Regression Model Insights Module

## Purpose

The AutoQuant Regression Model Insights module adapts `AutoQuant::generate_regression_model_insights_artifacts()` into Analytics Shiny App artifacts and report plans.

## Ownership Boundary

`AutoQuant::generate_regression_model_insights_artifacts()` is the source-of-truth generator for regression model insight artifacts. Analytics Shiny App only validates user configuration, calls the generator, catches errors, and adapts returned objects into the app artifact and report-plan model.

`AutoQuant::RegressionModelInsightsReport()` is the AutoQuant-native renderer/export path for those generated artifacts. The app does not call that RMarkdown renderer as the primary ingestion path.

## Output Contract

The adapter returns a `service_result` containing:

- generated artifacts
- status messages
- generated code skeleton
- run metadata
- recommended report plans in `metadata$report_plans`

Artifacts use:

- `source_module = "autoquant_regression_model_insights"`
- `artifact_id` prefix `aq_rmi_`
- readable labels
- report sections for overview, importance, effects, prediction diagnostics, residual diagnostics, and feature diagnostics
- `module_run_id` metadata
- timestamp metadata
- model/source/sample metadata
- original AutoQuant output name metadata

## Report Plans

The adapter creates app-side report plans when matching artifacts exist:

- Recommended Regression Model Insights Report
- Full Regression Model Insights Report
- Feature Effects Only
- Diagnostics Only

Report plans reference artifact IDs only. They do not own artifacts and must not delete artifacts from the Artifact Library.

## QA Helper

`qa_autoquant_regression_model_insights_integration()` builds a small local regression fixture, runs the real AutoQuant generator, and verifies:

- artifacts are returned
- report plans are returned
- labels are non-empty
- sections are non-empty
- `artifact_summary()` works
- `report_plan_summary()` works

If the generator is unavailable, the helper returns a clear warning instead of a false pass.

## Anti-Patterns

Avoid:

- reimplementing model insights logic in the app
- calling `RegressionModelInsightsReport()` as the primary app ingestion path
- creating module-specific export systems
- creating module-specific layout systems
- bypassing `service_result`
- bypassing `create_artifact()`
- building SHAP or CatBoost training in this module
- using `DT`
