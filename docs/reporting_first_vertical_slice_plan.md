# Reporting First Vertical Slice Plan

## Status

This is the implementation plan for the first reporting vertical slice. It intentionally stops before broad runtime implementation.

Phase 1 has established the semantic runtime foundation in `R/report_contract.R`. Later phases should consume that runtime rather than creating module-specific report schemas.

Phase 2 adds `build_regression_model_insights_report()` in `R/report_regression_model_insights.R`. It is an adapter only: Regression Model Insights module output goes in, a validated semantic `ReportContract` comes out.

## Selected Slice

Regression Model Insights.

## Why This Slice

Regression Model Insights is the best first reporting candidate because it is broad enough to test the real architecture and narrow enough to avoid a rewrite.

It includes model context, metrics, prediction diagnostics, residual diagnostics, feature effects, variable importance, tables, plots, warnings, recommendations, and existing app report plans.

It also already has a clear source-of-truth boundary: `AutoQuant::generate_regression_model_insights_artifacts()` generates analytical outputs, while the app adapts them into artifacts and report plans.

## Alternatives Considered

| Candidate | Reason Not First |
| --- | --- |
| EDA | Too broad and risks turning the first slice into a general dashboard/report builder. |
| SHAP | Valuable, but too specialized and likely to pull in advanced evidence-routing concerns. |
| Model Readiness | Important, but not rich enough to prove table, plot, diagnostic, and narrative composition together. |
| CatBoost Builder | Too close to training workflow and model object concerns. |

## Current Repository Evidence

Relevant existing files:

- `R/module_autoquant_regression_model_insights.R`
- `docs/autoquant_regression_model_insights_module.md`
- `R/report_plan_model.R`
- `R/page_layouts.R`
- `R/page_export.R`
- `R/service_export.R`
- `docs/report_plan_architecture.md`
- `docs/render_target_architecture.md`
- `docs/table_artifact_architecture.md`
- `docs/artifact_quality_policy.md`

The existing module documentation states that the app adapts AutoQuant outputs into artifacts and report plans and avoids calling the AutoQuant-native RMarkdown renderer as the primary app ingestion path. That makes this slice a natural bridge from report plans to `ReportContract`.

## Proposed New Files

Initial implementation should be small.

```text
R/report_contract.R
R/report_components.R
R/report_validation.R
R/report_presentation.R
R/report_renderer_registry.R
R/report_regression_model_insights.R

tests/testthat/test-report-contract.R
tests/testthat/test-report-validation.R
tests/testthat/test-report-regression-model-insights.R
tests/testthat/test-report-table-contract.R

tests/fixtures/reporting/regression_model_insights/
```

If the app test structure does not yet use `tests/testthat`, place QA helpers beside existing app QA conventions first, but keep names and responsibilities package-ready.

## Object Flow

```text
AutoQuant regression model insights generator
  -> module service_result
       -> canonical-ish regression insights output
            -> Artifact Service
                 create app artifacts and collector-ready bundles
            -> Report Service
                 create_regression_model_insights_report_contract()
                   -> validate_report_contract()
                   -> render_report(target = "workstation")
                   -> later render_report(target = "html")
```

The report slice must not recompute model metrics, residuals, effects, or diagnostics. It must consume the generated result or adapted module output.

## First Contract Scope

The first `ReportContract` should include:

- `contract_version`
- `schema_version`
- `report_id`
- `report_type = "regression_model_insights"`
- `title`
- `source_module`
- `source_run_id`
- `audience`
- `purpose`
- `mode`
- sections
- components
- findings
- recommendations
- diagnostics
- evidence links
- validation status
- provenance

## First Component Scope

Required components for the first slice:

- report title
- orientation
- executive summary
- metric summary
- at least one diagnostic table
- at least one visualization component
- residual diagnostics section
- feature effects or importance section when available
- recommendations
- methodology note
- evidence citation list

The implementation may skip a component when source data is unavailable, but the omission must be visible in validation metadata rather than silent.

## Table Requirements

At least one table component should exercise:

- table title
- purpose
- default sort
- priority columns
- compact report view
- full backing reference when available
- static fallback
- validation of required fields

Candidate first tables:

