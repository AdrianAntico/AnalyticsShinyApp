# Package Architecture

Analytics Workstation now has two identities:

- Product display name: **Analytics Workstation**
- R package name: **AnalyticsShinyApp**
- Product release: **1.0.0-buildweek**
- R package version: **1.0.0**

The package exposes a deliberately small supported API:

- `run_workstation()`
- `launch_workstation()`
- `workstation_diagnostics()`
- `workstation_installation_info()`
- `qa_package_distribution()`
- `qa_electron_distribution()`

## Immutable and Writable State

Installed R package directories may be read-only. Runtime state must not be written into the package library.

Immutable resources live in the package:

- `R/`
- `inst/electron/`
- `inst/app/www/`
- `inst/app/config/`
- `inst/app/data/`

Writable user state lives under:

```text
%LOCALAPPDATA%\AnalyticsWorkstation
```

The canonical path helpers are in:

```text
R/installation_paths.R
```

Application code should use these helpers instead of inventing new writable locations.

## Installed Package Model

The Windows installer installs the R package and launches from the installed namespace:

```r
AnalyticsShinyApp::run_workstation()
```

Shortcuts do not point to the developer checkout or to a copied repository source tree. This means the repository can move or be deleted after installation without breaking Start Menu launch.

## Supported Launch Paths

`run_workstation()` runs the app in the current R session.

`launch_workstation()` prefers the installed launcher when present and falls back to `run_workstation()` when it is not installed.

The installer also creates:

```text
Analytics Workstation.cmd
Analytics Workstation Electron.cmd
```

The first opens through R/Shiny in the browser. The second starts the Electron shell when Node dependencies are available.

## Invariants

- User projects are never stored inside the package installation.
- Shortcuts must not point to a temporary repository checkout.
- Application UI/config/demo resources must resolve through installed package resources.
- Missing optional desktop dependencies should produce diagnostics, not startup crashes.
- Secrets and API keys must not be written to installation logs.
- Electron owns only the R process it starts and must not kill unrelated R processes.
