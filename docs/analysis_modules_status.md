# Analysis Modules Status

Every analysis module is an artifact generator. The Analytics Shiny App owns orchestration, artifact storage, report plans, display, export, and project persistence. AutoQuant remains the analysis engine for the modules listed here.

## Current Modules

| module_id | AutoQuant source function | status | supported problem types | expected artifact types | report plans created | QA helper | known limitations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| autoquant_eda | `generate_eda_artifacts()` | Experimental adapter | General tabular EDA | plot, table, text | Recommended, Full, Diagnostics Only | `qa_autoquant_eda_integration()` | Depends on available EDA inputs selected by the user; exported replay code still marks app-side conversion as TODO. |
| autoquant_model_assessment | `generate_model_assessment_artifacts()` | Experimental adapter | Regression, Binary Classification | plot, table, text | Recommended, Full, Diagnostics Only | `qa_autoquant_model_assessment_integration()` | Uses the current AutoQuant model assessment artifact generator contract; exported replay code still marks app-side conversion as TODO. |
| autoquant_regression_model_insights | `generate_regression_model_insights_artifacts()` | Experimental adapter | Regression model diagnostics from model outputs/predictions | plot, table, text | Recommended, Full, Feature Effects Only, Diagnostics Only | `qa_autoquant_regression_model_insights_integration()` | Requires regression target/prediction columns and available AutoQuant support; richer model-object integration is deferred. |
| autoquant_binary_model_insights | `generate_binary_classification_model_insights_artifacts()` | Experimental adapter | Binary classification model diagnostics from target and prediction scores | plot, table, text | Recommended, Full, Threshold Diagnostics, Feature Effects Only | `qa_autoquant_binary_model_insights_integration()` | Uses structured AutoQuant artifacts as the source of truth; `BinaryClassificationModelInsightsReport()` remains the optional AutoQuant-native standalone renderer, not the primary app integration path. |
| autoquant_regression_shap_analysis | `generate_regression_shap_analysis_artifacts()` | Experimental adapter | Regression SHAP analysis from precomputed `Shap_` columns | plot, table, text | Recommended, Full, Interaction Diagnostics, Segment And Time Effects, Local Explanations, Diagnostics Only when artifacts exist | `qa_autoquant_regression_shap_analysis_integration()` | AutoQuant owns SHAP artifact generation. The app validates precomputed SHAP inputs, normalizes AutoQuant artifacts, and creates report plans. `RegressionShapAnalysisReport()` remains an optional AutoQuant-native standalone renderer, not the app ingestion path. |
| autoquant_binary_shap_analysis | `generate_binary_classification_shap_analysis_artifacts()` | Experimental adapter | Binary classification SHAP analysis from precomputed `Shap_` columns | plot, table, text | Recommended, Full, Threshold Context, Class Balance And Outcome Context, Interaction Diagnostics, Segment And Time Effects, Local Explanations, Diagnostics Only when artifacts exist | `qa_autoquant_binary_shap_analysis_integration()` | AutoQuant owns SHAP artifact generation. The app validates positive class, prediction scale, threshold, precomputed SHAP inputs, normalizes AutoQuant artifacts, and creates report plans. Native AutoQuant standalone report rendering is separate from the app ingestion path. |
| autoquant_multiclass_shap_analysis | Future AutoQuant multiclass SHAP generator | Deferred scaffold | Multiclass SHAP prediction-surface analysis | plot, table, text | Deferred | n/a | Multiclass SHAP is explicitly deferred until regression and binary SHAP are stable. |
| autoquant_catboost_builder | `generate_catboost_builder_artifacts()` | Experimental adapter | Regression and binary classification CatBoost training and scoring | plot, table, text | CatBoost Builder Summary, Training Diagnostics, Scored Output, Downstream Handoff | `qa_autoquant_catboost_builder_integration()` | AutoQuant owns CatBoost training, scoring, variable importance, SHAP column generation, and model-output artifact creation. AnalyticsShinyApp only validates config, calls the generator, normalizes artifacts, preserves scored output metadata, and creates report plans. Regression QA passes with local AutoQuant loaded. Binary QA currently reports an upstream AutoQuant training warning (`invalid first argument`) and the app preserves it as a `service_result()` failure. Multiclass, grid tuning, model registry, and automatic downstream execution are out of scope for v1. |

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
- Regression SHAP Analysis: `aq_rshap_`
- Binary Classification SHAP Analysis: `aq_bshap_`
- Multiclass SHAP Analysis: `aq_mshap_`
- CatBoost Builder: `aq_catboost_`

## SHAP Integration Status

SHAP Analysis follows `docs/shap_analysis_architecture.md`. The app now has shared SHAP contracts plus real Regression and Binary Classification SHAP adapters:

- `shap_problem_types()`
- `shap_date_aggregations()`
- `shap_sections()`
- `shap_lenses()`
- `create_shap_analysis_config()`
- `validate_shap_analysis_config()`
- `create_shap_artifact_metadata()`
- `create_shap_report_plan_specs()`

AutoQuant owns the functions that generate SHAP analyses and SHAP artifact payloads. Analytics Shiny App owns only app-side config validation, missing-generator checks, adapter calls, artifact normalization, and report-plan scaffolding.

Regression and Binary Classification SHAP input data must already contain numeric columns whose names start with `Shap_`. For example, `Shap_Impressions` maps to source feature `Impressions`. AutoQuant modeling functions are responsible for creating SHAP values upstream when requested; Analytics Shiny App does not compute SHAP values, call model prediction functions, or call SHAP backend packages.

Regression SHAP artifacts include AutoPlots-backed plot widgets, data.table-compatible tables, and text artifacts. Interaction diagnostics use binned or leveled combinations from ordinary `Shap_` columns and source variables; exact pairwise SHAP interaction values remain deferred unless upstream interaction-specific outputs exist.

Binary Classification SHAP artifacts include threshold context and class balance / outcome context when AutoQuant returns those sections. Multiclass SHAP remains deferred. SHAP module runners return structured warnings when required AutoQuant generators are unavailable, which prevents the app from pretending to compute SHAP values before the AutoQuant engines exist.

## Project Persistence

Module artifacts are stored in module artifact state, not as fake Plot Builder configs. Report plans and `active_plan_id` are part of project state and should survive:

- save project
- load project
- save bundle
- load bundle

## Aggregate QA

Use `qa_analysis_modules_integration()` to run all available module QA helpers and return one compact summary table. Individual module helpers may return a warning or dependency/config message when AutoQuant support is unavailable rather than throwing raw errors.
