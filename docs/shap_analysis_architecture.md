# SHAP Analysis Architecture

## Purpose And Scope

SHAP Analysis in the Analytics Shiny App is a prediction-surface analysis system, not a simple variable-importance add-on. It should explain how model predictions change across features, segments, time, interactions, and selected local rows.

Model Assessment answers whether a model is performing well. Model Insights explains broad model behavior through diagnostics such as importance, feature effects, and residual or threshold analysis. SHAP Analysis goes one level deeper: it explains the contribution structure behind predictions.

The first-class modules should be target/problem-type-specific:

- AutoQuant Regression SHAP Analysis
- AutoQuant Binary Classification SHAP Analysis

Multiclass SHAP Analysis is deferred. Three-way interactions are also deferred, but the model should reserve extension space for them.

## Problem-Type-Specific Modules

SHAP should not be implemented as one generic `shap_analysis` module. Regression and binary classification have different prediction scales, interpretation language, validation needs, report sections, and failure modes.

Proposed module IDs:

- `autoquant_regression_shap_analysis`
- `autoquant_binary_shap_analysis`
- `autoquant_multiclass_shap_analysis`, deferred

Proposed labels:

- AutoQuant Regression SHAP Analysis
- AutoQuant Binary Classification SHAP Analysis
- AutoQuant Multiclass SHAP Analysis, deferred

The current planned generic registry entry can remain as a placeholder until implementation begins, but the implementation direction should split the concrete adapters by problem type.

Regression SHAP explains movement in numeric response units or transformed prediction units. Binary SHAP explains movement in positive-class probability or logit space and must make the positive class explicit.

## User Inputs And Config Model

Each SHAP module should collect a bounded config object and pass it through validation before running. Config should be stored with generated artifacts and report plans so project save/load and reproducible code export remain possible.

Common inputs:

- active dataset
- target variable
- feature variables
- model object or model reference
- prediction function
- prediction type or prediction scale
- problem type
- selected features
- selected interaction pairs
- local row IDs
- sampling controls
- backend/options
- artifact options
- report plan options

Regression-specific inputs:

- target units label, if available
- prediction scale, such as response or transformed response
- residual column, if supplied or computed upstream

Binary-specific inputs:

- positive class
- prediction probability column or prediction function output
- probability versus logit scale
- optional threshold value
- optional calibration or class-balance context

Segment and time inputs:

- `DateVar`
- date aggregation: day, week, or month
- `ByVars`
- segment variables

`ByVars` are not passive grouping variables. They are segment lenses and interaction candidates used to compare how SHAP behavior changes across populations.

## Core Lens Architecture

The SHAP system should generate artifacts through a small set of analytical lenses. Each lens may produce plots, tables, text, diagnostics, and report-plan entries.

Global importance:

- rank features by average absolute SHAP magnitude
- support top-N controls
- include direction summaries where appropriate
- return importance plots and tables

Single-variable SHAP effects:

- show how one feature's SHAP contribution changes across its values
- include binned summaries for high-cardinality or noisy features
- support regression and binary-specific interpretation text

Interaction importance:

- rank feature pairs by estimated interaction strength
- include tables even when plots are too expensive or unstable
- bound pair counts to avoid combinatorial sprawl

Two-way interaction surfaces:

- show paired feature surfaces for selected or top-ranked pairs
- support heatmap, contour-like, or binned surface artifacts when available
- reserve metadata for future three-way extensions

By-variable and segment importance:

- compare global or feature-specific SHAP behavior across segments
- identify heterogeneity, rank changes, and segment-specific drivers
- include guardrails for sparse or high-cardinality segments

Over-time importance:

- summarize SHAP importance by day, week, or month
- highlight drift in feature contribution structure
- provide fallback messaging when `DateVar` is absent or invalid

By-variable over-time importance:

- cross `ByVars` with `DateVar` aggregations
- show segment-level contribution drift
- bound artifacts by top features, top segments, and date resolution

SHAP dependence:

- show feature value, SHAP value, target outcome, prediction, optional segment/color, and optional interaction feature
- distinguish dependence plots from simple importance plots

Local explanations:

- explain selected rows, top contributors, and prediction context
- optional in the first implementation
- return compact artifacts rather than large per-row reports by default

## SHAP Dependence Design

SHAP dependence artifacts should answer: "When this feature has this value, how does it contribute to the prediction, and what outcome or prediction context surrounds that contribution?"

A useful dependence view includes:

- feature value on the primary x-axis
- SHAP contribution on the y-axis
- target outcome or actual value when available
- model prediction or predicted probability
- optional segment/color from `ByVars`
- optional interaction feature
- binned summaries for dense data

