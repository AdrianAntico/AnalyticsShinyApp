# Architecture Causality

This document records causal chains: how one limitation, defect, insight, or implementation pressure caused the next concept to appear. It is not chronological summary. It is the "why this architecture exists" map.

## Master Causal Chain

```text
Need to build around AutoPlots without damaging AutoPlots
  -> separation of rendering package from application shell
  -> AnalyticsShinyApp extraction
  -> service-result and flat-R discipline
  -> artifact management appears
  -> artifacts become durable objects
  -> module outputs need project-level memory
  -> Project Artifact Collector
  -> render targets become explicit
  -> human reports and LLM DOCX split
  -> information encoding becomes separate from render target
  -> artifacts become evidence
  -> evidence routing precedes GenAI
  -> context optimization chooses representation
  -> marginal information gain becomes objective
  -> observability is required for learning
  -> book compiler needs ontology to preserve architecture
```

## Causal Chain: AutoPlots Doctrine To Production Rendering

Problem: The app needed to use AutoPlots without turning AutoPlots into app-specific code.

Cause:

- AutoPlots public APIs already represented production plotting.
- Direct `echarts4r` usage inside the app would bypass the package boundary.
- Generated code needed to be reproducible and portable.

Effects:

- AnalyticsShinyApp was instructed to call `AutoPlots::*` high-level functions.
- The app was forbidden from direct production plot construction with alternate libraries.
- Plot sizing QA was later corrected to use production AutoPlots functions.
- Screenshot generation was corrected to use the production artifact screenshot helper.

Concepts created or strengthened:

- Production Rendering Pipeline
- AutoPlots Doctrine
- Production Screenshot Helper
- Plot Sizing Gallery
- Composite Analytical View audit

## Causal Chain: Dynamic HTML Reports To Static Word Evidence

Problem: HTML reports can resize dynamically, but Word artifacts are static.

Cause:

- Plot labels can overlap or disappear in static screenshots.
- Long labels, many categories, rotation, font size, plot height, and coordinate flipping affect readability.
- LLM DOCX artifacts need readable evidence, not interactive exploration.

Effects:

- `qa_plot_sizing_gallery()` was created.
- The gallery had to use AutoPlots and production screenshot paths.
- Visual failures exposed that LLM evidence documents need different representation policies.
- Human report and LLM DOCX were separated.

Concepts created or strengthened:

- Render Target
- LLM DOCX
- Information Encoding
- LLM Encoding
- Information Density
- Composite Analytical Views

## Causal Chain: Module-Specific Exports To Project Memory

Problem: EDA, Model Readiness, Model Assessment, Model Insights, and SHAP produced outputs independently.

Cause:

- Individual modules thinking "generate my DOCX" duplicated logic.
- Project-level output needed to preserve multiple runs.
- Skipped modules should not fail aggregation.
- Artifact generation failures should be visible but not always fatal to the collector.

Effects:

- Project Artifact Collector was created.
- Artifact bundles became the producer submission contract.
- Collector manifests recorded run/module status.
- Duplicate append protection was implemented.
- Workflow integration loaded or created the collector automatically.

Concepts created or strengthened:

- Project Artifact Collector
- Artifact Bundle
- Collector Manifest
- Project Run
- Project Memory
- Failure Policy

## Causal Chain: Inconsistent Artifact Components To Artifact Quality Policy

Problem: Modules emitted different combinations of screenshots, captions, diagnostics, recommendations, tables, JSON, and metadata.

Cause:

- Collector needed standardized expectations.
- LLM DOCX needed interpretability even when screenshots or JSON were missing.
- Missing optional components should not fail the collector.

Effects:

- Artifact Quality Policy was created.
- Completeness scoring was introduced.
- Graceful degradation became a formal rule.
- Missing components became metadata rather than hidden absence.

Concepts created or strengthened:

- Artifact Quality Policy
- Artifact Completeness
- Screenshot Status
- Quality Metadata
- Graceful Degradation

## Causal Chain: Tables As Widgets To Table Artifacts

Problem: Analytical tables were often rendered as UI widgets or report tables, but LLM evidence and future renderers need backing data and alternate views.

Cause:

- SHAP tables, metrics tables, calibration tables, risk tables, and diagnostics can have multiple meaningful orderings.
- The top and bottom of a table can tell different stories.
- The human default sort is not always the best LLM sort.

Effects:

- Table Artifact Architecture was created.
- Table policies were introduced.
- Explicit vs inferred policy distinction was added.
- CSV and JSON sidecars became part of canonical table evidence.

Concepts created or strengthened:

- Table Artifact
- Table Policy
- Explicit Table Policy
- Preview View
- Sort Policy
- CSV Sidecar
- JSON Sidecar

## Causal Chain: Inference Limitations To Producer Semantics

Problem: Downstream inference could guess artifact meaning, but producers often already knew it.

Cause:

- SHAP importance, threshold metrics, lift/gain, calibration, correlation pairs, missingness, and risk tables have obvious analytical intent.
- Future token-aware rendering needs artifact importance.
- LLM context routing needs better semantics than filenames or captions.

Effects:

- Explicit producer metadata became preferred.
- Analytical intent and importance were introduced.
- Inference remained as compatibility fallback.

Concepts created or strengthened:

- Producer Semantics
- Analytical Intent
- Artifact Importance
- Explicit Table Policy
- Inferred Policy Fallback

## Causal Chain: Optional SHAP Interaction Failure To Diagnostic Skips

