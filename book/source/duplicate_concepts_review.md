# Duplicate Concepts Review

This document identifies overlapping concepts and recommends whether to merge, rename, or leave them separate.

## Summary Table

| Concept A | Concept B | Recommendation | Reason |
| --- | --- | --- | --- |
| Render Target | Information Encoding | Leave separate | Render target is delivery; encoding is representation. |
| Evidence Routing | Context Optimization | Leave separate | Routing selects evidence; optimization selects representation/profile under constraints. |
| Context Strategy | Evidence Strategy | Leave separate, clarify | Context strategy is technical; evidence strategy is user/business-facing. |
| Artifact Quality | Trustworthiness | Leave separate | Completeness is not reliability. |
| Artifact | Evidence | Leave separate | Artifact is object; evidence is role/use in reasoning. |
| Collector | Report Plan | Leave separate | Collector owns project memory; report plan describes a rendered output. |
| Artifact Studio | Artifact Library | Merge historically into Artifact Studio | Artifact Library was predecessor; Studio is canonical current mode. |
| Model Readiness | Model Assessment | Leave separate | Pre-model suitability vs post-model evaluation. |
| LLM DOCX | Human Report | Leave separate | Different consumers and optimization goals. |
| Information Transfer | Knowledge Compression | Leave separate | Transfer is outcome/process; compression is representation transformation. |
| Evidence Sufficiency | Stopping Criterion | Leave related | Sufficiency is state; stopping criterion is decision rule. |
| Producer Semantics | Artifact Metadata | Leave separate | Metadata stores facts; producer semantics declare analytical meaning. |
| Table Policy | Sort Policy | Leave hierarchical | Sort policy is part of table policy. |
| Consumer Encoding | Information Encoding | Leave hierarchical | Consumer encoding is a specialization of information encoding. |
| Mission Control | Project Workspace | Leave separate | Mission Control is operational status; Workspace is project setup/context. |
| Delivery Studio | Export | Rename future concept to Delivery Studio | Export is too narrow. |
| GenAI Service | Agentic Lab | Leave separate | Service is provider abstraction; Agentic Lab is future UX/action mode. |
| Observability | QA | Leave separate | QA validates; observability records behavior/outcomes over time. |

## Detailed Reviews

### Render Target vs Information Encoding

Recommendation: Leave separate.

Canonical distinction:

- Render Target answers: where and how is the artifact delivered?
- Information Encoding answers: how should the artifact be represented for a consumer?

Why separation matters: The same LLM DOCX render target could contain several encodings, and the same LLM encoding could be delivered through DOCX, Markdown, API JSON, or a future knowledge-base compiler. Merging these concepts would recreate the earlier confusion where output format controlled representation.

Action: Standardize the phrase "render target is delivery; encoding is representation."

### Evidence Routing vs Context Optimization

Recommendation: Leave separate.

Canonical distinction:

- Evidence Routing selects which evidence should be considered.
- Context Optimization selects how that evidence should be represented and how much of it to include under constraints.

Why separation matters: A deterministic router may decide that SHAP importance, model metrics, and calibration are relevant. Context optimization then decides screenshot, table preview, JSON summary, or balanced representation depending on provider and objective.

Action: Keep Evidence Plan as the output of Evidence Routing. Keep Context Strategy as the output of Context Optimization.

### Context Strategy vs Evidence Strategy

Recommendation: Leave separate, clarify naming.

Canonical distinction:

- Context Strategy is technical and concrete: `screenshot_caption`, `table_preview_only`, `structured_json_summary`, `balanced`.
- Evidence Strategy is user/business-facing: Efficient, Balanced, Thorough, Critical Decision, Cost Is Irrelevant.

Why overlap appeared: Both are strategy terms. One is implementation-level; the other is UX/policy-level.

Action: In UI, prefer Evidence Strategy. In telemetry and experiments, use Context Strategy.

### Artifact Quality vs Trustworthiness

Recommendation: Leave separate.

Canonical distinction:

- Artifact Quality primarily measures component completeness and render-target readiness.
- Trustworthiness measures analytical reliability.

Example: A plot can have screenshot, caption, metadata, JSON, and table sidecars but still be based on insufficient data. It is complete but not trustworthy.

Action: Artifact Quality Policy should not be treated as a substitute for validation, assumptions, or statistical trust.