This is different from global importance. Importance says which variables matter overall. Dependence says how a variable contributes across its observed range and whether that contribution differs by target behavior, prediction level, segment, or interaction.

For regression, dependence text should use response-unit language when the prediction scale supports it. For binary classification, dependence text should state whether the contribution is on probability or logit scale and always name the positive class.

## ByVars As Segment Lenses

`ByVars` should be treated as active analytical lenses. They are used to examine heterogeneity and interactions, not just to split charts mechanically.

ByVar outputs may include:

- segment-level global importance tables
- segment-level importance plots
- rank-change tables across segments
- single-feature contribution comparisons by segment
- SHAP dependence plots colored or faceted by segment
- segment diagnostics for sparse groups
- crossed segment/time contribution summaries

Guardrails:

- cap the number of `ByVars`
- cap displayed segment levels
- prefer top-N features and top-N segments
- collapse rare levels when safe
- warn when segment sample sizes are too small
- return diagnostic text/table artifacts instead of crashing

When `ByVars` and `DateVar` are both configured, the module may create by-variable over-time artifacts. These should be bounded and labeled clearly because they can multiply quickly.

## DateVar And Time Architecture

`DateVar` enables contribution-over-time analysis. The app should support day, week, and month aggregation.

Time outputs may include:

- global importance over time
- selected feature contribution over time
- feature rank over time
- prediction contribution drift
- segment-over-time SHAP summaries
- date parsing and missing-date diagnostics

Validation should check:

- `DateVar` exists
- values can be parsed as dates or datetimes
- aggregation is one of day, week, or month
- enough periods exist after aggregation
- enough rows exist per period for stable summaries

If `DateVar` is absent, invalid, or too sparse, the module should skip time artifacts and return a friendly diagnostic text or table artifact. It should not fail the whole module run unless time analysis is explicitly required.

## Artifact Model Contract

SHAP modules should return standard artifacts through `create_artifact()`. Outputs should become first-class artifacts wherever possible.

Artifact types:

- `plot` for AutoPlots-backed visual outputs
- `table` for importance, interaction, diagnostic, local, and segment summaries
- `text` for interpretation notes, caveats, and methodology
- `model_summary` where a compact model/context summary is useful

Recommended artifact metadata:

- `module_id`
- `module_run_id`
- `source_module`
- `source_package = "AutoQuant"`
- `source_function`
- `problem_type`
- `positive_class`, for binary classification
- `prediction_scale`
- `target_var`
- `feature_vars`
- `DateVar`
- `date_aggregation`
- `ByVars`
- `lens`
- `shap_backend`
- `original_name`
- `original_section`
- `normalized_section`
- `artifact_index`
- `created_by_module = TRUE`

Suggested artifact ID prefixes:

- Regression SHAP: `aq_rshap_`
- Binary SHAP: `aq_bshap_`
- Future multiclass SHAP: `aq_mshap_`

IDs should be run-scoped to avoid collisions across repeated runs.

Labels should be specific and readable. Avoid generic labels such as `unnamed`, `plot_1`, `table_1`, or `artifact`.

Recommended section names:

- SHAP Overview
- Global Importance
- Interaction Importance
- Single Feature Effects
- SHAP Dependence
- Segment Effects
- Time Effects
- Local Explanations
- Appendix

## Report Plan And Layout Integration

SHAP modules should return report plans in `metadata$report_plans`, following the existing AutoQuant adapter pattern.

Recommended plans:

- Recommended Regression SHAP Analysis Report
- Full Regression SHAP Analysis Report
- Interaction Diagnostics Report
- Segment And Time Effects Report, when segment/time artifacts exist
- Recommended Binary Classification SHAP Analysis Report
- Full Binary Classification SHAP Analysis Report
- Threshold Context SHAP Report, when binary threshold context is configured

Plans should reference artifact IDs only. They should not own artifacts, delete artifacts, or mutate the Artifact Library.

Display/Layout pages own:

- final artifact selection
- visibility
- section assignment
- ordering
- layout mode
- export

Users should be able to preview, apply, edit, reorder, duplicate, and archive SHAP report plans just like EDA and Model Insights plans.

## Computation And Backend Strategy

The app should not own SHAP computation details. Analytics Shiny App should validate configuration, call AutoQuant, normalize returned objects, and preserve metadata.

AutoQuant should own:

- model-agnostic prediction function handling
- background data selection
- SHAP backend selection
- prediction-scale handling
- sampling strategy
- seed/reproducibility handling
- feature and interaction computation
- diagnostic output

The app adapter should own:

- friendly config validation
- dependency availability checks
- service_result wrapping
- artifact normalization
- report plan creation
- project/export/display integration

