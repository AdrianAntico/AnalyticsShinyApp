# Repository Contracts

## AnalyticsShinyApp

AnalyticsShinyApp is the central product and coordination repo.

It owns:

- Shiny app shell and page modules
- local-first product state
- Artifact Library
- report plans
- layout/display composition
- project save/load and bundles
- app exports
- Workflow page
- Analysis Modules page
- Code Runner UI/history/output-to-artifact flow
- app-side adapters for AutoQuant, Rodeo, PolarsFE, and future modules

It must not:

- modify AutoPlots internals
- call echarts4r directly
- source internal AutoQuant or AutoPlots files
- reimplement analytics owned by AutoQuant
- create a second code execution system
- own Electron packaging/runtime behavior

## AutoQuant

AutoQuant owns analytics, artifact generation, and standalone analytical report rendering.

It owns:

- EDA artifact generators
- Model Readiness / target diagnostics generators
- post-model Model Assessment generators
- Regression and Binary Model Insights generators
- Regression and Binary SHAP artifact generators
- CatBoost Builder training/scoring artifact generator
- analytical report Rmd/static HTML rendering
- package-level QA for analytical outputs

It must not:

- mutate AnalyticsShinyApp state directly
- own app layout/report composition
- run app exports
- depend on Shiny page state

## AutoPlots

AutoPlots owns plotting and display primitives.

It owns:

- high-level plot functions
- themes
- axis/tooltip/display defaults
- display helpers such as grid/section/carousel-style plot display
- widget sizing/display helper behavior

It must not:

- own AutoQuant analytical decisions
- own app workflow state
- become a report-planning system

## Rodeo

Rodeo owns R feature engineering and model prep.

It owns:

- R/data.table/collapse feature engineering plans
- fitted specs
- transform/apply contracts
- model prep partition/fold contracts
- R-side feature engineering/model prep artifacts

It must not:

- own app UI
- own Python feature engineering
- own benchmark result interpretation as product truth

## PolarsFE

PolarsFE owns Python/Polars feature engineering and model prep.

It owns:

- Polars feature plans
- fitted specs
- transform/apply contracts
- Python-side model prep
- manifests and diagnostics

It must not:

- own R feature engineering
- own app UI
- run large benchmarks without Benchmarks guardrails

## Benchmarks

Benchmarks owns performance evidence.

It owns:

- smoke, moderate, focused, and large benchmark harnesses
- benchmark safety guardrails
- output summaries
- decision reports
- performance recommendations

It must not:

- change production package APIs as part of benchmark scripts
- commit heavy outputs
- run Spark or large Python jobs unless explicitly enabled and guarded

## shinyelectron

shinyelectron owns packaging and runtime.

It owns:

- Electron shell
- R/Shiny process launch
- local server lifecycle
- dependency installation/source handling
- packaged runtime smoke tests

It must not:

- change Shiny app behavior
- install AutoPlots or AutoQuant from CRAN when local/source overrides are configured
- own app analytics or artifact state

## Cross-Repo Contract

Cross-repo work should move in this order:

1. Define or update upstream package contract.
2. Add package-level QA.
3. Add AnalyticsShinyApp adapter.
4. Add app-level QA.
5. Update shinyelectron only when runtime/dependency behavior changes.
6. Update Benchmarks only when performance evidence is needed.

Avoid circular ownership. If two repos need the same concept, define the source of truth and let the other repo adapt to it.
