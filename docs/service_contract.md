# Analytics Shiny App Service Contract

## Problem Statement

Quantico became difficult to maintain because each service, module, and workflow managed edge cases differently. Validation, runtime failures, UI messages, generated code, and downstream artifacts were often handled locally inside each feature. Over time, that made the codebase hard to reason about and made new edge cases expensive to support.

Analytics Shiny App should avoid that path by using a standard service contract. Every major capability should expose a predictable interface, return a standard result object, and keep business logic out of Shiny UI code.

## Core Principle

Every module should:

- validate inputs
- execute bounded logic
- return a standard result object
- never leak raw errors directly into the app UI

Services should absorb low-level failures, translate them into structured errors and messages, and return enough diagnostics for debugging without forcing the UI to understand internal implementation details.

## Standard Result Object

All services should return a named list with the same top-level fields:

```r
list(
  status = "success",
  value = NULL,
  artifacts = list(),
  messages = character(),
  warnings = character(),
  errors = character(),
  diagnostics = list(),
  code = character(),
  metadata = list()
)
```

Field definitions:

- `status`: One of `success`, `warning`, `error`, or `needs_input`.
- `value`: The primary return value, such as a prepared config, model object, report object, or plot object.
- `artifacts`: Renderable outputs or files created by the service, such as widgets, tables, paths, reports, or downloadable assets.
- `messages`: User-facing informational messages.
- `warnings`: User-facing warnings that do not prevent partial success.
- `errors`: User-facing errors that explain why the service could not complete.
- `diagnostics`: Developer-facing details for logs, debugging, validation traces, timing, package versions, or caught conditions.
- `code`: Generated reproducible R code, when relevant.
- `metadata`: Structured context such as plot names, source data paths, schema summaries, model metrics, service version, or status flags.

Services may add nested fields inside `artifacts`, `diagnostics`, or `metadata`, but should not add ad hoc top-level fields unless the service contract is updated.

## Error Taxonomy

Services should use stable error codes so the UI, logs, tests, and future GenAI workflows can reason about failures consistently.

Common error codes:

- `DATA_MISSING`: Required data is unavailable.
- `COLUMN_MISSING`: Required column names are absent from the current data.
- `COLUMN_TYPE_INVALID`: A column exists but has an unsupported type.
- `CONFIG_INVALID`: A saved or generated configuration is malformed.
- `OPTION_INVALID`: A selected option is invalid for the requested service or plot type.
- `PLOT_NOT_SUPPORTED`: The requested plot type is not supported by the app registry or AutoPlots.
- `EXPORT_PATH_INVALID`: Export path is missing, inaccessible, or cannot be created.
- `PROJECT_VERSION_MISMATCH`: A project file was created by a different app version.
- `PROJECT_DATA_MISSING`: A project loaded, but its source data could not be found.
- `GENAI_JSON_INVALID`: GenAI output could not be parsed as valid JSON.
- `GENAI_SCHEMA_INVALID`: GenAI output parsed but did not match the expected schema.
- `RUNTIME_ERROR`: A caught runtime failure that does not fit a more specific category.

Recommended structured error shape:

```r
list(
  code = "COLUMN_MISSING",
  message = "Required column is missing: Revenue",
  field = "YVar",
  details = list(column = "Revenue", plot_name = "p1")
)
```

## Service Examples

### `plot_service`

Responsibilities:

- validate plot type, mappings, options, and data compatibility
- build AutoPlots calls using high-level AutoPlots functions only
- return plot widgets and generated R code
- mark plots as `Ready`, `Needs data`, `Missing columns`, or `Rebuild failed`

Inputs:

- data
- plot config
- plot registry
- option registry

Returns:

- `value`: plot object or validated plot config
- `artifacts$plot`: renderable AutoPlots widget
- `code`: reproducible `AutoPlots::<PlotType>()` call
- `metadata`: plot name, plot type, mappings, status

### `project_service`

Responsibilities:

- save and load project `.rds` files
- save and load portable project bundles
- validate project structure
- repair safe stale metadata
- rebuild plot objects from configs when data is available

Inputs:

