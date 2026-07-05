# Electron Smoke Test Results

Checkpoint run: 2026-07-04T20:05:49-07:00

## Scope

This checkpoint verifies the Analytics Shiny App after Code Runner, Code History, rerun/duplicate, and output-to-artifact work. The Electron wrapper used for this run is the local fork at:

`C:/Users/Bizon/Documents/GitHub/shinyelectron`

The smoke test focused on command-line launch/build verification and app-side QA. Full manual click-through inside the Electron window remains a follow-up checkpoint.

## Dependency Source Checkpoint

Checkpoint run: 2026-07-04T22:12:17-07:00

Status: **Pass**

This checkpoint verified the shinyelectron dependency-source fix for AnalyticsShinyApp using the local fork at:

`C:/Users/Bizon/Documents/GitHub/shinyelectron`

Dependency source handling added in shinyelectron:

- Explicit Local, GitHub, URL, and CRAN package source handling.
- Source precedence and install ordering for configured package sources.
- Local/GitHub/URL packages are not installed by CRAN package name.
- URL package installs support `install.packages(url, repos = NULL, type = "source", INSTALL_opts = ...)`.
- Post-install validation now checks `requireNamespace()`, `packageVersion()`, and `find.package()`.
- AutoPlots validation also checks `Line`, `Bar`, and `CorrMatrix`.
- AutoQuant validation also checks the implemented analysis artifact generator exports.
- Package installs that emit warnings or verbose output are accepted when post-install validation passes.

AnalyticsShinyApp Electron package source configuration:

| Package | Source | Location / Notes |
| --- | --- | --- |
| AutoPlots | Local | `C:/Users/Bizon/Documents/GitHub/AutoPlots` |
| AutoQuant | Local | `C:/Users/Bizon/Documents/GitHub/AutoQuant` |
| catboost | URL | `https://github.com/catboost/catboost/releases/download/v1.2/catboost-R-Windows-1.2.tgz` |
| Rodeo | GitHub | `AdrianAntico/Rodeo` |
| Ordinary CRAN dependencies | CRAN | Installed only when not source-overridden. |

Verification evidence:

- No CRAN install was attempted for AutoPlots.
- No CRAN install was attempted for AutoQuant.
- AutoPlots installed from the local path and validated successfully.
- AutoQuant installed from the local path and validated successfully.
- catboost URL package handling was present in the generated manifest.
- Electron launched the generated app and reached `server_ready`.
- Final log evidence: `Server ready on port 3838`.

## Focused Electron / Manual App Checkpoint

Checkpoint run: 2026-07-04T22:55:00-07:00

Status: **Partial pass**

This checkpoint verified the current AnalyticsShinyApp build after shinyelectron dependency-source handling, Code Runner, and AutoQuant module adapter work.

Revisions and package context:

| Component | Revision / Version | Path / Notes |
| --- | --- | --- |
| AnalyticsShinyApp | `e69bddf Configure Electron package sources` | `C:/Users/Bizon/Documents/GitHub/AnalyticsShinyApp` |
| shinyelectron | `f2fa3fe Add explicit R package source handling` | `C:/Users/Bizon/Documents/GitHub/shinyelectron` |
| AutoPlots | `1.5.0` | `C:/Users/Bizon/AppData/Local/R/win-library/4.5/AutoPlots` |
| AutoQuant | `1.0.1` | `C:/Users/Bizon/AppData/Local/R/win-library/4.5/AutoQuant` |

Dependency/source result:

- Generated Electron manifest included 11 R packages.
- AutoPlots was configured as Local: `C:/Users/Bizon/Documents/GitHub/AutoPlots`.
- AutoQuant was configured as Local: `C:/Users/Bizon/Documents/GitHub/AutoQuant`.
- catboost was configured as URL package: `https://github.com/catboost/catboost/releases/download/v1.2/catboost-R-Windows-1.2.tgz`.
- Rodeo was configured as GitHub: `AdrianAntico/Rodeo`.
- Ordinary dependencies remained CRAN-managed when not source-overridden.
- No CRAN package-name install was attempted for AutoPlots or AutoQuant in the successful dependency-source run.
- Electron served the app on `127.0.0.1:3838`; HTTP GET returned 200.

Pre-checks:

| Check | Status | Notes |
| --- | --- | --- |
| `source("app.R", local = new.env())` | Pass | Sourced successfully. |
| AutoQuant critical exports | Pass | EDA, Model Assessment, Regression Model Insights, and Binary Model Insights artifact generators exist. |
| AutoPlots critical exports | Pass | `Line`, `Bar`, and `CorrMatrix` exist. |
| No nested `R/` directories | Pass | `Get-ChildItem R -Directory -Recurse` returned no directories. |
| No DT usage | Pass | No `DT`, `DT::`, `library(DT)`, or `require(DT)` matches in app code. |
| `git diff --check` | Pass | Passed with no whitespace errors. |

