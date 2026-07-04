# AutoQuant EDA Module

## Purpose

The AutoQuant EDA module is the reference implementation for analysis-module integration in Analytics Shiny App. AutoQuant owns EDA generation. Analytics Shiny App adapts AutoQuant outputs into standard artifacts and report plans.

## Ownership Boundary

`AutoQuant::generate_eda_artifacts()` is the source of truth for EDA logic. The app must not reimplement EDA calculations, plotting, diagnostics, or export logic from AutoQuant.

Analytics Shiny App owns:

- dependency checks
- user configuration collection
- config validation before calling AutoQuant
- `tryCatch` error handling around AutoQuant calls
- conversion of AutoQuant outputs into `aq_artifact` objects
- recommended report-plan creation
- Artifact Library storage
- Layouts page display and final composition
- project save/load of artifacts and plans

## Output Contract

The module returns a `service_result` with:

- `status`
- generated artifacts
- user-facing messages
- generated code skeleton
- run metadata
- recommended report plans in `metadata$report_plans`

Artifacts use:

- `source_module = "autoquant_eda"`
- stable run-scoped artifact IDs
- readable labels
- clean report sections
- `module_run_id` metadata
- run timestamp metadata
- selected variable metadata

## Report Plans

The adapter creates app-side report plans from generated artifacts:

- Recommended EDA Report: curated, balanced, suitable for first review
- Full EDA Report: all generated EDA artifacts grouped by section
- Diagnostics Only: correlation, trend, target, drift, and risk-oriented artifacts when present

Report plans reference artifact IDs only. They do not own artifacts and must not delete artifacts from the Artifact Library.

## Display Flow

1. User uploads data.
2. User configures and runs AutoQuant EDA.
3. AutoQuant generates EDA outputs.
4. The app converts outputs into artifacts.
5. The Artifact Library stores all artifacts.
6. The adapter creates recommended report plans.
7. The Layouts page previews and applies selected plans.
8. Users can edit plans without changing the underlying artifacts.

## QA Helper

`qa_autoquant_eda_integration()` runs the adapter against the sample transactional dataset when no data is supplied. It verifies:

- the module runs successfully
- artifacts are returned
- report plans are returned
- artifact labels are non-empty
- artifact sections are non-empty
- `artifact_summary()` works
- `report_plan_summary()` works

## Anti-Patterns

Avoid:

- reimplementing AutoQuant EDA calculations in this app
- creating EDA-specific artifact state
- creating EDA-specific export systems
- bypassing `service_result`
- bypassing `create_artifact()`
- directly mutating Layouts page state from the adapter
- using `DT` for the EDA integration
