# AutoQuant Binary Classification Model Insights Module

## Purpose

The AutoQuant Binary Classification Model Insights module adapts binary classification model insight outputs into Analytics Shiny App artifacts and report plans.

`AutoQuant::generate_binary_classification_model_insights_artifacts()` is the source of truth for artifact generation. The app does not reimplement model diagnostics, threshold analysis, calibration, ROC/PR analysis, lift/gains, or feature-effect logic.

## Integration Rule

The Analytics Shiny App is the adapter and report builder:

- collect selected app inputs
- validate app-side configuration
- call `AutoQuant::generate_binary_classification_model_insights_artifacts()`
- normalize returned structured artifacts with `create_artifact()`
- add artifacts to the Artifact Library
- create recommended report plans

The app should not call `AutoQuant::BinaryClassificationModelInsightsReport()` as the primary integration path. That function is the AutoQuant-native standalone HTML renderer and may be used later as a native export option.

## Module ID

`autoquant_binary_model_insights`

## Expected Inputs

- target column
- prediction/score column
- positive class
- feature columns
- model ID
- optional source path/model object support as AutoQuant evolves
- threshold and threshold-optimization settings
- theme
- sample size

## Expected Artifact Types

The adapter accepts standard artifact types returned by AutoQuant:

- `plot`
- `table`
- `text`

Normalized artifact IDs use the run-scoped prefix:

`aq_bmi_`

## Standard Metadata

Each normalized artifact should include:

- `module_id = "autoquant_binary_model_insights"`
- `module_run_id`
- `source_module = "autoquant_binary_model_insights"`
- `original_name`
- `original_section`
- `normalized_section`
- `artifact_index`
- `created_by_module = TRUE`

Run metadata should include:

- `source_package = "AutoQuant"`
- `source_function = "generate_binary_classification_model_insights_artifacts"`
- selected target/prediction/positive class inputs
- artifact counts
- report plan counts

## Report Plans

The adapter creates report plans when matching artifacts are available:

- Recommended Binary Classification Model Insights Report
- Full Binary Classification Model Insights Report
- Threshold Diagnostics Report
- Feature Effects Only

Plans are curated selections and orderings. Removing an artifact from a plan must not remove it from the Artifact Library.

## QA Helper

Use:

`qa_autoquant_binary_model_insights_integration()`

The helper creates a small synthetic binary classification fixture, runs the module when the AutoQuant generator is available, checks artifacts and report plans, and verifies shared module-result conventions.

If the AutoQuant generator is not installed, the helper should return a structured warning rather than throwing a raw error.

## Anti-Patterns

Avoid:

- reimplementing AutoQuant model insight calculations in the app
- using `ggplot2` or other non-AutoPlots rendering paths for this adapter
- calling the standalone AutoQuant HTML report as the app's primary integration
- storing module artifacts as fake Plot Builder configs
- creating module-specific export systems
- bypassing `service_result()`
