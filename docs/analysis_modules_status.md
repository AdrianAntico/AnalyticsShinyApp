# Analysis Modules Status

Every analysis module is an artifact generator. The Analytics Shiny App owns orchestration, artifact storage, report plans, display, export, and project persistence. AutoQuant remains the analysis engine for the modules listed here.

## Current Modules

| module_id | AutoQuant source function | status | supported problem types | expected artifact types | report plans created | QA helper | known limitations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| autoquant_eda | `generate_eda_artifacts()` | Experimental adapter | General tabular EDA | plot, table, text | Recommended, Full, Diagnostics Only | `qa_autoquant_eda_integration()` | Depends on available EDA inputs selected by the user; exported replay code still marks app-side conversion as TODO. |
| autoquant_model_assessment | `generate_model_assessment_artifacts()` | Experimental adapter | Regression, Binary Classification | plot, table, text | Recommended, Full, Diagnostics Only | `qa_autoquant_model_assessment_integration()` | Uses the current AutoQuant model assessment artifact generator contract; exported replay code still marks app-side conversion as TODO. |
| autoquant_regression_model_insights | `generate_regression_model_insights_artifacts()` | Experimental adapter | Regression model diagnostics from model outputs/predictions | plot, table, text | Recommended, Full, Feature Effects Only, Diagnostics Only | `qa_autoquant_regression_model_insights_integration()` | Requires regression target/prediction columns and available AutoQuant support; richer model-object integration is deferred. |
| autoquant_binary_model_insights | `generate_binary_classification_model_insights_artifacts()` | Experimental adapter | Binary classification model diagnostics from target and prediction scores | plot, table, text | Recommended, Full, Threshold Diagnostics, Feature Effects Only | `qa_autoquant_binary_model_insights_integration()` | Uses structured AutoQuant artifacts as the source of truth; `BinaryClassificationModelInsightsReport()` remains the optional AutoQuant-native standalone renderer, not the primary app integration path. |

## Shared Run Metadata

Successful module runs should return a `service_result()` with artifacts in `artifacts` and report plans in `metadata$report_plans`.

Run metadata should include:

- `module_id`
- `module_run_id`
- `generated_at`
- `data_name` when available
- `source_package`
- `source_function`
- `configured_inputs`
- `artifact_count`
- `plot_count`
- `table_count`
- `text_count`
- `report_plan_count`

The legacy keys `run_timestamp`, `n_artifacts`, `artifact_counts`, and `n_report_plans` are currently retained for compatibility while the app settles on the standardized names.

## Shared Artifact Metadata

Module-generated artifacts should include:

- `module_id`
- `module_run_id`
- `source_module`
- `original_name`
- `original_section`
- `normalized_section`
- `artifact_index`
- `created_by_module = TRUE`
- `generated_at`

Each adapter may add module-specific metadata such as selected variables, model name, problem type, target/prediction columns, source path, or sample size.

## Artifact IDs

Module artifacts use run-scoped prefixes to avoid collisions across repeated runs:

- AutoQuant EDA: `aq_eda_`
- Model Assessment: `aq_ma_`
- Regression Model Insights: `aq_rmi_`
- Binary Classification Model Insights: `aq_bmi_`

## Project Persistence

Module artifacts are stored in module artifact state, not as fake Plot Builder configs. Report plans and `active_plan_id` are part of project state and should survive:

- save project
- load project
- save bundle
- load bundle

## Aggregate QA

Use `qa_analysis_modules_integration()` to run all available module QA helpers and return one compact summary table. Individual module helpers may return a warning or dependency/config message when AutoQuant support is unavailable rather than throwing raw errors.
