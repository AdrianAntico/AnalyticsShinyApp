# Analysis Module Architecture

## Core Principle

Analysis modules are artifact generators.

They may:

- collect module-specific configuration
- validate inputs
- run analysis, modeling, or forecasting
- preview generated artifacts internally
- return artifacts to the Artifact Library

They may not:

- own final report layout
- directly mutate Display or Layout page state
- export reports directly
- bypass artifact validation
- bypass `service_result`
- create ad hoc rendering systems

The app should avoid Quantico-style scope and edge-case sprawl by keeping module execution, artifact state, display composition, export, and project persistence as separate responsibilities.

## Standard Module Contract

Each analysis module should define:

- `module_id`
- `label`
- `description`
- `category`
- `ui` function
- `server` function, if needed
- `default_config` function
- `validate_config` function
- `run` function
- artifact output types
- required packages
- generated code support
- permissions, eventually
- GenAI action hooks, eventually

The UI and server functions collect and preview module-specific configuration. The `run` function performs the bounded analytical workflow and returns a standard `service_result`. Modules should not write directly into app-level reactive state.

## Module Registry

The app should eventually expose a flat `module_registry` object, similar in spirit to `plot_registry` and `option_registry`.

Example modules:

- `eda_report`
- `target_analysis`
- `model_assessment`
- `model_insights`
- `shap_analysis`
- `forecasting`
- `catboost_builder`

Each registry entry should include:

- `module_id`
- `label`
- `category`
- `description`
- `output_artifact_types`
- `supports_genai`
- `supports_code_generation`
- `required_packages`
- `status`: one of `planned`, `experimental`, or `stable`

Example shape:

```r
module_registry <- list(
  eda_report = list(
    module_id = "eda_report",
    label = "EDA Report",
    category = "Exploration",
    description = "Generate exploratory tables, plots, diagnostics, and warnings.",
    output_artifact_types = c("table", "plot", "text", "metric"),
    supports_genai = TRUE,
    supports_code_generation = TRUE,
    required_packages = c("AutoQuant", "AutoPlots", "data.table"),
    status = "planned"
  )
)
```

Registry metadata should make modules inspectable without forcing the app shell to know module-specific internals.

## Module Run Contract

A module run should return `service_result`.

Example:

```r
service_result(
  status = "success",
  artifacts = list(...),
  messages = "EDA report artifacts generated.",
  warnings = character(),
  errors = character(),
  metadata = list(
    module_id = "eda_report",
    n_artifacts = 12
  ),
  code = "..."
)
```

Run results should use:

- `status` for success, warning, error, or needs-input state
- `artifacts` for standard artifact objects
- `messages`, `warnings`, and `errors` for user-facing communication
- `diagnostics` for developer-facing details
- `metadata` for module run context
- `code` for reproducible generated R code when supported

The page module or app shell may decide whether to add returned artifacts to the Artifact Library, but the analysis module should not mutate the library directly.

## Module Artifact Contract

Modules should return standard artifacts created with `create_artifact()`.

Artifact types may include:

- `plot`
- `table`
- `text`
- `metric`
- `model_summary`
- `forecast_block`
- `genai_narrative`

Artifacts should include enough metadata to support validation, display, export, project save/load, and future GenAI reasoning. At minimum, modules should set:

- `artifact_id`
- `artifact_type`
- `label`
- `source_module`
- `object` or `content`
- `config`
- `code`
- `metadata`
- `section`
- `order`
- `visible`
- `status`

Modules may recommend `section`, `order`, and labels, but those values remain editable in the Artifact Library and Display/Layout pages.

## AutoQuant Module Mapping

Existing and planned AutoQuant reporting systems should map into artifact-generating modules rather than app-specific report builders.

### EDA Report

Potential artifacts:

- data description table
- univariate stats table
- univariate plots
- correlation matrix
- high correlation tables
- trend plots
- drift diagnostics
- leakage/risk flags
- narrative text artifacts later

### Target Analysis

Potential artifacts:

- target distribution table
- target distribution plot
- target association plots
- target trend plots
- target drift plots
- target risk flags

### Model Assessment

Potential artifacts:

- model metrics table
- ROC / PR plots
- confusion matrix
- calibration plots
- lift/gains
- residual diagnostics

### Model Insights

Potential artifacts:

- variable importance
- partial dependence
- feature effects
- model comparison
- interpretation notes

### SHAP Analysis

Potential artifacts:

- SHAP importance
- SHAP dependence
- SHAP summary
- feature contribution tables
- narrative explanations

### CatBoost Builder

Potential artifacts:

- model training config
- validation metrics
- fitted model metadata
- assessment artifacts
- model insights artifacts
- SHAP artifacts where supported

CatBoost Builder may orchestrate model fitting and then call assessment or insight modules, but it should still return standard artifacts through `service_result`.

## Separation From Display Layer

Modules can recommend:

- section names
- artifact labels
- suggested order

The Display/Layout pages own:

- final artifact selection
- visibility
- section assignment
- layout mode
- export

This keeps report composition stable even as new analytical systems are added. A Forecasting, EDA, or CatBoost module should never need its own final report page, export implementation, or project persistence model.

## GenAI Hooks

Future GenAI can:

- suggest module configs
- explain module outputs
- generate narratives
- propose which module artifacts to add to a report
- propose layout/sections

GenAI must use the proposal/action system and permissions/policy gates. It should not directly mutate artifact state, project state, exports, layout state, or module configs without an accepted action.

Potential hooks:

- `suggest_config`
- `explain_artifact`
- `draft_narrative`
- `recommend_artifacts`
- `recommend_layout`

All hooks should return structured proposals or `service_result` objects that can be validated before use.

## Implementation Phases

### Phase A

- module registry skeleton
- module result contract
- EDA module wrapper around existing AutoQuant EDA outputs

### Phase B

- Target Analysis module
- Model Assessment module

### Phase C

- Model Insights module
- SHAP Analysis module

### Phase D

- CatBoost Builder module

### Phase E

- GenAI-assisted module configuration and report generation

Each phase should preserve the artifact model, page-module boundaries, and display/report separation.

## Anti-Patterns

Avoid:

- module-specific report builders
- module-specific export systems
- module-specific artifact state
- direct layout mutation
- direct raw Shiny observers outside page/module boundaries
- ad hoc table/plot rendering
- arbitrary `eval`
- bypassing `service_result`
- bypassing `create_artifact()`
- storing fragile runtime-only objects when config/code/metadata can support rebuild or repair

When a module appears to need special layout, export, or persistence logic, first ask whether the artifact model, display layer, or service contract should be extended instead.