Backend rules:

- keep the SHAP backend isolated behind an AutoQuant adapter
- do not overcommit the app to one SHAP package
- support row limits and sampling controls
- cache or reuse expensive intermediate outputs where AutoQuant supports it
- return warning/error artifacts for partial failures
- never throw raw backend errors into Shiny

Diagnostic tables should record:

- backend used
- prediction scale
- background row count
- explanation row count
- sampled feature count
- skipped features/pairs
- warnings
- computation time

## Regression-Specific Interpretation

Regression SHAP should explain contribution to numeric predictions.

Interpretation should include:

- response-scale contribution language when possible
- target units when supplied
- high-prediction and low-prediction driver summaries
- residual or actual-versus-predicted overlays when available
- feature effects connected to prediction magnitude
- contribution summaries by quantile or prediction band

Regression artifacts may include:

- global contribution importance
- high/low prediction driver table
- selected-feature dependence plots
- residual/context dependence plots
- contribution-over-time plots
- segment-level contribution rank changes
- local row explanation tables
- methodology and caveat text

## Binary-Specific Interpretation

Binary SHAP should make class context explicit.

Interpretation should include:

- positive class
- probability versus logit scale
- class probability context
- optional threshold-aware diagnostics
- class balance context
- calibration context where available
- high-risk and low-risk driver summaries

Binary artifacts may include:

- positive-class SHAP importance
- probability/logit scale caveat text
- high-score and low-score driver tables
- threshold-band contribution summaries
- SHAP dependence with actual class and predicted probability
- segment-level contribution differences
- time drift in positive-class contribution structure
- local selected-row explanations

Binary SHAP should not silently switch scales. If backend output is logit-scale but the UI labels it probability-scale, validation should fail or emit a clear warning artifact.

## Deferred Extensions

Deferred items:

- multiclass SHAP analysis
- three-way interactions
- causal analysis
- ICE/PDP comparison views
- local comparison groups
- deeper model registry integration
- persistent SHAP cache storage
- advanced interactive selection workflows

The artifact metadata should reserve space for:

- `class_label`
- `interaction_order`
- `comparison_group`
- `model_registry_id`
- `shap_cache_key`

This lets future modules expand without changing the core Artifact Library or Report Plan contracts.

## Implementation Phases

Phase 1: shared contracts and documentation.

- finalize SHAP config contract
- define artifact metadata and ID prefixes
- define report-plan section names
- add registry entries as planned stubs
- add QA contract helpers without real computation if useful

Phase 2: Regression SHAP Analysis.

- add AutoQuant generator support
- add app adapter
- normalize plot/table/text artifacts
- create recommended and full report plans
- add `qa_autoquant_regression_shap_analysis_integration()`

Phase 3: Binary Classification SHAP Analysis.

- add AutoQuant generator support
- add app adapter
- require positive class and prediction scale
- add threshold/context artifacts where available
- add `qa_autoquant_binary_shap_analysis_integration()`

Phase 4: segment, time, and dependence expansion.

- add bounded `ByVars` lens artifacts
- add `DateVar` day/week/month aggregation artifacts
- expand dependence plots with target/prediction overlays
- strengthen partial-failure diagnostics

Phase 5: local explanations and advanced interactions.

- selected-row local explanations
- local contribution tables
- two-way interaction surfaces
- richer interaction diagnostics

Phase 6: multiclass and future extensions.

- multiclass module design
- class-specific report plans
- three-way interaction research
- model registry integration

## QA And Acceptance

Proposed QA helpers:

- `qa_autoquant_regression_shap_analysis_integration()`
- `qa_autoquant_binary_shap_analysis_integration()`
- `qa_shap_artifact_contract()`

Acceptance criteria:

- modules load through `app_env`
- module runners return `service_result`
- raw backend errors are caught and converted to friendly errors, warnings, or diagnostic artifacts
- outputs normalize into standard artifacts
- Artifact Library displays SHAP artifacts
- report plans are created and previewable
- Layouts render selected SHAP artifacts
- export includes SHAP artifacts through existing export pathways
- project save/load preserves artifacts, configs, metadata, and report plans
- project bundles preserve enough state to reopen SHAP reports
- `DateVar` aggregation works for day, week, and month
- `ByVars` generate bounded segment artifacts
- missing or invalid SHAP inputs do not crash Shiny
- failures return useful text/table diagnostics
- no module-specific export system is created
- no module-specific artifact state is created
- no direct layout mutation occurs inside module code

The first implementation task should be shared SHAP contracts and adapter scaffolding, not a broad UI build or a full SHAP backend commitment.
