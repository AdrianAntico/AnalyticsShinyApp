# Artifact Quality Policy

## Purpose

The Artifact Quality Policy defines the common expectations for every standard artifact. It centralizes quality assessment so modules do not invent their own rules for screenshots, captions, metadata, tables, diagnostics, recommendations, or JSON.

The policy is informational and supports graceful degradation. Missing optional components should be recorded, not treated as collector failures.

## Lifecycle

1. A module returns standard `aq_artifact` objects.
2. Producers declare analytical intent, importance, render targets, and artifact-specific policy metadata when the meaning is known.
3. The app accepts the artifacts into the Artifact Library and Project Artifact Collector.
4. The collector renders the target representation, such as `llm_docx`.
5. The quality policy evaluates each artifact.
6. The collector records completeness, missing components, screenshot status, table preview status, sorting policy status, backing data status, and JSON status.

## Producer Responsibilities

Artifact producers are the authoritative source for analytical meaning whenever they already know it. Producers should declare:

- `analytical_intent`: examples include Ranking, Comparison, Relationship, Distribution, Diagnostic, Forecast, Optimization, Segmentation, Time Series, Prediction, Importance, and Interaction.
- `artifact_importance`: one of `critical`, `recommended`, or `supplementary`.
- `render_targets`: target audiences such as `human_report` and `llm_docx`.
- table, plot, or narrative policy metadata when the artifact type has meaningful interpretation rules.

Inference remains supported for backward compatibility, but it should be treated as a fallback rather than the preferred source of artifact meaning.

Explicit policies should be supplied when:

- a table has multiple meaningful orderings
- top and bottom slices tell different stories
- the default human sort is not the best LLM sort
- the artifact is SHAP, importance, risk, diagnostic, threshold, lift, gain, calibration, confusion matrix, residual, or interaction output
- a plot or narrative carries critical interpretation value

Example producer metadata:

```r
metadata = module_artifact_metadata(
  module_id = "autoquant_regression_shap_analysis",
  module_run_id = module_run_id,
  source_module = "autoquant_regression_shap_analysis",
  original_name = "global_importance_table",
  normalized_section = "Global Importance",
  extra = list(
    analytical_intent = "Importance",
    artifact_importance = "critical",
    render_targets = c("human_report", "llm_docx")
  )
)
```

## Components

Required or preferred components:

- Screenshot: required for graphical `llm_docx` artifacts when possible. Screenshot failures become warnings and do not fail the collector.
- Caption: required for every artifact.
- Metadata: required for every artifact, including artifact id, module, render target, creation time, artifact type, caption, screenshot status, table status, and JSON status.
- Narrative: preferred when meaningful.
- Diagnostics: optional, recorded when available.
- Recommendations: optional, recorded when available.
- Backing tables: preferred where practical. Table artifacts preserve canonical data, policy-driven preview slices, sorting semantics, row counts, and truncation status.
- Sorting policy: preferred for table artifacts. When modules do not declare one, source order is recorded explicitly for backward compatibility.
- Backing data sidecars: preferred for table artifacts. The collector records CSV and JSON availability and paths when files are written.
- JSON payload: optional, recorded when available for future machine consumption.

## Render Targets

Human report targets prioritize readability, layout, interactivity, and presentation quality.

The `llm_docx` target prioritizes completeness, interpretability, and supporting evidence. It can use production screenshots plus captions, metadata, tables, narratives, diagnostics, recommendations, and JSON.

## Graceful Degradation

Missing components should degrade gracefully:

- Screenshot failure: record failure, continue rendering caption, tables, metadata, narrative, diagnostics, and recommendations.
- JSON unavailable: record `not_supplied`, continue.
- Recommendation unavailable: record `not_supplied`, continue.
- Narrative unavailable: record `not_supplied`, continue.
- Table JSON unavailable: record `not_supplied`, continue.

The collector should fail only for collector-level failures such as corrupted bundles or DOCX write failure.

## Completeness Score

Each artifact receives `artifact_completeness` from 0 to 100.

Components scored:

- screenshot
- caption
- narrative
- metadata
- diagnostics
- recommendations
- table
- table preview
- sorting policy
- backing data
- JSON

The score is informational. It should guide future module improvements but should not fail the collector by itself.

## Extension Guidelines

Future modules should:

- return standard `aq_artifact` objects
- set clear labels that can become captions
- include module metadata
- declare analytical intent, importance, and render target expectations
- add narratives, diagnostics, recommendations, tables, or JSON when naturally available
- avoid module-specific collector rendering rules

The shared policy functions are:

- `artifact_quality_policy()`
- `assess_artifact_quality()`
- `artifact_quality_summary()`
- `artifact_semantics_audit()`
- `qa_artifact_producer_semantics()`
- `qa_artifact_quality_policy()`