App-side QA results:

| Area | Status | Notes |
| --- | --- | --- |
| Analysis modules aggregate QA | Pass | EDA, Model Assessment, Regression Model Insights, and Binary Model Insights all returned success. |
| Code Runner model QA | Pass | Summary includes successful code run record. |
| Code Runner UI state QA | Pass | Request validation, record add, summary rows, and local trusted service checks passed. |
| Code Runner local trusted QA | Pass | Success value, warning capture, error capture, blocked function, and table artifact candidate passed. |
| Code Runner history QA | Pass | Duplicate, rerun, parent run ID, immutable original, notes, and failed rerun preservation passed. |
| Artifact model QA | Pass | Plot, text, and table artifacts summarized correctly. |
| Module registry QA | Pass | Implemented and planned modules summarized. |
| Report plan workflow QA | Pass with warning case | Valid plan ready, missing-artifact plan warning, duplicate/edit/apply success, duplicate ID repair ready. |
| Table framework QA | Pass | Reactable rendering, CSV export, and XLSX export passed after adding `openxlsx` to app Imports. |
| Export service QA | Pass | Expected service-result statuses for missing report/code, code export, and invalid filename. |

Electron UI / manual click-through:

| Check | Status | Notes |
| --- | --- | --- |
| Electron fixture build | Pass | Built `C:/Users/Bizon/AppData/Local/Temp/aq_electron_manual_checkpoint/electron-app`. |
| Electron process launch | Pass | Electron, Node, and Rscript processes started. |
| Shiny backend port | Pass | `127.0.0.1:3838` was listening. |
| App HTTP load | Pass | `Invoke-WebRequest http://127.0.0.1:3838` returned 200 and Shiny HTML. |
| Browser/UI click-through | Blocked | The in-app browser connector failed with a sandbox metadata error, and no local Playwright/Puppeteer runtime was available in the generated Electron project. |

Failure classification:

| Failure / Limitation | Classification | Notes |
| --- | --- | --- |
| Browser automation unavailable for manual UI clicks | Local environment / browser tooling | Electron app served Shiny successfully, but the available browser connector failed before interaction. |
| XLSX table export QA warning | Resolved | `openxlsx 4.2.8.1` is available in the app R context; direct `export_table_xlsx()` and `qa_table_framework()` XLSX export passed. |

Follow-up tasks:

1. Run a true visual/manual Electron click-through with a working browser automation surface or direct human interaction.
2. Repeat UI workflows once browser automation is available:
   - Data upload and preview.
   - Plot, text, table, and code-created artifacts.
   - Artifact Library previews and metadata edits.
   - Layout Grid/Sections and report plan apply.
   - Code Runner disabled-by-default, local_trusted runs, duplicate/rerun/history.
   - HTML/R code/export all and project/bundle save/load.
   - Light/Dark/Pimp theme readability.

## Revisions

| Component | Revision / Version | Notes |
| --- | --- | --- |
| AnalyticsShinyApp | `ea285ac shell/wiring` | Worktree already had in-progress app changes before this checkpoint. |
| shinyelectron | `4eff9c0 Update README` | Local branch `codex/github-local-package-support`; patched during this checkpoint. |
| AutoPlots | `1.5.0` | Loaded as an installed package. |
| AutoQuant | `1.0.1` | Loaded as an installed package. |
| R | `4.5.2` | `C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe` |
| Node.js | `24.18.0` | shinyelectron-managed cache. |
| npm | `11.16.0` | shinyelectron-managed cache. |

## Summary

Status: **Partial pass**

The AnalyticsShinyApp app-side checks passed, and shinyelectron successfully exported and built a temporary Windows Electron project after a wrapper-side PATH fix. The generated Electron project produced:

`C:/Users/Bizon/AppData/Local/Temp/aq_electron_export_build/electron-app/dist/analyticsshinyapp Setup 1.0.0.exe`

Electron launch was initiated with `run_after = TRUE`; the command ran until the smoke-test timeout and created live Electron processes. A follow-up process check found no remaining Electron/Rscript smoke-test processes, so no obvious orphaned backend remained.

## Wrapper Fix Applied

Failure before fix:

- `npm install` ran from the shinyelectron-managed `npm.cmd`.
- npm lifecycle scripts then called bare `node`.
- Because the managed Node directory was not added to `PATH`, child commands failed with: `'node' is not recognized as an internal or external command`.

Fix location:

- `C:/Users/Bizon/Documents/GitHub/shinyelectron/R/env.R`
- `C:/Users/Bizon/Documents/GitHub/shinyelectron/R/build-steps.R`
- `C:/Users/Bizon/Documents/GitHub/shinyelectron/R/run.R`

