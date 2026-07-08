# Project Artifact Collector

## Purpose

The Project Artifact Collector is the canonical aggregation layer for project-level artifacts.

Analysis modules produce standardized artifacts. The collector groups those artifacts by project, run, and module, writes a reconstructable manifest, and produces the primary project DOCX:

```text
EDA / Readiness / Assessment / Insights / SHAP
        -> Artifact Bundle
        -> Project Artifact Collector
        -> Project_Artifact_Collector.docx
```

The collector is not a module-specific report generator. It should not know how EDA, Model Readiness, SHAP, forecasting, optimization, or future modules compute their results.

## Artifact Bundle Contract

Use `project_artifact_bundle()` to submit module output to the collector.

Required bundle fields:

- `project_id`
- `project_name`
- `run_id`
- `module_id`
- `module_label`
- `status`
- `artifacts`
- `warnings`
- `errors`
- `diagnostics`
- `metadata`

Artifacts inside the bundle are normal `aq_artifact` objects created with `create_artifact()`.

Supported artifact payloads include:

- `plot`
- `table`
- `text`
- `metric`
- `model_summary`
- `forecast_block`
- `genai_narrative`
- `diagnostic`
- `recommendation`
- `json`
- `narrative`

The collector accepts `service_result` output through `project_collector_append_result()`, which converts the result into a bundle without requiring modules to write collector-specific code.

## Lifecycle

The app manages the collector lifecycle automatically during normal module execution:

1. A user starts or loads an analysis project.
2. The app creates the collector on the first module run, or recreates it when a loaded project resumes.
3. Each completed module `service_result` is appended with a monotonic run id such as `run_001`.
4. Modules not requested for that run may be recorded as `not_requested` bundles so optional stages do not look like failures.
5. The collector validates artifacts and protects against duplicate bundle appends.
6. `project_collector_write()` updates:
   - `Project_Artifact_Collector.docx`
   - `Project_Artifact_Collector_manifest.csv`
   - screenshot artifacts under the collector artifact directory
   - table backing CSV/JSON sidecars under the collector artifact directory

Developers may still create a collector directly with `create_project_artifact_collector()` for tests or batch workflows.

Expected empty states are preserved in the manifest and do not fail the collector:

- module not requested
- module intentionally skipped
- no artifacts generated
- empty section

Unexpected failures are reported as collector failures:

- invalid artifact bundle
- DOCX write failure
- corrupted artifact object
- duplicate append attempts, reported as warnings

Screenshot and table sidecar generation failures are recorded as warnings and quality metadata so the collector can continue rendering remaining artifact context.

## Screenshot Policy

The collector uses the existing production screenshot helper:

```r
AutoQuant::ObjectToPNG()
```

It must not introduce a second screenshot implementation. If the production helper fails, the collector reports the failure and does not fall back to alternate rendering.

Each plot screenshot records helper metadata in the collector write result, including helper name, generated PNG path, staging HTML path when available, viewport width, viewport height, and `selfcontained` behavior reported by the helper.

## DOCX Purpose

The primary collector DOCX is optimized as a compact project corpus for downstream review and LLM interpretation. It favors information-dense screenshots plus grounding metadata over raw data dumps.

Human-oriented R Markdown reports may continue to use richer layout and narrative formatting. The collector DOCX is the canonical project artifact aggregation mechanism.

The collector render target is `llm_docx`. Human report render targets remain independent and must not be degraded by collector screenshot generation.

Each collector write evaluates artifacts with the shared Artifact Quality Policy. Missing optional components lower the informational completeness score but do not fail the collector.

For table artifacts, the collector uses the shared Table Artifact Architecture. The canonical table data remains the source of truth; the DOCX includes table summaries, sorting policy, preview slices, truncation metadata, and backing CSV/JSON paths instead of treating an interactive table screenshot as the primary representation.

## Adding New Modules

New modules should:

- return `service_result`
- include standard `aq_artifact` objects in `result$artifacts`
- set stable `artifact_id`, `artifact_type`, `source_module`, `section`, and `order`
- place module-specific details in `metadata` or `diagnostics`
- avoid writing directly to the collector DOCX

The app shell or workflow coordinator appends module results to the collector through the central module result acceptance path. Individual modules should not call the collector directly.

## Backward Compatibility

Standalone module exports may remain when they already exist, but they are optional. The preferred project workflow is:

```text
Generate artifacts
-> Append artifact bundle
-> Write project collector DOCX and manifest
```

## QA

Run:

```r
qa_project_artifact_collector()
```

The QA covers collector creation, append behavior, multiple module appends, skipped modules, failed modules, ordering, manifest generation, duplicate append protection, screenshot validation, DOCX integrity, backward compatibility with `aq_artifact`, and corrupted bundle validation.