- model metrics
- residual diagnostic summary
- top-error table
- feature diagnostic table

## Presentation Requirements

Use `PresentationProfile` for appearance decisions.

Initial profiles:

- `workstation_dark`
- `workstation_light`
- `executive_compact`

The report contract should not contain theme colors or CSS. It may contain semantic presentation hints such as `importance = "critical"` or `density = "compact"`.

## Renderer Requirements

Next proof phase:

- Multi-service generalization across SHAP Analysis and EDA.

First renderer after generalization:

- Workstation renderer or app-native preview.

Second renderer:

- Static HTML fallback.

Do not begin DOCX, PDF, or PowerPoint until the contract has survived the first interactive and static renderers.

## QA Plan

Add deterministic QA for:

- contract construction
- required version fields
- missing title failure
- missing section warning or failure depending on severity
- invalid component type failure
- table component validation
- JSON serialization and restore
- renderer registry target lookup
- unsupported renderer rejection
- regression model insights adapter produces a valid contract
- SHAP Analysis adapter produces a valid contract
- EDA adapter produces a valid contract
- all adapters share validation, serialization, capability, and degradation semantics
- adapter does not call AutoQuant renderer/export functions
- empty or missing optional source components degrade gracefully
- app still sources
- reporting docs are discoverable in Knowledge Library

## Acceptance Criteria

The first slice is complete when:

- a Regression Model Insights report contract can be created from fixture/module output
- the contract validates deterministically
- the contract contains meaningful sections and components
- at least one table and one plot-like component are represented semantically
- unavailable optional components are recorded, not silently ignored
- an app/workstation renderer can display the report contract
- unsupported render targets fail gracefully
- no existing artifact, collector, layout, or export behavior regresses
- `source("app.R")` still succeeds
- relevant QA passes

## Migration Constraints

- Do not replace existing report plans in this slice.
- Do not remove Layout Studio.
- Do not remove Export.
- Do not call AutoQuant-native RMarkdown as the primary app report path.
- Do not create module-specific renderer logic that cannot be reused.
- Do not introduce Studio editing yet.
- Do not create a generic workflow engine.

## Implementation Phases

### Phase 1: Contract and Validation

Create constructors, validators, component definitions, and fixtures.

Stopping point: founder/developer review of a printed contract object and validation output.

### Phase 2: Regression Adapter

Create `create_regression_model_insights_report_contract()` from existing module output or a fixture that mirrors it.

Stopping point: validate contract without rendering.

Implementation note: the adapter name is `build_regression_model_insights_report()`. It consumes existing `service_result` output from the Regression Model Insights module and references its artifacts as evidence. If explicit artifact lineage is missing, the adapter records diagnostic components rather than fabricating evidence.

### Phase 3: Multi-Service Generalization

Create two more adapters before renderer work:

- `build_shap_analysis_report()`
- `build_eda_report()`

Stopping point: Regression Model Insights, SHAP Analysis, and EDA all validate and serialize through the same `ReportContract`.

Implementation note: this phase introduced `R/report_adapter_helpers.R` for shared artifact indexing, evidence links, table/visual descriptors, source-supplied findings, optional recommendations, and robust section finalization. No SHAP-specific or EDA-specific report model was needed.

### Phase 4: Interactive Report Browser

Render the contract in the app using existing workstation primitives and a component-renderer registry.

Implementation note: this phase adds `R/report_browser.R` and `R/page_report_browser.R`. The browser consumes validated `ReportContract` objects only. Regression, SHAP, and EDA appear in the browser because their adapters already produce the same contract shape, not because the renderer knows those service families.

Stopping point: Regression Model Insights, SHAP Analysis, and EDA contracts render in the same native browser without renderer changes.

### Phase 5: Static HTML Fallback

Render the same contract to static HTML and record degradation metadata.

Stopping point: compare Workstation and static HTML outputs.

### Phase 6: Next Renderer Decision

Choose DOCX, PDF, or PowerPoint based on actual usage and founder need.

## Recommended Next Prompt

Implement Phase 1 only: create the versioned `ReportContract`, component constructors, validation helpers, serialization round-trip, and deterministic QA. Do not build the Regression Model Insights renderer yet.