- project path or bundle directory
- current app state
- current data path

Returns:

- `value`: repaired project state
- `artifacts$project_path`
- `artifacts$bundle_dir`
- `messages`: load/save success messages
- `warnings`: version mismatch, missing data, repaired metadata
- `metadata`: app version, saved time, data path, plot statuses

### `export_service`

Responsibilities:

- validate export paths
- save HTML using `AutoPlots::save_widget()`
- write reproducible R code files
- eventually save PNG when that feature is added

Inputs:

- report object
- generated report code
- export directory
- export name

Returns:

- `artifacts$html_path`
- `artifacts$code_path`
- `messages`: export success messages
- `errors`: path or runtime failures

### `genai_service`

Responsibilities:

- accept natural-language instructions
- request or parse GenAI responses
- validate JSON
- validate against app schemas
- return proposed plot configs, layout configs, or analysis plans

Inputs:

- user prompt
- data schema summary
- allowed plot registry
- allowed option registry

Returns:

- `value`: validated structured proposal
- `warnings`: assumptions or unsupported requests
- `errors`: JSON/schema failures
- `diagnostics`: raw response, parse attempts, schema validation details

### `eda_service`

Responsibilities:

- summarize data
- infer column types
- report missingness, cardinality, distributions, correlations, and candidate mappings
- return report artifacts without mutating app state

Inputs:

- data
- selected columns
- EDA options

Returns:

- `artifacts$tables`
- `artifacts$plots`
- `code`: reproducible EDA code
- `metadata`: schema, column roles, warnings

### `modeling_service`

Responsibilities:

- validate target, predictors, model family, train/test settings, and metrics
- fit models
- produce performance reports and reproducible code

Inputs:

- data
- modeling config
- validation policy

Returns:

- `value`: model object or model summary
- `artifacts$plots`
- `artifacts$tables`
- `code`: reproducible modeling code
- `metadata`: metrics, feature roles, split details

### `forecasting_service`

Responsibilities:

- validate time column, target column, frequency, horizon, and grouping
- fit forecasting workflows
- return forecast tables, plots, diagnostics, and code

Inputs:

- data
- forecasting config
- horizon and grouping settings

Returns:

- `value`: forecast object or forecast table
- `artifacts$forecast_plot`
- `artifacts$diagnostics`
- `code`: reproducible forecast code
- `metadata`: time range, horizon, model family, accuracy metrics

## Shiny Integration Rule

The UI should not contain deep business logic.

The UI should:

- collect inputs
- call services
- display standard result messages
- render returned artifacts

Shiny observers and render functions should be thin orchestration layers. They may coordinate state, but they should not contain complex validation, data prep, export logic, model fitting, prompt parsing, or plot-building logic directly.

## Module Boundary Rule

Analytics modules should return report artifacts, not mutate app state directly.

Modules should not directly modify global `reactiveValues`, saved plot lists, project state, export state, or layout state. Instead, they should return a standard result object. The app shell decides how to merge accepted results into app state.

This boundary makes modules easier to test and prevents hidden cross-module coupling.

## Future Refactor Path

Recommended first files use flat `R/` paths with filename prefixes. Do not create subdirectories inside `R/`.

```text
R/service_result.R
R/validators.R
R/service_plot.R
R/service_project.R
R/service_export.R
R/service_genai.R
R/registry_plots.R
R/registry_options.R
R/project_state.R
R/project_bundle.R
R/utils_paths.R
R/utils_messages.R
```

Suggested sequence:

1. Add `service_result.R` with constructors such as `service_success()`, `service_warning()`, `service_error()`, and `service_needs_input()`.
2. Add `validators.R` for shared data, column, config, path, and project validators.
3. Move plot config validation and AutoPlots build calls into `service_plot.R`.
4. Move project save/load/repair/bundle logic into `service_project.R`.
5. Move HTML and R code export logic into `service_export.R`.
6. Introduce `service_genai.R` only after plot/project/export services have stable schemas.

The app should keep working throughout the refactor. Move one workflow at a time, preserve generated AutoPlots code, and keep service behavior covered by focused smoke tests.
