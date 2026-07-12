# Analytics Shiny App

Analytics Shiny App is a local-first Shiny visualization builder powered by AutoPlots.

It lets users load data, build AutoPlots charts, save plots, organize report layouts, export HTML/R code, and save or load local project bundles.

AutoPlots is the rendering engine. This app owns the Shiny product layer and calls exported AutoPlots functions; it does not own or modify AutoPlots plotting internals.

## Repository Boundary

This repository owns the app/product layer:

- Shiny app logic
- AutoPlots calls
- plot registries and options
- project state
- export behavior
- generated report code
- UI behavior inside the Shiny app

The AutoPlots package remains an external dependency. AutoPlots plotting internals should not be copied into this repository.

## Ecosystem Operating Model

AnalyticsShinyApp is the central product and coordination repo for the local-first analytics report builder ecosystem.

Start with these docs before architecture-affecting work:

- `docs/architecture_constitution.md`: product principles, boundary rules, QA expectations, and deferred scope.
- `docs/ecosystem_operating_model.md`: single-developer operating loop, workflow lifecycle, artifact flow, and Code Runner rules.
- `docs/repo_contracts.md`: ownership boundaries for AnalyticsShinyApp, AutoQuant, AutoPlots, Rodeo, PolarsFE, Benchmarks, and shinyelectron.
- `docs/project_artifact_collector.md`: project-level artifact aggregation contract, bundle lifecycle, manifest, screenshot policy, and DOCX collector workflow.
- `docs/render_target_architecture.md`: explicit human vs LLM render target policies and `ExportPNG` semantics.
- `docs/artifact_quality_policy.md`: shared artifact component expectations, completeness scoring, and graceful degradation rules.
- `docs/table_artifact_architecture.md`: canonical table artifacts, table render targets, sorting policies, previews, and backing data sidecars.
- `docs/api_surface_audit.md`: aggressive pre-product API/product surface audit and cleanup recommendations.
- `docs/agent_task_template.md`: recommended Codex task framing.

Core operating rules:

- AutoQuant owns analytics, artifact generators, and analytical report rendering.
- AutoPlots owns high-level plot functions, themes, and display helpers.
- The Project Artifact Collector owns project-level artifact aggregation and the primary project DOCX.
- Human reports and LLM collectors are independent render targets built from the same underlying artifacts.
- AnalyticsShinyApp owns the conservative deterministic Feature Engineering / Model Preparation workflow that creates visible prepared-data artifacts without mutating source data.
- Rodeo and PolarsFE remain future homes for richer R/Python feature engineering engines if they are integrated intentionally.
- Benchmarks owns performance evidence.
- shinyelectron owns packaging/runtime.
- Code Runner is the only custom code execution system.
- Workflow actions are user-triggered unless explicitly designed otherwise.

Workflow terminology:

- Model Readiness is pre-model Target Analysis: target diagnostics, leakage checks, drift, class balance, missingness, and readiness recommendations.
- Feature Engineering / Model Preparation creates reproducible prepared-data artifacts and transformation lineage before training.
- CatBoost Builder trains and scores models when the user runs it.
- Model Assessment is post-model evaluation of trained/scored output: RMSE, MAE, ROC, PR, lift, gains, calibration, residual diagnostics, and holdout performance.
- The preferred pre-model AutoQuant adapter id is `autoquant_model_readiness`; `autoquant_model_assessment` is a legacy compatibility alias only.

## Dependencies

Required R packages include:

- `AutoPlots`
- `shiny`
- `data.table`
- `htmltools`
- `htmlwidgets`
- `tools`

Install released dependencies in R:

```r
install.packages(c("shiny", "data.table", "htmltools", "htmlwidgets"))
```

Install `AutoPlots` separately before running this app. If you use a GitHub-hosted AutoPlots build:

```r
install.packages("remotes")
remotes::install_github("AdrianAntico/AutoPlots")
```

During local AutoPlots development, point your R library at a local AutoPlots install instead of adding dev-only loading to this app:

```r
remotes::install_local("../AutoPlots")
```

Production app code should load AutoPlots with:

```r
library(AutoPlots)
```

Do not add `devtools::load_all("../AutoPlots")` or source internal AutoPlots files in this repository.

## Run Locally

From this repository root:

```r
shiny::runApp(".")
```

Or from a terminal:

```powershell
Rscript -e "shiny::runApp('.')"
```

The app performs a lightweight startup dependency check through `check_app_dependencies()` before loading the Shiny UI.

## Table Filters

Reactable-backed table artifacts support text exclusion filters:

- `Impressions` keeps rows containing `Impressions`
- `!Impressions` excludes rows containing `Impressions`
- `-Impressions` also excludes rows containing `Impressions`

Text filtering is case-insensitive. Numeric and date columns keep their standard table behavior.

## Sample Data

Sample QA data is available at:

- `inst/sample_data/app_qa_transactional.csv`

It includes `Date`, `Channel`, `Category`, `Spend`, `Revenue`, `Clicks`, `XNum`, `YNum`, and `ZVal`.

## Electron Wrapper

This app may be run inside an Electron shell maintained outside this repository.

Known Electron wrapper source:

- `AdrianAntico/<ELECTRON_FORK_REPO_NAME>`

The Electron wrapper repository owns Electron startup, R/Shiny process launch, desktop window behavior, packaging, local server lifecycle, and Electron-specific file/path behavior.

If a smoke test fails in both browser Shiny and Electron, fix this repository. If it fails only in Electron, inspect the Electron wrapper repository first.

See `docs/electron_smoke_test.md`.

## Smoke Test Checklist

Detailed smoke steps are in `docs/smoke_test.md`.

Basic Shiny app smoke:

- app launches from this repository
- upload `inst/sample_data/app_qa_transactional.csv`
- build Line plot
- add `p1`
- build Bar plot
- add `p2`
- preview Grid layout
- assign sections
- preview Sections layout
- export R code
- export HTML; when `AutoPlots::save_widget()` is unavailable, the app falls back to an HTML file plus asset directory
- save/load project `.rds`
- save/load project bundle

Generated code smoke:

- report code uses `AutoPlots::<PlotType>()`
- report code uses `AutoPlots::display_plots_grid()` or `AutoPlots::display_plots_sections()`
- bundle-loaded report code uses the bundled `data.csv` path

## Notes

This repository was copied out of the AutoPlots package repository so app/product code can evolve separately from the plotting package. Do not delete the old app copy from AutoPlots until this repository has passed the expected app and Electron smoke tests.
