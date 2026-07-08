# Table Artifact Architecture

Tables are analytical objects, not screenshots. A table artifact preserves canonical backing data first, then exposes separate human and LLM renderings.

## Lifecycle

1. A module emits an `aq_artifact` with `artifact_type = "table"` and canonical data in `artifact$object`.
2. The table artifact policy declares the intended default analytical view, alternate views, preview size, and backing data expectations.
3. Human reports continue to render interactive tables through the existing `render_table()` path.
4. The Project Artifact Collector writes LLM-oriented table summaries, policy-driven preview slices, metadata, and backing CSV/JSON sidecars.
5. The Artifact Quality Policy evaluates table completeness using caption, metadata, preview, sorting policy, backing data, and JSON availability.

## Canonical Table

The canonical table is the in-memory data frame or `data.table` stored in the artifact object. This remains the source of truth for all render targets.

Screenshots of interactive tables are not treated as canonical because pagination, filters, and sort state expose only one temporary view.

## Human Render Target

Human reports preserve existing behavior:

- `reactable` where available
- pagination
- searching
- sorting
- filtering
- HTML fallback when needed

No human report behavior should depend on the LLM preview policy.

## LLM DOCX Render Target

LLM DOCX output prioritizes structured interpretation over interactive affordances. For table artifacts the collector includes:

- caption
- table summary
- row and column counts
- default sort
- alternate sorts
- preview strategy
- preview row count
- truncation status
- policy-driven preview tables
- backing CSV path
- backing JSON path
- render target metadata

Screenshots may be added later as visual context, but they are never the source of truth for tables.

## Sorting Policy

Every table can declare an analytical default sort and any number of alternate sorts. If a module does not declare one, the shared policy records `Source order` explicitly for backward compatibility.

When creating a table artifact, supply an explicit `table_policy` when:

- there are multiple meaningful analytical orderings
- the table is SHAP, importance, risk, or diagnostic output
- top and bottom slices tell different stories
- the default human sort is not the best LLM sort

Example:

```r
table_artifact_policy(
  default_view = list(
    view_id = "top_mean_abs_shap",
    label = "Mean Absolute SHAP descending",
    sort = table_artifact_sort("mean_abs_shap", "desc")
  ),
  alternate_views = list(
    list(
      view_id = "highest_positive",
      label = "Mean SHAP descending",
      sort = table_artifact_sort("mean_shap", "desc")
    )
  )
)
```

## Preview Philosophy

Preview tables are compact slices of the canonical table, generated from declared views. The first page of an interactive table is not assumed to be the best LLM representation.

Examples of useful future view labels:

- Top 25
- Bottom 25
- Highest Positive
- Highest Negative
- Highest Correlation
- Lowest Correlation

## Backing Data

The collector persists backing files where practical:

- CSV for full tabular data
- JSON for structured machine consumption

Missing backing files are recorded as metadata and warnings where appropriate. They do not make the collector fail by themselves.

## Metadata

Standard table metadata includes:

- `table_id`
- `table_type`
- `table_intent`
- `rows`
- `columns`
- `default_sort`
- `alternate_sorts`
- `preview_strategy`
- `preview_row_count`
- `truncated`
- `csv_available`
- `json_available`
- `render_target`

## Quality Integration

The shared Artifact Quality Policy evaluates table artifacts using:

- caption
- metadata
- preview
- sorting policy
- backing data
- JSON availability

Completeness is informational. Missing optional table components should lower the completeness score or produce warnings, not fail the collector.

## Module Adoption Status

Existing table-producing paths are integrated through the shared artifact boundary. Table artifacts created with `create_artifact()` receive an inferred `table_artifact_policy()` when a producer has not supplied one. Legacy or upstream `aq_artifact` table objects are also normalized when module results enter the Project Artifact Collector.

| Module | Table Name | Purpose | Human Report | LLM Collector | Table Policy | Preview Views | Sort Policy | CSV Sidecar | JSON Sidecar | Quality Policy | Status | Recommended Action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| AutoQuant EDA | Missingness Summary | Missing data diagnostics | Existing interactive table path | Structured table summary and previews | Inferred | Highest Missingness | Missingness descending | Collector writes | Collector writes | Completeness scored | Covered | No action required |
| AutoQuant EDA | Correlation summaries | Correlation diagnostics | Existing interactive table path | Structured table summary and previews | Inferred | Highest Absolute / Positive / Negative Correlation | Correlation strength descending | Collector writes | Collector writes | Completeness scored | Covered | No action required |
| Model Readiness | Feature Risk Registry and readiness tables | Pre-model readiness diagnostics | Existing interactive table path | Structured table summary and previews | Inferred | Highest Risk | Risk score descending when present | Collector writes | Collector writes | Completeness scored | Covered | Modules may provide explicit policies for specialized readiness tables later |
| Regression Model Insights | Metrics, residual, error, and segment tables | Post-model regression diagnostics | Existing interactive table path | Structured table summary and previews | Inferred | Top Metric Values | RMSE/MAE/error descending when present | Collector writes | Collector writes | Completeness scored | Covered | Add explicit policies for specialized model-assessment tables when implemented |
| Binary Model Insights | Threshold, confusion, lift/gain, calibration tables | Post-model binary diagnostics | Existing interactive table path | Structured table summary and previews | Inferred | Top Metric Values; Threshold ascending | Utility/F1/AUC/lift descending when present | Collector writes | Collector writes | Completeness scored | Covered | Add explicit threshold utility policy if AutoQuant exposes richer metadata |
| Regression SHAP Analysis | Global importance and SHAP summaries | SHAP contribution diagnostics | Existing interactive table path | Structured table summary and previews | Inferred | Top Mean Absolute SHAP; Top Positive Mean SHAP; Top Negative Mean SHAP | Mean absolute SHAP descending | Collector writes | Collector writes | Completeness scored | Covered | Explicit policies can be supplied by AutoQuant for future SHAP lenses |
| Binary SHAP Analysis | Interaction importance and threshold context tables | SHAP interaction and binary context diagnostics | Existing interactive table path | Structured table summary and previews | Inferred | Interaction Strength | Interaction strength descending | Collector writes | Collector writes | Completeness scored | Covered | Add explicit policies for grouped/time/local SHAP summaries as they mature |
| CatBoost Builder | Variable importance, metrics, scored-output summaries | Training diagnostics and handoff | Existing interactive table path | Structured table summary and previews | Inferred or preserved from upstream artifact | Top Importance | Importance descending when present | Collector writes | Collector writes | Completeness scored | Covered | No action required |
| Code Runner | Data frame outputs | User-generated table outputs | Existing preview table path | Structured table summary and previews | Inferred | Source order | Source order | Collector writes | Collector writes | Completeness scored | Covered | User code can attach explicit policies in future extension APIs |

## Remaining Gaps

- The app currently infers table policies from artifact labels, sections, and column names when modules do not provide explicit policies.
- Human-facing interactive tables are intentionally unchanged.
- AutoQuant-native report generators may still render their own human tables outside the app collector path; app ingestion normalizes their returned table artifacts for LLM collector use.
- Future modules should provide explicit `table_policy` metadata whenever the table has multiple meaningful orderings, top and bottom slices differ analytically, or the human table sort is not the best LLM representation.

## Extension Guidelines

New modules should emit canonical tables and attach a `table_policy` in artifact config or metadata when the analytical ordering matters. They should not implement their own LLM table renderer or screenshot substitute.

Future renderers such as Markdown, PDF, APIs, and AI packages should consume the same canonical table artifact and policy metadata.
