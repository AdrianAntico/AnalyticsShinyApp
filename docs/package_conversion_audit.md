# Real R Package Conversion Audit

Analytics Workstation has been converted from a repository-launched Shiny application into an installable R package.

## Product Identity

- Product: Analytics Workstation
- R package: AnalyticsShinyApp
- Package version: 1.0.0
- Product release: 1.0.0-buildweek

## Supported User Contract

```r
install.packages("AnalyticsShinyApp_1.0.0.tar.gz", repos = NULL, type = "source")
library(AnalyticsShinyApp)
run_workstation()
```

The launch contract must work from arbitrary working directories after the developer repository is moved or deleted.

## Before

The development app was launched primarily by sourcing `app.R` from the repository. The Windows launcher also depended on a copied source tree under the per-user program directory. That made launch success dependent on filesystem layout and made it too easy for source-tree-only paths to leak into production behavior.

## After

The package now owns the runtime:

- immutable resources live under `inst/app`
- UI assets are served through the `aw-assets` Shiny resource path
- bundled config defaults and Build Week demo data are loaded through package resource helpers
- mutable runtime state lives under `%LOCALAPPDATA%\AnalyticsWorkstation`
- `run_workstation()` builds the Shiny app from the installed package namespace
- the Electron shell launches `AnalyticsShinyApp::run_workstation()` instead of sourcing repository files

## Public API

The supported package surface is intentionally small:

- `run_workstation()`
- `launch_workstation()`
- `workstation_diagnostics()`
- `workstation_installation_info()`
- `qa_package_distribution()`
- `qa_electron_distribution()`

Everything else remains internal implementation detail unless explicitly exported later.

## Installed Resource Layout

```text
AnalyticsShinyApp/
  R/
  app/
    www/
    config/
    data/
  electron/
```

The installed package resource root is discovered with `workstation_resource_path()`.

## Writable State

Writable state is never placed inside the installed package:

```text
%LOCALAPPDATA%\AnalyticsWorkstation
  config/
  data/
  exports/
  logs/
  projects/
  runtime/
```

The canonical helper is `workstation_user_path()`.

## Validation Performed

- `source("app.R")`
- `qa_package_distribution()`
- `R CMD build .`
- `R CMD check --no-manual AnalyticsShinyApp_1.0.0.tar.gz`
- installed-package smoke test from a temporary library
- app factory smoke test from an arbitrary temporary working directory
- installed `run_workstation()` localhost launch probe

`R CMD check` currently completes with tests passing and one NOTE from data.table-style nonstandard evaluation/global variable discovery. No package check errors or warnings remain.

## Release Artifacts

Release artifacts are written under `release/`:

- `AnalyticsShinyApp_1.0.0.tar.gz`
- `AnalyticsWorkstation-1.0.0-buildweek.zip`
- `ReleaseNotes.md`
- `SHA256.txt`

## Remaining Intentional Limitations

- The package is source-install oriented for Build Week.
- Electron packaging is still a lightweight shell around the installed R package rather than a fully signed native installer.
- The data.table global-variable NOTE is not a runtime failure and should be handled in a later cleanup pass if CRAN-style polish becomes a priority.