Fix summary:

- Added `get_node_npm_env()`.
- Passed that environment to npm install, npm build scripts, and the Electron dev launcher.
- This keeps the fix in the Electron wrapper repo, not AnalyticsShinyApp.

Classification: **Electron wrapper/toolchain issue**

## Checklist

| Area | Status | Evidence / Notes |
| --- | --- | --- |
| App sources from repo | Pass | `source('app.R')` succeeded. |
| R/ remains flat | Pass | No nested directories under `R/`. |
| DT usage | Pass | No DT package calls found in app code. |
| shinyelectron local load | Pass | `pkgload::load_all('C:/Users/Bizon/Documents/GitHub/shinyelectron')` succeeded using temp `cli 3.6.6`. |
| Electron export, build false | Pass | Exported staged Shiny app and detected 9 R dependencies. |
| Electron export, build true | Pass after wrapper fix | Created `electron-app`, installed npm dependencies, and produced Windows installer. |
| Electron launch | Partial pass | Launch initiated and ran until timeout; no obvious orphaned smoke-test process remained afterward. |
| App close cleanup | Partial pass | Timeout ended the smoke run; follow-up process scan did not show remaining matching Electron/Rscript processes. |
| Full Electron UI navigation | Not run | Needs manual or browser-automation checkpoint against the Electron window. |
| Code Runner QA | Pass | `qa_code_runner_history_workflow()`, `qa_code_runner_local_trusted()`, `qa_code_runner_model()`, and `qa_code_runner_ui_state()` returned success rows. |
| Analysis module QA | Partial pass | EDA, Model Assessment, and Regression Model Insights passed. Binary Model Insights returned a clear warning because `AutoQuant::generate_binary_classification_model_insights_artifacts()` is not available in installed AutoQuant. |
| git diff check, app | Pass | `git diff --check` passed with line-ending warnings only. |
| git diff check, wrapper | Pass | `git diff --check` passed with line-ending warnings only. |

## App-Side QA Results

Code Runner:

- Duplicate selected run: pass.
- Rerun creates new run ID: pass.
- `parent_run_id` preserved: pass.
- Original run unchanged: pass.
- Failed rerun preserved: pass.
- Local trusted execution captures success, warning, error, blocked function, and table artifact candidate: pass.
- Code Runner model/UI state QA: pass.

Analysis modules:

| Module | Status | Notes |
| --- | --- | --- |
| `autoquant_eda` | Success | 28 artifacts, 3 report plans. |
| `autoquant_model_assessment` | Success | 73 artifacts, 3 report plans. |
| `autoquant_regression_model_insights` | Success | 79 artifacts, 4 report plans. |
| `autoquant_binary_model_insights` | Warning | Installed AutoQuant does not expose `generate_binary_classification_model_insights_artifacts()`. |

## Dependency Detection

shinyelectron detected these R dependencies for the app:

- AutoPlots
- AutoQuant
- data.table
- digest
- htmltools
- htmlwidgets
- openxlsx
- reactable
- shiny

Warnings:

- Posit Package Manager sysreq lookup returned HTTP 500 for Ubuntu and Red Hat metadata. This did not block the Windows system-R Electron build.
- The user-library `cli` package was locked at `3.6.5`, so this checkpoint used a temporary R library containing `cli 3.6.6` for shinyelectron loading.

## Failure Classification

| Step | Expected | Actual | Browser Shiny reproduction? | Electron-only? | Likely fix repo |
| --- | --- | --- | --- | --- | --- |
| Initial wrapper load | Local shinyelectron loads | Blocked by missing R deps, then by `cli >= 3.6.6` | No | Yes | Local environment / shinyelectron dependency setup |
| First build | npm install succeeds | npm lifecycle scripts could not find `node` | No | Yes | shinyelectron |
| Binary Model Insights QA | Adapter can run if AutoQuant generator exists | Warning: generator not available in installed AutoQuant | N/A | No | AutoQuant installation/version |

## Follow-Up Tasks

1. Commit or otherwise preserve the shinyelectron PATH fix.
2. Install/update `cli >= 3.6.6` in the normal user R library when the locked DLL is released.
3. Run a full manual Electron click-through:
   - Data upload.
   - Plot/Text/Table artifacts.
   - Artifact Library preview/edit/hide/show/remove.
   - Layout Grid and Sections.
   - Report Plans preview/apply/edit.
   - Code Runner disabled-by-default and local_trusted workflows.
   - HTML/R code/export all.
   - Project save/load and bundle save/load.
   - Light, Dark, and Pimp themes.
4. Update installed AutoQuant when `generate_binary_classification_model_insights_artifacts()` is available, then rerun Binary Model Insights QA.