### Artifact vs Evidence

Recommendation: Leave separate.

Canonical distinction:

- Artifact is the durable object.
- Evidence is the role an artifact plays when used for reasoning or decision support.

Why separation matters: Not every artifact is relevant evidence for every question. Evidence Routing turns artifacts into selected evidence.

Action: Use "artifact" for storage, UI, collector, metadata, and producer output. Use "evidence" for reasoning, routing, GenAI, and decision support.

### Collector vs Report Plan

Recommendation: Leave separate.

Canonical distinction:

- Collector owns project memory across modules and runs.
- Report Plan defines a specific renderable report structure.

Why overlap appeared: Both organize artifacts into documents.

Action: Collector can feed report plans, but report plans should not own project memory.

### Artifact Studio vs Artifact Library

Recommendation: Merge historically into Artifact Studio.

Canonical distinction:

- Artifact Library was the first management layer.
- Artifact Studio is the canonical workstation mode.

Action: Use Artifact Library only in historical discussions. Current docs and UI should prefer Artifact Studio.

### Model Readiness vs Model Assessment

Recommendation: Leave separate.

Canonical distinction:

- Model Readiness is pre-model suitability.
- Model Assessment is post-model evaluation.

Why separation matters: The old `autoquant_model_assessment` name was architecturally wrong for pre-model target analysis.

Action: Keep `autoquant_model_readiness` canonical and `autoquant_model_assessment` only as legacy alias.

### LLM DOCX vs Human Report

Recommendation: Leave separate.

Canonical distinction:

- Human Report optimizes readability and communication.
- LLM DOCX optimizes dense evidence transfer to LLMs/custom GPTs.

Why separation matters: Plot sizing and encoding choices differ dramatically.

Action: Do not evaluate LLM DOCX by human report aesthetics alone.

### Information Transfer vs Knowledge Compression

Recommendation: Leave separate.

Canonical distinction:

- Knowledge Compression is the transformation into denser representations.
- Information Transfer is the empirical outcome of a representation communicating useful information.

Action: Treat compression as mechanism and transfer as measured result.

### Evidence Sufficiency vs Stopping Criterion

Recommendation: Leave related, not merged.

Canonical distinction:

- Evidence Sufficiency is a state.
- Stopping Criterion is a rule that decides when sufficiency has been reached.

Action: Keep both under MIG.

### Producer Semantics vs Artifact Metadata

Recommendation: Leave separate.

Canonical distinction:

- Metadata records properties.
- Producer Semantics records intended meaning.

Example: `artifact_type = "table"` is metadata. `analytical_intent = "ranking"` is producer semantics.

Action: Producer semantics should be preferred over inference where available.

### Table Policy vs Sort Policy

Recommendation: Leave hierarchical.

Canonical distinction:

- Table Policy includes preview, sort, sidecar, truncation, and render-target behavior.
- Sort Policy is one part of Table Policy.

Action: Do not elevate Sort Policy into a peer unless it expands across non-table artifacts.

### Delivery Studio vs Export

Recommendation: Rename future concept to Delivery Studio.

Canonical distinction:

- Export is a file operation.
- Delivery Studio is a workstation mode for composing consumer-specific outputs.

Action: Use export for button/action labels; use Delivery Studio for architecture.

### Observability vs QA

Recommendation: Leave separate.

Canonical distinction:

- QA checks expected behavior.
- Observability records actual behavior and outcomes.

Why separation matters: Experiment telemetry and routing observations may not be pass/fail. They are evidence for future learning.

Action: Use QA to protect contracts. Use observability to enable learning.

## Terms To Standardize

Preferred:

- Analytics Workstation
- Artifact
- Evidence
- Project Artifact Collector
- Render Target
- Information Encoding
- Evidence Routing
- Context Optimization
- Context Strategy
- Evidence Strategy
- Marginal Information Gain
- Model Readiness
- Model Assessment
- Artifact Studio
- Mission Control
- Command Palette
- Delivery Studio
- Agentic Lab

Avoid as current canonical terms:

- Dashboard
- Shiny app as product identity
- Artifact Library except historically
- Model Assessment for pre-model readiness
- Export Studio unless intentionally narrower than Delivery Studio
- Prompt engineering as the main framing