Problem: A default SHAP run could fail when requested interaction columns were missing.

Cause:

- Interaction analysis is optional.
- Missing columns, insufficient rows, insufficient unique values, unsupported problem type, or unavailable backend should not destroy main SHAP outputs.

Effects:

- Interaction guards were added.
- Structured interaction diagnostics were required.
- Reports had to render diagnostics/caveats instead of broken sections.
- AnalyticsShinyApp normalization had to tolerate diagnostics-only interaction outputs.

Concepts created or strengthened:

- SHAP Interaction Guard
- Structured Diagnostics
- Optional Artifact Skipping
- Graceful Degradation

## Causal Chain: Model Assessment Name Collision To Terminology QA

Problem: `autoquant_model_assessment` referred to pre-model Target Analysis / Model Readiness.

Cause:

- True model assessment should mean post-model evaluation.
- The workflow needed clean future space for a real Model Assessment module.

Effects:

- Canonical module ID changed to `autoquant_model_readiness`.
- Legacy alias remained only for compatibility.
- Terminology consistency QA was added.

Concepts created or strengthened:

- Model Readiness
- Model Assessment
- Compatibility Alias
- Workflow Registry
- Module Terminology Consistency QA

## Causal Chain: Local-First AI Needs To Provider-Agnostic GenAI

Problem: The workstation needed GenAI features without requiring paid APIs or hard-coding Ollama.

Cause:

- Users may run local/free providers.
- Providers differ in capabilities.
- App startup must not fail if no provider is configured.
- Initial use cases should be read-only.

Effects:

- GenAI Service contract was created.
- Provider adapters and capabilities were normalized.
- Ollama became a working/default local provider, not the architecture.
- UI status could show provider/model/capabilities/privacy.

Concepts created or strengthened:

- GenAI Service
- Provider Adapter
- Provider Capability
- Local-first GenAI
- Read-only GenAI Use Case

## Causal Chain: Unknown Best LLM Context To Information Transfer Experiments

Problem: It was not known whether screenshots, tables, metadata, captions, JSON, or combinations best communicate analytical information to LLMs.

Cause:

- Screenshots may contain visual structure but cost more and require vision.
- Structured tables may be precise but lose visual context.
- Full tables may be too large.
- Providers and models differ.

Effects:

- GenAI calls recorded telemetry.
- Context strategies became named experimental units.
- Ollama smoke tests and experiment harness were created.
- Vision-model support and image-vs-data studies followed.
- Plot-type-aware strategy research was introduced.

Concepts created or strengthened:

- Information Transfer
- Context Strategy
- GenAI Telemetry
- Image-vs-Data Experiment
- Plot-Type-Aware Strategy Study

## Causal Chain: Context Strategy Proliferation To Evidence Routing

Problem: Once many context strategies existed, the system needed to choose among them.

Cause:

- Different artifact families and question types require different evidence.
- Strategy choice depends on provider capabilities, privacy, cost, latency, and accuracy.
- Deterministic metadata should be routed before GenAI reasoning.

Effects:

- Evidence Routing Policy was created.
- Evidence Plan became the output of routing.
- Evidence Strategy UX separated business controls from technical overrides.
- Observability was added for routing decisions.

Concepts created or strengthened:

- Evidence Routing
- Evidence Plan
- Evidence Strategy
- Routing Observability
- Context Optimization

## Causal Chain: Token Minimization Is Insufficient To MIG

Problem: Minimizing tokens alone can remove valuable information, while sending everything can waste context and hurt performance.

Cause:

- Evidence has marginal value and marginal cost.
- Decision criticality changes acceptable cost.
- Redundancy and uncertainty matter.
- Stopping conditions are needed.

Effects:

- Marginal Information Gain became the governing optimization principle.
- Evidence Sufficiency and stopping criteria were named.
- Information compression was reframed as value-preserving reduction.

Concepts created or strengthened:

- Marginal Information Gain
- Evidence Sufficiency
- Knowledge Compression
- Decision Criticality
- Stopping Criterion

## Causal Chain: Dashboard Feel To Premium Workstation UX

Problem: The app risked feeling like a traditional Shiny dashboard despite deeper architecture.

Cause:

- Stock Shiny controls and page layouts were insufficient for a premium analytical workstation.
- Users needed project status, evidence browsing, command navigation, and mode switching.
- Interaction quality matters to perceived intelligence and usability.

Effects:

- Workstation design philosophy was created.
- Reusable UI primitives were introduced.
- Dark-first control/table styling was hardened.
- Artifact Studio, Mission Control, and Command Palette were built.
- Visual QA and dogfooding became part of the UX process.

Concepts created or strengthened:

- Workstation Mode
- Artifact Studio
- Mission Control
- Command Palette
- Evidence Inspector
- Dark-first Design System

## Causal Chain: Conversation Scale To Book Compiler

Problem: The project generated more architecture than one thread, one draft, or one document could preserve.

Cause:

- Multiple Codex threads, repo docs, QA, experiments, implementation changes, and ChatGPT conversations accumulated.
- A book draft without source packs was too polished too early.
- The user needed a full base-layer dump before narrative condensation.

Effects:

- Codex corpus was extracted.
- Workstream ledger and topic dossiers were created.
- Book compiler plan was created.
- Concept ontology became the next required artifact.

Concepts created or strengthened:

- Codex Corpus
- Source Pack
- Workstream Ledger
- Concept Ontology
- Chapter Mapping
- Architecture Synthesis

