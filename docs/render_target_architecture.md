# Render Target Architecture

## Purpose

Artifacts now have explicit render targets because human-facing reports and LLM-facing project collectors have different presentation needs.

Human reports optimize for reviewer experience. LLM collectors optimize for dense evidence transfer.

## Targets

Current targets are registered by `render_targets()`:

- `human_report`
- `html_report`
- `rmarkdown`
- `llm_docx`
- `markdown`
- `pdf`
- `json_archive`

Each target has a policy from `render_target_policy()`.

## Human Reports

Human report targets preserve the existing behavior:

- interactive AutoPlots widgets stay interactive
- existing R Markdown / HTML renderers stay unchanged
- sizing and layout are controlled by the existing report renderer
- widgets are not replaced by screenshots

The human artifact is the original standard `aq_artifact`.

## LLM Collectors

The `llm_docx` target is owned by the Project Artifact Collector.

For plot artifacts, the collector uses the production screenshot helper:

```r
AutoQuant::ObjectToPNG()
```

The screenshot is an additional LLM-ready representation. It does not mutate or replace the human artifact object.

The collector DOCX includes:

- screenshot
- caption
- source artifact id
- artifact type
- module id
- section
- ordering
- screenshot helper
- screenshot status
- metadata
- structured table previews
- table sorting policy
- table backing CSV/JSON paths
- narratives
- diagnostics
- recommendations
- JSON/text payloads where available

## ExportPNG Semantics

`ExportPNG = TRUE` means: produce an additional LLM-ready static representation alongside the human artifact.

It must not mean: replace the human report widget with a PNG.

The intended lifecycle is:

```text
Production AutoPlots object
  -> human_report: interactive widget, unchanged
  -> llm_docx: production screenshot plus context
```

Both renderings originate from the same production visualization object.

## Extension Points

Future render targets should be added by extending:

- `render_targets()`
- `render_target_policy()`
- target-specific collector/export adapters

Do not add module-specific target branches to the Project Artifact Collector. Modules produce standard artifacts; presentation layers decide how to render them.

## QA

Run:

```r
qa_render_targets()
```

The QA verifies registered targets, human widget preservation, LLM screenshot generation, captions, metadata, table payloads, DOCX integrity, manifest integrity, and `ExportPNG = TRUE` behavior.

Artifact completeness and missing component handling are covered by `qa_artifact_quality_policy()`.

Table render target behavior is covered by `qa_table_artifact_policy()`.
