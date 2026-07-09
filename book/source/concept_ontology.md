# Canonical Concept Ontology

This is the canonical concept ontology for Analytics Workstation as extracted from the Codex corpus, workstream ledger, architecture documents, research documents, QA artifacts, and book compiler notes.

This is not the book. It is the knowledge model beneath the book.

The ontology records concepts, definitions, relationships, origin, reason for existence, implementation state, validation state, maturity, open research, and future direction. Each concept has one canonical definition. Related phrases, earlier names, and overlapping ideas are recorded as aliases or adjacent concepts rather than competing definitions.

## Maturity Scale

Foundational: A governing concept that other concepts depend on. It should rarely change.

Stable: Implemented or documented enough to be relied on, but still open to refinement.

Emerging: Recently formalized and directionally clear, but not yet broadly exercised.

Experimental: Implemented or studied as controlled research, not yet product behavior.

Research: A conceptual framework or empirical program that guides experiments.

Speculative: A plausible future concept not yet validated or implemented.

## Canonical Concepts

### 1. Analytics Workstation

Canonical definition: Analytics Workstation is an evidence-centered analytical operating environment that uses Shiny as a reactive engine but treats projects, artifacts, evidence, collectors, render targets, GenAI, and observability as first-class product architecture.

Aliases and related phrases: AnalyticsShinyApp, Analytics Shiny App, premium analytics workstation, analytical operating environment.

Parent concepts: Product vision.

Child concepts: Project, Workstation Mode, Artifact System, Mission Control, Artifact Studio, Command Palette, Project Artifact Collector, GenAI Service, Evidence Routing, Context Optimization.

Dependencies: AutoPlots, AutoQuant adapters, Shiny reactivity, project state, artifact model.

Origin: Began as a local-first Shiny/Electron visualization builder powered by AutoPlots in the AutoQuant-origin thread. It evolved after artifact management, collector architecture, and UI/UX research made the application more than a plot builder.

Why it appeared: The original product needed a safe shell around AutoPlots. Later work revealed that the real product was not chart generation but evidence-centered analytical workflow.

Problem it solved: It provided a product-level home for visualization, analysis modules, artifacts, project memory, reports, and GenAI context without polluting AutoPlots or AutoQuant.

Alternative ideas: A traditional Shiny dashboard, an AutoPlots-only visual builder, a report generator, a notebook-like workflow, or module-specific export tools.

Implementation: Implemented as AnalyticsShinyApp with a workstation shell, workflow pages, Artifact Studio, Mission Control, Command Palette, collector integration, artifact policies, and GenAI service scaffolding.

Validation: Exercised through app QA, visual QA, workflow dogfooding, artifact studio demo seed, collector QA, module integration QA, and dark theme QA.

Current state: Stable as product identity, still emerging as full workstation experience.

Open research: How far the workstation should move toward spatial/canvas workflows, AI-native planning, and model landscape interfaces.

Future evolution: Mission Control, Artifact Studio, Delivery Studio, Agentic Lab, Model Landscape, and Evidence Storytelling should become modes inside one project world.

Maturity: Foundational.

### 2. Project

Canonical definition: A Project is the persistent analytical world that contains data references, runs, module results, artifacts, collector state, manifests, reports, and future GenAI observations.

Parent concepts: Analytics Workstation.

Child concepts: Project Run, Project Artifact Collector, Project Manifest, Project Workspace, Project Memory.

Dependencies: project state serialization, path normalization, collector lifecycle, module execution.

Origin: Early save/load and portable project bundle work in the AutoPlots builder phase; later generalized by the collector.

Why it appeared: The app needed to preserve user work across sessions and support multiple analysis executions without overwriting prior results.

Problem it solved: Prevented the workflow from being a stateless sequence of Shiny tabs. It made analysis durable.

Alternative ideas: Session-only state, module-local files, individual report outputs, notebook files.

Implementation: Project save/load, path normalization, collector files, manifests, artifact directories, demo seeded projects.

Validation: Project load QA, Windows path normalization QA, collector manifest QA, artifact studio seed QA.

Current state: Stable but expanding.

Open research: Project versioning, run diffing, cross-run comparison, project health scoring, and project-level GenAI memory.

Future evolution: Project should become the root unit for all evidence routing, delivery, observability, and learning.

Maturity: Foundational.

### 3. Project Run

Canonical definition: A Project Run is one execution episode inside a project that produces module outputs and artifacts without overwriting previous runs.

Parent concepts: Project.

Child concepts: Module Run, Collector Append, Run Manifest Entry, Run Timeline.

Dependencies: run ID generation, manifest append behavior, duplicate append protection.

Origin: Project Artifact Collector integration required multiple executions within the same project.

Why it appeared: Users may run EDA first, SHAP later, and model insights later still. The project needed chronological memory.

Problem it solved: Avoided overwriting prior artifacts and enabled project history.

Alternative ideas: Single mutable project state, timestamped export folders without a model.

Implementation: Run IDs and manifest status fields in collector architecture.

Validation: Collector QA for multiple module appends, persistent project runs, duplicate protection.

Current state: Stable concept, partially surfaced in UI.

Open research: Run diff, run lineage, run comparison, run quality scoring.

Future evolution: Run Timeline in Mission Control and Model Landscape.

Maturity: Stable.

### 4. Workstation Mode

Canonical definition: A Workstation Mode is a persistent operational view within the same project world, analogous to Lightroom modules or IDE workspaces, optimized for a distinct analytical activity.

Parent concepts: Analytics Workstation UX.

Child concepts: Mission Control, Artifact Studio, Project Workspace, Delivery Studio, Agentic Lab, Model Landscape.

Dependencies: workstation shell, routing, command palette, project state.

Origin: UI/UX research sprint reframed Mission Control, Artifact Studio, and Agentic Lab as modes rather than pages.

Why it appeared: The app needed to stop feeling like a sequence of Shiny pages and start feeling like professional software.

Problem it solved: Removed page-centric thinking and supported a workspace mental model.

Alternative ideas: Shiny tabs, dashboard pages, module screens.

Implementation: Artifact Studio, Mission Control, Command Palette, Project Workspace surfaces.

Validation: Visual QA and dogfooding.

Current state: Emerging.

Open research: Mode switching, persistent panels, saved layouts, keyboard-first workflows.

Future evolution: Modes should share project state, artifact selection, command routing, and GenAI status.

Maturity: Emerging.

### 5. Artifact

Canonical definition: An Artifact is a durable analytical evidence object produced by a module or workflow, carrying payloads such as screenshot, table, narrative, diagnostics, recommendations, JSON, and metadata.

Aliases and related phrases: Analytical artifact, report artifact, evidence object.

Parent concepts: Artifact System.

Child concepts: Plot Artifact, Table Artifact, Narrative Artifact, Diagnostic Artifact, Recommendation Artifact, JSON Artifact, Artifact Bundle.

Dependencies: Artifact Model, Producer Semantics, Artifact Quality Policy, Collector.

Origin: First appeared through plot/text/table artifact management in the Artifact Library. It became central during Project Artifact Collector design.

Why it appeared: Plots, tables, and text needed to be managed, previewed, hidden, ordered, exported, and later used as GenAI evidence.

Problem it solved: Replaced ephemeral outputs with durable, addressable, inspectable evidence.

Alternative ideas: report sections, UI outputs, screenshots, module results.

Implementation: Artifact model helpers, artifact cards, Artifact Studio, collector bundles, table artifacts, quality metadata.

Validation: Artifact Library smoke tests, Artifact Studio QA, collector QA, table policy QA, quality policy QA.

Current state: Foundational and implemented.

Open research: Artifact trustworthiness, evidence sufficiency contribution, learned importance, lifecycle aging.

Future evolution: Artifact lineage, compare, story builder, evidence bundles, GenAI evidence plans.

Maturity: Foundational.

### 6. Evidence

Canonical definition: Evidence is an artifact or artifact component considered as support for reasoning, explanation, decision-making, or GenAI context.

Parent concepts: Knowledge System.

Child concepts: Evidence Plan, Evidence Sufficiency, Evidence Bundle, Evidence Strategy, Evidence Routing.

Dependencies: Artifact, Artifact Quality, Information Encoding, Context Strategy.

Origin: Emerged when artifacts became the input to LLM reasoning rather than merely report outputs.

Why it appeared: The system needed a concept for what GenAI reasons over.

Problem it solved: It separated artifact existence from artifact use in reasoning.

Alternative ideas: context, output, report content, data extract.

Implementation: Evidence routing policy, context optimization policy, GenAI context strategy experiments.

Validation: Experiment harness telemetry, evidence routing calibration, architecture synthesis.

Current state: Foundational as concept, emerging in implementation.

Open research: Evidence scoring, trustworthiness, sufficiency, redundancy, marginal value.

Future evolution: Evidence should become routable, observable, scored, and learnable.

Maturity: Foundational.

### 7. Artifact Model

Canonical definition: The Artifact Model is the shared data structure and helper layer that standardizes artifact identity, payloads, metadata, render-target state, quality state, and producer semantics.

Parent concepts: Artifact System.

Child concepts: Artifact Bundle, Table Artifact, Artifact Quality Metadata, Producer Semantics.

Dependencies: service-result conventions, module producers, collector.

Origin: Early artifact library and layout/report work required common artifact handling.

Why it appeared: Separate plot, text, and table paths risked divergent behavior.

Problem it solved: Gave all artifact types a common contract.

Alternative ideas: Separate UI lists for plots/text/tables, module-specific output objects.

Implementation: Existing artifact helpers and later architecture layers.

Validation: Artifact QA, collector QA, table policy QA.

Current state: Stable.

Open research: Versioning, lineage, provenance depth, compatibility migration.

Future evolution: It should become the substrate for every analytical object in the workstation.

Maturity: Stable.

### 8. Artifact Bundle

Canonical definition: An Artifact Bundle is the standardized package submitted by a producer to the Project Artifact Collector, containing artifact identity, project/run/module metadata, ordering, and one or more payload components.

Parent concepts: Artifact Model.

Child concepts: Bundle Validation, Collector Append, Duplicate Append Protection.

Dependencies: Project, Project Run, Module Producer, Collector.

Origin: Project Artifact Collector architecture.

Why it appeared: Modules needed a shared submission format for project-level collection.

Problem it solved: Avoided module-specific DOCX/report generation paths.

Alternative ideas: module-owned DOCX export, loose lists of files, report-section fragments.

Implementation: Bundle contract documented in `docs/project_artifact_collector.md`.

Validation: Collector creation, append, ordering, duplicate protection, DOCX integrity QA.

Current state: Stable.

Open research: Bundle schema versioning and cross-repo compatibility.

Future evolution: Bundles should support future modules such as forecasting, optimization, causal analysis.

Maturity: Stable.

### 9. Project Artifact Collector

Canonical definition: The Project Artifact Collector is the project-level owner of artifact aggregation, manifesting, and project DOCX generation across modules and runs.

Aliases and related phrases: Collector, project memory, collector document.

Parent concepts: Project Memory.

Child concepts: Collector Manifest, Collector DOCX, Collector Append, Collector Status.

Dependencies: Artifact Bundle, Artifact Quality Policy, screenshot helper, DOCX writer, manifest generation.

Origin: DOCX artifact generation exposed that individual modules should not own final project documents.

Why it appeared: EDA, readiness, assessment, insights, and SHAP generated artifacts independently, creating duplication and fragmentation.

Problem it solved: Centralized artifact aggregation and project memory.

Alternative ideas: per-module DOCX generation, report plan ownership, manual export folders.

Implementation: Collector architecture, manifests, DOCX generation, duplicate append protection, workflow integration.

Validation: `qa_project_artifact_collector()`, aggregate QA, DOCX integrity, screenshot validation.

Current state: Stable and implemented.

Open research: Collector UI surfacing, collector diff, token-aware collector rendering, multi-document strategy for LLM constraints.

Future evolution: Collector becomes canonical project memory for humans and AI.

Maturity: Foundational.

### 10. Collector Manifest

Canonical definition: The Collector Manifest is the reconstructable record of collector runs, module statuses, artifacts added, warnings, errors, document paths, and artifact directories.

Parent concepts: Project Artifact Collector.

Child concepts: Manifest Entry, Module Status, Collector Status.

Dependencies: Project Run, Module execution, Collector append behavior.

Origin: Project Artifact Collector requirements.

Why it appeared: Project-level aggregation needed auditability and reconstructability.

Problem it solved: Prevented collector output from being an opaque DOCX file.

Alternative ideas: console logs, implicit folder contents, report metadata only.

Implementation: Manifest generation and status exposure.

Validation: Manifest QA and workflow integration QA.

Current state: Stable.

Open research: Manifest as GenAI context, manifest summarization, manifest diffing.

Future evolution: Mission Control and Project Workspace should use manifest as project health input.

Maturity: Stable.

### 11. Artifact Quality Policy

Canonical definition: Artifact Quality Policy is the shared policy for evaluating artifact completeness, required metadata, captions, render-target expectations, graceful degradation, and component availability.

Parent concepts: Artifact System.

Child concepts: Completeness Score, Screenshot Status, Table Status, JSON Status, Quality Metadata.

Dependencies: Artifact Model, Collector, Render Targets, Table Artifact Architecture.

Origin: After artifacts and collector existed, modules produced inconsistent screenshots, captions, narratives, diagnostics, recommendations, tables, JSON, and metadata.

Why it appeared: Quality needed to be centralized instead of module-specific.

Problem it solved: Missing optional components became visible without becoming fatal.

Alternative ideas: module-specific quality checks, hard failures for incomplete artifacts.

Implementation: Policy doc, completeness scoring, QA routine.

Validation: `qa_artifact_quality_policy()`, collector behavior tests.

Current state: Stable.

Open research: Relationship to trustworthiness, learned quality scoring, downstream impact on GenAI accuracy.

Future evolution: Quality should feed Evidence Routing and MIG.

Maturity: Stable.

### 12. Artifact Completeness

Canonical definition: Artifact Completeness is an informational score estimating how many expected artifact components are present for a given artifact and render target.

Parent concepts: Artifact Quality Policy.

Child concepts: completeness score, missing component diagnostics.

Dependencies: metadata, screenshot, caption, narrative, diagnostics, recommendations, table, JSON.

Origin: Artifact Quality Policy.

Why it appeared: The system needed a non-fatal way to measure artifact richness.

Problem it solved: Avoided binary pass/fail quality thinking.

Alternative ideas: hard validation failure, no scoring.

Implementation: Completeness score in policy and metadata.

Validation: Quality policy QA.

Current state: Stable.

Open research: Whether completeness predicts usefulness for humans or LLMs.

Future evolution: Completeness should become one feature in MIG and evidence routing.

Maturity: Stable.

### 13. Trustworthiness

Canonical definition: Trustworthiness is the degree to which an artifact can be relied on analytically, based on provenance, diagnostics, validation, assumptions, data quality, and model reliability.

Parent concepts: Evidence.

Child concepts: Diagnostic Quality, Validation Status, Warning Severity.

Dependencies: Artifact Quality, Producer Semantics, module diagnostics.

Origin: Architecture synthesis identified possible tension between Artifact Quality and Trustworthiness.

Why it appeared: A complete artifact can still be analytically unreliable.

Problem it solved: Prevented visual/metadata completeness from being mistaken for evidential reliability.

Alternative ideas: quality score as total trust measure.

Implementation: Mostly conceptual; diagnostics and warnings exist.

Validation: Not yet independently validated.

Current state: Emerging.

Open research: Trust scoring, calibration, relationship to model validation.

Future evolution: Trustworthiness should become a routing feature and a Mission Control signal.

Maturity: Emerging.

### 14. Table Artifact

Canonical definition: A Table Artifact is a canonical analytical table object with backing data, preview views, sort policy, metadata, sidecars, render-target behavior, and quality integration.

Parent concepts: Artifact.

Child concepts: Table Policy, Preview View, CSV Sidecar, JSON Sidecar.

Dependencies: Table Artifact Architecture, Artifact Quality Policy, Collector.

Origin: Tables were initially rendered widgets or report objects, but LLM DOCX and collector needs required canonical backing data.

Why it appeared: Analytical tables contain dense evidence and should not be reduced to screenshots or UI pages.

Problem it solved: Preserved tabular evidence for LLMs, reports, CSV/JSON sidecars, and future renderers.

Alternative ideas: reactable-only output, screenshot-only table export, report-specific tables.

Implementation: Table artifact architecture, policy integration, sidecars, QA expansion.

Validation: `qa_table_artifact_policy()` and module adoption audit.

Current state: Stable.

Open research: Best preview strategies by table type and question type.

Future evolution: Table artifacts should feed evidence routing and information transfer experiments.

Maturity: Stable.

### 15. Table Policy

Canonical definition: Table Policy is the explicit or inferred analytical policy that defines preview views, default sorting, alternate sorting, truncation behavior, and backing sidecars for table artifacts.

Parent concepts: Table Artifact.

Child concepts: Explicit Table Policy, Inferred Table Policy, Sort Policy, Preview Strategy.

Dependencies: producer semantics, table type, render target.

Origin: SHAP, importance, diagnostic, risk, and metrics tables often have multiple meaningful orderings.

Why it appeared: One human-facing table sort may not be the best LLM context.

Problem it solved: Preserved analytical intent and multiple useful views.

Alternative ideas: default UI sort only, generic table truncation.

Implementation: Explicit vs inferred table policies and producer adoption.

Validation: Table policy QA and coverage reports.

Current state: Stable.

Open research: Learned table preview strategies.

Future evolution: Table policies should become context-strategy candidates.

Maturity: Stable.

### 16. Producer Semantics

Canonical definition: Producer Semantics are explicit metadata supplied by artifact-producing modules to declare analytical intent, importance, purpose, interpretation, render targets, and policy expectations.

Parent concepts: Artifact Model.

Child concepts: Analytical Intent, Artifact Importance, Plot Policy, Narrative Policy, Explicit Table Policy.

Dependencies: module producers, artifact model, quality policy.

Origin: The system initially inferred meaning later; adoption work shifted responsibility to producers when they already know intent.

Why it appeared: Inference loses semantic fidelity.

Problem it solved: Made artifact meaning explicit at creation time.

Alternative ideas: downstream inference, naming heuristics.

Implementation: Producer adoption audits and policy fields.

Validation: QA coverage summaries by policy source, intent, importance, render targets.

Current state: Emerging to stable.

Open research: Minimum producer burden, automated suggestions, schema versioning.

Future evolution: Producer semantics should drive routing, rendering, and book examples.

Maturity: Emerging.

### 17. Analytical Intent

Canonical definition: Analytical Intent is the declared purpose category of an artifact, such as ranking, comparison, relationship, distribution, diagnostic, forecast, optimization, segmentation, time series, prediction, importance, or interaction.

Parent concepts: Producer Semantics.

Child concepts: intent-specific policies.

Dependencies: module producer knowledge.

Origin: Explicit Artifact Producer Adoption.

Why it appeared: Future renderers and GenAI routing need to know what an artifact is trying to communicate.

Problem it solved: Avoided treating all artifacts as generic plots, tables, or text.

Alternative ideas: artifact type only, caption parsing.

Implementation: Metadata field, QA reporting.

Validation: Producer semantics coverage QA.

Current state: Emerging.

Open research: Intent taxonomy completeness and multi-intent artifacts.

Future evolution: Intent should guide information encoding and context strategy selection.

Maturity: Emerging.

### 18. Artifact Importance

Canonical definition: Artifact Importance is the producer-declared priority of an artifact, usually critical, recommended, or supplementary.

Parent concepts: Producer Semantics.

Child concepts: token-aware rendering priority, evidence routing priority.

Dependencies: producer knowledge, artifact purpose, decision criticality.

Origin: Explicit producer adoption and future token-aware rendering needs.

Why it appeared: Not all artifacts deserve equal context budget.

Problem it solved: Prepared the system for constrained rendering and evidence routing.

Alternative ideas: all artifacts equal, UI order as proxy.

Implementation: Metadata field and QA coverage.

Validation: Producer semantics QA.

Current state: Emerging.

Open research: Whether importance should be learned, user-adjusted, or producer-fixed.

Future evolution: Importance should feed MIG and evidence sufficiency decisions.

Maturity: Emerging.

### 19. Render Target

Canonical definition: A Render Target is the delivery context for an artifact or report, such as Human Report, LLM DOCX, Artifact Studio, Collector, Presentation, or future API output.

Parent concepts: Delivery Architecture.

Child concepts: Human Report, LLM DOCX, Artifact Studio Preview, Collector DOCX.

Dependencies: Artifact Model, Information Encoding, Quality Policy.

Origin: DOCX export and artifact collector work revealed that different outputs serve different consumers.

Why it appeared: Human reports and LLM evidence documents have different optimization goals.

Problem it solved: Stopped treating export formats as interchangeable.

Alternative ideas: single report renderer, module-specific exports.

Implementation: Render target architecture and render target metadata.

Validation: Render target QA and collector/rendering tests.

Current state: Stable.

Open research: Delivery Studio, PDF/Markdown/API renderers.

Future evolution: Render target should remain separate from information encoding.

Maturity: Foundational.

### 20. Information Encoding

Canonical definition: Information Encoding is the consumer-specific representation of the same analytical artifact, optimized for how a consumer receives and uses information.

Parent concepts: Representation Architecture.

Child concepts: Human Encoding, LLM Encoding, Thumbnail Encoding, Executive Encoding, Developer Encoding, Consumer Encoding.

Dependencies: Artifact, Render Target, Context Optimization, AutoPlots future direction.

Origin: Plot sizing and LLM DOCX discussions revealed that render target and representation are not the same.

Why it appeared: The same artifact should look different when intended for humans, LLMs, thumbnails, executives, or developers.

Problem it solved: Prevented ad hoc LLM-specific plot hacks and clarified that delivery is not representation.

Alternative ideas: render target controls all representation, one-size-fits-all plots.

Implementation: Information Encoding Policy document.

Validation: Conceptual; future experiments planned.

Current state: Emerging foundational policy.

Open research: Measuring information density and comparing encodings experimentally.

Future evolution: AutoPlots V2 consumer-aware encodings and information-transfer studies.

Maturity: Emerging.

### 21. Consumer Encoding

Canonical definition: Consumer Encoding is the class of information encoding optimized for a specific consumer type, including human, LLM, thumbnail, presentation, executive, or developer.

Parent concepts: Information Encoding.

Child concepts: Human Encoding, LLM Encoding, Thumbnail Encoding, Executive Encoding, Developer Encoding.

Dependencies: consumer type, render target, artifact family.

Origin: Information Encoding Policy.

Why it appeared: A consumer's cognitive or computational constraints determine the best representation.

Problem it solved: Avoided treating visual beauty as universal artifact quality.

Alternative ideas: render-target-only tuning.

Implementation: Policy only.

Validation: Planned future research.

Current state: Emerging.

Open research: Consumer-specific encoding performance by artifact family.

Future evolution: Encoding registry and AutoPlots consumer profiles.

Maturity: Research.

### 22. Human Encoding

Canonical definition: Human Encoding represents artifacts for readability, hierarchy, interaction, exploration, spacing, and presentation quality.

Parent concepts: Consumer Encoding.

Dependencies: UI/UX architecture, human reports, interactive widgets.

Origin: Human report and Artifact Studio design work.

Why it appeared: Humans benefit from progressive disclosure and visual clarity.

Problem it solved: Prevented LLM-dense artifacts from degrading human-facing reports.

Implementation: Human Report rendering and workstation UI.

Validation: Visual QA and dogfooding.

Current state: Stable concept, implemented in parts.

Open research: Best human layouts by artifact family and decision context.

Future evolution: Human report preview and Delivery Studio.

Maturity: Stable.

### 23. LLM Encoding

Canonical definition: LLM Encoding represents artifacts for high analytical information density, compactness, evidence completeness, and machine interpretability rather than visual presentation alone.

Parent concepts: Consumer Encoding.

Dependencies: screenshots, captions, tables, JSON, metadata, GenAI context strategies.

Origin: DOCX artifact export and custom GPT knowledge-base discussion.

Why it appeared: LLMs consume evidence differently from humans and may benefit from dense screenshots, tables, captions, and structured summaries.

Problem it solved: Clarified why LLM DOCX should not simply be a human report.

Implementation: LLM DOCX render target, context strategy experiments, information encoding policy.

Validation: Plot sizing gallery and GenAI information-transfer studies.

Current state: Emerging/research.

Open research: Whether screenshots, tables, JSON, or hybrids perform best by artifact type.

Future evolution: LLM-specific AutoPlots encodings and learned context strategies.

Maturity: Research.

### 24. Information Density

Canonical definition: Information Density is the amount of useful analytical signal conveyed per unit of representational cost, such as pixels, tokens, pages, latency, or cognitive load.

Parent concepts: Information Encoding, Marginal Information Gain.

Dependencies: artifact family, context strategy, encoding, consumer.

Origin: Plot sizing and LLM DOCX discussions; formalized in Information Encoding Policy.

Why it appeared: LLM evidence docs need compressed, interpretable representations.

Problem it solved: Reframed plot aesthetics around information transfer.

Implementation: Policy/research concept.

Validation: Not yet quantitatively validated.

Current state: Research.

Open research: Metrics for labels, annotations, data-to-pixel ratio, reference lines, legend complexity.

Future evolution: Information density score.

Maturity: Research.

### 25. Composite Analytical View

Canonical definition: A Composite Analytical View combines multiple analytical encodings in one plot or artifact to increase information transfer, such as importance plus cumulative contribution or histogram plus density.

Parent concepts: Information Encoding, AutoPlots Evolution.

Child concepts: ImportancePareto, HistogramDensity, ScatterSmooth, BoxPlotSummary, SHAPDependenceBinned.

Dependencies: AutoPlots, echarts4r internals, theme helpers, consumer encoding.

Origin: Information Encoding Policy and AutoPlots composite view audit.

Why it appeared: Some decisions require more signal than a single primitive chart can convey.

Problem it solved: Provided a principled reason for composite plots beyond decoration.

Alternative ideas: optional overlays on existing APIs, raw echarts hacks.

Implementation: Audit complete; `ImportancePareto()` prototype implemented in AutoPlots.

Validation: AutoPlots QA/smoke test for prototype.

Current state: Emerging.

Open research: Which composites maximize MIG by artifact family.

Future evolution: AutoPlots V2 composite helpers and consumer-aware encodings.

Maturity: Emerging.

### 26. Production Rendering Pipeline

Canonical definition: The Production Rendering Pipeline is the actual rendering and screenshot/export path users receive, especially AutoPlots function calls and the shared artifact screenshot helper.

Parent concepts: Rendering Architecture.

Child concepts: Screenshot Helper, Widget Save Path, PNG Export, Plot Sizing QA.

Dependencies: AutoPlots, htmlwidgets, screenshot helper, webshot/chromote where used.

Origin: Plot sizing gallery initially used alternate plotting/screenshot logic and was corrected.

Why it appeared: QA using non-production renderers is invalid.

Problem it solved: Ensured plot sizing and artifact screenshots reflect actual user outputs.

Implementation: Plot sizing gallery calls AutoPlots functions and production screenshot helper.

Validation: Plot sizing QA, screenshot metadata, no `ERR_INVALID_URL`, no Pandoc/selfcontained failure.

Current state: Stable principle.

Open research: Cross-platform screenshot stability.

Future evolution: Shared screenshot policy across collector, reports, gallery, and future render targets.

Maturity: Stable.

### 27. Plot Sizing Gallery

Canonical definition: The Plot Sizing Gallery is a reproducible QA harness that generates representative production AutoPlots screenshots and DOCX/HTML outputs for static sizing review.

Parent concepts: Production Rendering Pipeline.

Dependencies: AutoPlots, production screenshot helper, DOCX generation.

Origin: Need to evaluate static plot sizing before Word artifact export.

Why it appeared: HTML reports resize dynamically; Word exports are static.

Problem it solved: Made static sizing failures visible before implementing final DOCX policies.

Implementation: QA routine `qa_plot_sizing_gallery()`.

Validation: Manual visual QA and metadata checks.

Current state: Stable infrastructure, heuristics still future work.

Open research: Sizing policies for labels, rotation, flipping, font size, height, and information density.

Future evolution: Regression test for plot sizing improvements.

Maturity: Experimental.

### 28. Evidence Plan

Canonical definition: An Evidence Plan is the selected set of evidence components and encodings intended to answer a question or support a reasoning task under constraints.

Parent concepts: Evidence Routing.

Child concepts: Context Strategy, Evidence Sufficiency, Evidence Frontier.

Dependencies: artifact inventory, metadata, quality, routing policy, optimization profile.

Origin: Evidence Routing Policy.

Why it appeared: GenAI should receive planned evidence, not arbitrary dumps.

Problem it solved: Separated evidence selection from model prompting.

Alternative ideas: send all artifacts, send raw data, hand-written prompts only.

Implementation: Policy-level and experiment scaffolding.

Validation: Evidence routing calibration and context strategy experiments.

Current state: Emerging.

Open research: Evidence plan scoring and automatic plan construction.

Future evolution: Agentic Lab grounding panel and preview-before-commit.

Maturity: Emerging.

### 29. Evidence Sufficiency

Canonical definition: Evidence Sufficiency is the state where the available evidence is good enough for the current question, decision criticality, and uncertainty tolerance, making further context acquisition low marginal value.

Parent concepts: Marginal Information Gain.

Child concepts: Stopping Criterion, Knowledge Gap, Evidence Frontier.

Dependencies: current knowledge, question type, decision criticality, trustworthiness, context cost.

Origin: Recurring discussions about when enough evidence has been supplied to an LLM; named in MIG framework.

Why it appeared: Context is scarce and more evidence is not always better.

Problem it solved: Provided a stopping logic for evidence acquisition.

Alternative ideas: maximize context, minimize tokens only.

Implementation: Research concept.

Validation: Not yet validated.

Current state: Research.

Open research: Operational metrics for sufficiency and stopping criteria.

Future evolution: Evidence routing should estimate sufficiency before GenAI calls.

Maturity: Research.

### 30. Evidence Routing

Canonical definition: Evidence Routing is the deterministic and policy-guided selection of which evidence should be used for a task before GenAI reasoning occurs.

Parent concepts: Context Optimization.

Child concepts: Evidence Plan, Routing Level, Evidence Strategy Layer, Upstream Priors, Learning Feedback.

Dependencies: Artifact Model, Quality Policy, Producer Semantics, Table Policy, Information Encoding.

Origin: GenAI context work and the principle that routing should happen before probabilistic reasoning.

Why it appeared: GenAI should not be asked to sort through deterministic project facts unnecessarily.

Problem it solved: Reduced waste, improved grounding, and created observable evidence decisions.

Alternative ideas: prompt stuffing, manual prompt selection, model-driven evidence search only.

Implementation: Evidence Routing Policy, calibration sprint, observability layer.

Validation: Policy QA and experiment harness hooks.

Current state: Emerging.

Open research: How to calibrate routing rules and when probabilistic routing is justified.

Future evolution: Evidence plans should be visible, explainable, and learn from outcomes.

Maturity: Emerging.

### 31. Context Optimization

Canonical definition: Context Optimization is the policy layer that chooses the best evidence representation and amount of context for a task, provider, model, user constraint, and decision criticality.

Parent concepts: GenAI Architecture.

Child concepts: Context Strategy, Optimization Profile, Evidence Routing, MIG, Observability.

Dependencies: evidence routing, information encoding, provider capabilities, telemetry.

Origin: GenAI information-transfer experiments and evidence routing policy.

Why it appeared: Different tasks require different tradeoffs among cost, latency, accuracy, privacy, and completeness.

Problem it solved: Moved context selection beyond static prompts.

Alternative ideas: token minimization only, always send screenshots, always send structured data.

Implementation: Context Optimization Policy and experiment telemetry.

Validation: GenAI experiment harness and targeted studies.

Current state: Emerging/research.

Open research: Automatic strategy selection and frontier learning.

Future evolution: Context optimizer recommends strategies based on constraints.

Maturity: Research.

### 32. Context Strategy

Canonical definition: A Context Strategy is a named representation bundle for a GenAI call, such as caption_metadata, screenshot_caption, table_preview_only, full_table, structured_json_summary, or balanced.

Parent concepts: Context Optimization.

Child concepts: Strategy Telemetry, Included Components, Strategy Downgrade.

Dependencies: artifact components, provider capabilities, safety thresholds.

Origin: Information transfer efficiency framework.

Why it appeared: Experiments needed controlled comparisons of representation choices.

Problem it solved: Made GenAI context reproducible and comparable.

Alternative ideas: ad hoc prompts, untracked context assembly.

Implementation: GenAI experiment harness and telemetry fields.

Validation: Ollama smoke tests, mock provider tests, vision support QA, context strategy studies.

Current state: Stable for experiments, not yet optimized product behavior.

Open research: Strategy selection by artifact family and question type.

Future evolution: Context strategies become candidates in Evidence Routing.

Maturity: Experimental.

### 33. Evidence Strategy

Canonical definition: Evidence Strategy is the user-facing or business-facing configuration of how aggressive, economical, thorough, private, or critical evidence gathering should be.

Parent concepts: Evidence Strategy UX.

Child concepts: Efficient, Balanced, Thorough, Critical Decision, Cost Is Irrelevant.

Dependencies: context optimization profiles, routing policy.

Origin: Need to make technical context configuration understandable to MBA-style users while preserving technical override.

Why it appeared: Users should not have to manipulate low-level context strategies directly.

Problem it solved: Provided business-language controls over evidence behavior.

Alternative ideas: raw technical knobs only, automatic hidden behavior.

Implementation: UX/technical configuration docs.

Validation: Policy QA and documentation alignment.

Current state: Emerging.

Open research: Mapping business strategies to technical policy reliably.

Future evolution: UI controls and explainability surfaces.

Maturity: Emerging.

### 34. Marginal Information Gain

Canonical definition: Marginal Information Gain is the expected additional decision-relevant value of including one more evidence component or representation, net of cost, redundancy, uncertainty, and provider capability.

Aliases: MIG.

Parent concepts: Context Optimization, Decision Theory.

Child concepts: Evidence Sufficiency, Stopping Criterion, Information Frontier, Utility Components.

Dependencies: relevance, trustworthiness, novelty, insight gain, decision impact, context cost, uncertainty, redundancy.

Origin: Formalized after context optimization and evidence routing needed a governing objective.

Why it appeared: Token count alone was too shallow; the system needed a decision-theoretic objective.

Problem it solved: Explained why context should be optimized for value, not merely minimized.

Alternative ideas: minimize tokens, maximize evidence volume, fixed strategies.

Implementation: Framework doc.

Validation: Conceptual; future experiment scoring planned.

Current state: Research/foundational principle.

Open research: Measuring MIG empirically and approximating it from telemetry.

Future evolution: MIG should drive evidence planning, context optimization, and stopping criteria.

Maturity: Research.

### 35. Knowledge Compression

Canonical definition: Knowledge Compression is the transformation of raw analytical material into denser, lower-cost representations that preserve decision-relevant information.

Parent concepts: Information Transfer.

Child concepts: Artifact, Table Preview, Visual Summary, Narrative Summary, Executive Summary, LLM DOCX.

Dependencies: artifact generation, information encoding, context strategy.

Origin: Repeated discussions that raw data is usually the wrong unit of AI context and plots/tables provide compressed views.

Why it appeared: LLMs and humans both need manageable representations of complex analytical landscapes.

Problem it solved: Explained why artifacts are better context units than raw datasets.

Alternative ideas: full dataset dump, raw notebook dump.

Implementation: Collector, LLM DOCX, table previews, screenshots, structured JSON summaries.

Validation: Information transfer experiments planned and partially run.

Current state: Emerging concept.

Open research: Measuring compression loss and usefulness by artifact type.

Future evolution: Compression-aware evidence routing.

Maturity: Research.

### 36. Information Transfer

Canonical definition: Information Transfer is the process by which an artifact representation communicates useful analytical content to a consumer at some cost in tokens, latency, cognitive load, or storage.

Parent concepts: GenAI Research, Information Encoding.

Child concepts: Image-vs-Data Experiment, Context Strategy Study, Output Quality, Accuracy, User Rating.

Dependencies: artifacts, context strategies, provider capabilities, telemetry.

Origin: GenAI service instrumentation and LLM DOCX discussion.

Why it appeared: The team needed to learn which representations work best, not assume screenshots or structured data are superior.

Problem it solved: Turned representation choice into an empirical research program.

Alternative ideas: anecdotal preference, one default strategy.

Implementation: GenAI experiment harness, telemetry fields, image-vs-data studies.

Validation: Ollama smoke tests, vision support QA, targeted plot-type-aware studies.

Current state: Experimental.

Open research: Manual scoring, accuracy measurement, artifact-family rules.

Future evolution: Strategy recommendations and learned routing.

Maturity: Experimental.

### 37. GenAI Service

Canonical definition: GenAI Service is the provider-agnostic service layer through which the app performs read-only LLM operations such as chat, generation, artifact summarization, and project briefing.

Parent concepts: GenAI Architecture.

Child concepts: Provider Adapter, Provider Capability, GenAI Telemetry, Mock Provider, Ollama Adapter.

Dependencies: configuration, provider abstraction, service-result pattern.

Origin: Need to support local/free providers before Agentic Lab without hard-coding Ollama.

Why it appeared: The app should call generic functions, not provider-specific functions.

Problem it solved: Avoided coupling app features to one LLM provider.

Alternative ideas: direct Ollama calls, paid API dependency, no abstraction.

Implementation: GenAI service contract and provider adapters.

Validation: `qa_genai_service_contract()`, mock provider, unavailable provider behavior, Ollama payload tests.

Current state: Stable foundation.

Open research: streaming, embeddings, vision, tool calling, remote providers.

Future evolution: Agentic Lab and evidence-grounded AI workflows.

Maturity: Stable.

### 38. Provider Adapter

Canonical definition: A Provider Adapter translates the generic GenAI Service contract into provider-specific availability checks, model lists, request payloads, responses, capabilities, errors, and timeouts.

Parent concepts: GenAI Service.

Child concepts: Ollama Adapter, LM Studio Adapter, llama.cpp Adapter, OpenAI-compatible Adapter.

Dependencies: HTTP endpoints, model capabilities, response normalization.

Origin: GenAI service design.

Why it appeared: Local providers differ but should be swappable.

Problem it solved: Prevented provider-specific logic from leaking into app modules.

Implementation: Ollama working adapter; other providers documented/stubbed.

Validation: payload formation tests, unavailable provider degradation, mock provider.

Current state: Stable for Ollama, emerging for others.

Open research: provider capability discovery, vision payload differences.

Future evolution: Adapter registry.

Maturity: Emerging.

### 39. Provider Capability

Canonical definition: Provider Capability is a normalized declaration of what a GenAI provider/model can do, such as chat, generate, structured JSON, embeddings, vision, streaming, tool calling, local, remote, free, paid, offline, or privacy-preserving.

Parent concepts: GenAI Service.

Dependencies: provider adapter, model metadata.

Origin: Provider-agnostic GenAI contract.

Why it appeared: UI and context strategies need to know what is possible.

Problem it solved: Avoided blind calls to unsupported features.

Implementation: Capability normalization.

Validation: GenAI service QA and vision support QA.

Current state: Stable.

Open research: model-level vs provider-level capability detection.

Future evolution: Capability-aware routing and UI guidance.

Maturity: Stable.

### 40. GenAI Telemetry

Canonical definition: GenAI Telemetry is the structured record of each GenAI call, including provider, model, context strategy, included components, token estimates, reported tokens, latency, success, errors, responses, and later manual scores.

Parent concepts: Observability.

Child concepts: Information Transfer Experiment Result, Strategy Telemetry, Manual Scoring.

Dependencies: GenAI service, context strategy, experiment harness.

Origin: Information Transfer Efficiency requirement.

Why it appeared: The system must learn which representations work best.

Problem it solved: Made GenAI interactions observable and comparable.

Implementation: Telemetry fields in chat/experiment helpers.

Validation: GenAI experiment harness QA.

Current state: Stable infrastructure.

Open research: Quality scoring, accuracy scoring, user ratings, reviewer workflows.

Future evolution: Telemetry feeds learning and context optimization.

Maturity: Experimental.

### 41. Observability

Canonical definition: Observability is the system's ability to record decisions, inputs, routing choices, representations, provider behavior, outputs, scores, failures, and user feedback so future learning is possible.

Parent concepts: Learning System.

Child concepts: GenAI Telemetry, Routing Observability, Collector Manifest, QA Signals.

Dependencies: structured metadata, experiment outputs, manifests.

Origin: GenAI, evidence routing, and context optimization work.

Why it appeared: The system cannot improve what it does not record.

Problem it solved: Prevented hidden AI behavior and unlearnable context decisions.

Implementation: manifests, telemetry, experiment outputs, QA reports.

Validation: QA and experiment artifact creation.

Current state: Emerging but central.

Open research: Metrics, dashboards, learning loops, privacy constraints.

Future evolution: Observability should become an explicit layer across all modes.

Maturity: Emerging.

### 42. Learning

Canonical definition: Learning is the future process of improving evidence routing, context strategies, encoding choices, and recommendations from observed outcomes and feedback.

Parent concepts: Observability.

Child concepts: Calibration, Policy Refinement, Strategy Recommendation, Learned Routing.

Dependencies: telemetry, manual scoring, user feedback, QA outcomes.

Origin: Evidence routing and context optimization policies.

Why it appeared: Static rules should be conservative at first, then improve from outcomes.

Problem it solved: Provided a path from deterministic rules to adaptive intelligence.

Implementation: Not implemented as automatic learning.

Validation: Not applicable yet.

Current state: Speculative/research.

Open research: Feedback schema, safe learning, evaluation design.

Future evolution: Controlled learning loops after sufficient telemetry.

Maturity: Speculative.

### 43. Deterministic Knowledge

Canonical definition: Deterministic Knowledge is information the system can compute, inspect, validate, or retrieve exactly without probabilistic reasoning.

Parent concepts: Context Optimization.

Child concepts: Metadata, Manifest Facts, Artifact Counts, Available Columns, QA Status, File Paths.

Dependencies: project state, artifacts, manifests, deterministic functions.

Origin: Governing principle for AI-native analytical systems.

Why it appeared: LLMs should not spend probabilistic reasoning on facts the software already knows.

Problem it solved: Prevented unnecessary model calls and hallucination risk.

Implementation: Policy principle, QA, structured metadata.

Validation: Repeated in architecture docs and book draft.

Current state: Foundational.

Open research: Boundary between deterministic routing and probabilistic prioritization.

Future evolution: Deterministic fact layer for Agentic Lab.

Maturity: Foundational.

### 44. Probabilistic Reasoning

Canonical definition: Probabilistic Reasoning is GenAI or model-based reasoning reserved for ambiguity, synthesis, judgment, uncertain prioritization, explanation, and open-ended interpretation.

Parent concepts: AI-Native Analytical System.

Dependencies: evidence plans, context optimization, observability.

Origin: Foundational principle in book/manuscript tasks.

Why it appeared: LLMs change analytical software, but should not replace deterministic computation.

Problem it solved: Gave principled boundaries to GenAI usage.

Implementation: GenAI read-only helpers; no autonomous actions.

Validation: GenAI service QA and non-goal enforcement.

Current state: Foundational.

Open research: When probabilistic routing becomes worth the risk.

Future evolution: Preview-before-commit agent plans.

Maturity: Foundational.

### 45. Mission Control

Canonical definition: Mission Control is a workstation mode for project status, workflow progress, collector health, alerts, next actions, run timeline, and decision awareness.

Parent concepts: Workstation Mode.

Child concepts: Project Health Center, Alert Queue, Run Timeline, Collector Status Panel.

Dependencies: project state, collector manifest, workflow registry, GenAI status.

Origin: UI/UX research and roadmap.

Why it appeared: Users need a first-open operational view answering what is happening and what to do next.

Problem it solved: Replaced dashboard-like status fragments with a project command center.

Implementation: Phase 1 built and polished.

Validation: Mission Control QA and visual QA.

Current state: Emerging/stable first version.

Open research: Whether it naturally becomes the first page users open.

Future evolution: project health, run timeline, alert/decision queue, GenAI explanations.

Maturity: Emerging.

### 46. Artifact Studio

Canonical definition: Artifact Studio is a workstation mode for browsing, inspecting, filtering, previewing, and understanding artifacts as first-class analytical evidence objects.

Parent concepts: Workstation Mode.

Child concepts: Artifact Gallery, Artifact Card, Evidence Inspector, Artifact Filmstrip, Artifact Filters.

Dependencies: Artifact Model, Collector, Quality Policy, screenshots, table previews.

Origin: Artifact Library evolved into a premium evidence browser inspired by Lightroom.

Why it appeared: Users should spend analytical time exploring evidence, not hunting through pages.

Problem it solved: Made artifacts central to the experience.

Implementation: Gallery, cards, thumbnails, inspector, filmstrip, demo seed, interaction polish.

Validation: `qa_artifact_studio()`, visual QA, demo seed QA.

Current state: Stable first version.

Open research: Compare, Story Builder, artifact lineage, AI summarization.

Future evolution: The main evidence browsing mode.

Maturity: Stable.

### 47. Evidence Inspector

Canonical definition: Evidence Inspector is the Artifact Studio inspector hierarchy that presents preview, summary, quality, recommendations, diagnostics, metadata, and backing assets as an analytical dossier.

Parent concepts: Artifact Studio.

Child concepts: Hero Preview, Executive Summary, Quality Panel, Backing Asset Panel.

Dependencies: artifact metadata, screenshots, quality metadata, recommendations, diagnostics.

Origin: The initial inspector felt like a property panel; it was redesigned as a dossier.

Why it appeared: Clicking an artifact should feel like investigating evidence.

Problem it solved: Reordered artifact information around meaning before metadata.

Implementation: Premium inspector components and progressive disclosure.

Validation: Artifact Studio QA and visual polish.

Current state: Stable first version.

Open research: AI summaries, compare actions, copy/export interactions.

Future evolution: Evidence reasoning surface for Agentic Lab.

Maturity: Stable.

### 48. Artifact Filmstrip

Canonical definition: Artifact Filmstrip is a persistent quick-navigation strip of recently generated or selected artifacts that supports browsing, context retention, hover, and active state.

Parent concepts: Artifact Studio.

Dependencies: artifact selection state, thumbnails, interaction CSS/JS.

Origin: Artifact Studio layout inspired by Lightroom.

Why it appeared: Users need fast switching without losing context.

Problem it solved: Made artifact browsing feel alive and exploratory.

Implementation: Phase 1 Artifact Studio.

Validation: Artifact Studio QA.

Current state: Stable first version.

Open research: grouping, pinning, compare, recency vs importance sorting.

Future evolution: Reusable workstation component.

Maturity: Stable.

### 49. Command Palette

Canonical definition: Command Palette is the global keyboard-first command and navigation interface for workstation actions, mode switching, and discoverability.

Parent concepts: Workstation Interaction.

Dependencies: routing, command registry, UI shell.

Origin: UI/UX research from IDEs and professional tools.

Why it appeared: Professional workstations should support fast navigation without page hunting.

Problem it solved: Reduced dependence on visible navigation and made advanced actions discoverable.

Implementation: Phase 1 global command palette.

Validation: Command Palette QA and dogfooding.

Current state: Stable first version.

Open research: command ranking, saved commands, macros, contextual commands.

Future evolution: Developer/QA modes, command history, AI-assisted actions.

Maturity: Stable.

### 50. Project Workspace

Canonical definition: Project Workspace is the general project-facing mode or surface for loading data, managing project state, viewing collector status, and entering workflows.

Parent concepts: Workstation Mode.

Dependencies: project state, data loading, collector, navigation.

Origin: Early Shiny app pages and later workstation shell.

Why it appeared: Users need a place to start and manage project context.

Problem it solved: Connected raw project management to analysis modes.

Implementation: Existing app pages updated with workstation styling.

Validation: UI QA and dogfooding.

Current state: Stable but less conceptually central than Artifact Studio/Mission Control.

Open research: Whether Project Workspace should shrink as Mission Control becomes primary.

Future evolution: Project dashboard or project setup surface.

Maturity: Stable.

### 51. Delivery Studio

Canonical definition: Delivery Studio is the future workstation mode for assembling, previewing, and exporting render-target-specific outputs such as human reports, LLM DOCX, evidence bundles, presentations, and future formats.

Parent concepts: Workstation Mode, Delivery Architecture.

Dependencies: Collector, Render Targets, Information Encoding, Report Plans.

Origin: Architecture synthesis identified Export vs Delivery Studio as an unresolved concept.

Why it appeared: Reports, collector docs, LLM evidence docs, and presentations need a unified delivery surface.

Problem it solved: Would replace scattered export actions with intentional delivery workflows.

Implementation: Not implemented.

Validation: None.

Current state: Speculative.

Open research: Relationship to report builder, story builder, collector, and render target preview.

Future evolution: Phase 4 report/evidence storytelling.

Maturity: Speculative.

### 52. Agentic Lab

Canonical definition: Agentic Lab is the future workstation mode where AI proposes plans, explains evidence, previews actions before execution, and remains grounded in project artifacts and evidence plans.

Parent concepts: Workstation Mode, GenAI Architecture.

Dependencies: GenAI Service, Evidence Routing, Context Optimization, Observability, command/action safety.

Origin: UI/UX research and GenAI service non-goals.

Why it appeared: AI-native tools need a place for agentic reasoning, but only after provider abstraction and evidence grounding exist.

Problem it solved: Prevented premature AI action implementation while preserving a future direction.

Implementation: Not implemented.

Validation: Not applicable.

Current state: Speculative.

Open research: Autonomy boundaries, preview-before-commit, action safety, evidence grounding.

Future evolution: AI plan panel, evidence grounding panel, trace panel.

Maturity: Speculative.

### 53. Model Landscape

Canonical definition: Model Landscape is a future spatial or graph-based workstation mode for viewing models, runs, artifacts, diagnostics, metrics, and relationships as an analytical landscape.

Parent concepts: Workstation Mode.

Dependencies: artifact lineage, model registry, run history, visualization layer.

Origin: UI/UX research signature moments.

Why it appeared: End-to-end modeling generates many related artifacts that are hard to understand linearly.

Problem it solved: Would make modeling space navigable and memorable.

Implementation: Not implemented.

Validation: Not applicable.

Current state: Speculative.

Open research: Spatial metaphors, graph layout, model comparison.

Future evolution: Phase 6 spatial model landscape.

Maturity: Speculative.

### 54. Report Plan

Canonical definition: A Report Plan is the structured description of what sections, artifacts, tables, diagnostics, and narratives should render in a report.

Parent concepts: Delivery Architecture.

Dependencies: artifacts, module results, render targets.

Origin: Report generation and SHAP Rmd template work.

Why it appeared: Reports need deterministic plans rather than ad hoc rendering.

Problem it solved: Preserved section contracts and prevented broken report generation when optional artifacts are skipped.

Implementation: Report plan architecture and QA.

Validation: report plan QA, Rmd template render checks.

Current state: Stable.

Open research: Relationship to Delivery Studio and Collector.

Future evolution: Report plans become one input to delivery workflows.

Maturity: Stable.

### 55. Human Report

Canonical definition: Human Report is a render target optimized for human interpretation, presentation quality, readability, and narrative structure.

Parent concepts: Render Target.

Dependencies: report plan, Rmd templates, artifact rendering.

Origin: Existing Rmd reports and report generation.

Why it appeared: Humans need communicable analysis outputs.

Problem it solved: Provides presentation-ready analytical documents.

Implementation: Rmd reports and templates.

Validation: report template render QA.

Current state: Stable.

Open research: Integration with Delivery Studio and Story Builder.

Future evolution: Better report preview and artifact-based story assembly.

Maturity: Stable.

### 56. LLM DOCX

Canonical definition: LLM DOCX is a render target optimized for feeding compressed analytical evidence to LLMs or custom GPT knowledge workflows, prioritizing completeness and interpretability over human presentation aesthetics.

Parent concepts: Render Target.

Dependencies: collector, artifact screenshots, table sidecars, metadata, information encoding.

Origin: Word artifact export discussion and user goal of training/custom GPT knowledge ingestion.

Why it appeared: LLMs are constrained by uploaded document counts and token/cognitive load, so artifacts can compress evidence.

Problem it solved: Created a distinct document type for AI consumption.

Implementation: Collector DOCX and artifact export experiments.

Validation: plot sizing gallery, collector DOCX QA.

Current state: Emerging.

Open research: Single vs multiple DOCX strategy, optimal encoding, visual vs structured evidence.

Future evolution: Token-aware LLM evidence compiler.

Maturity: Research/emerging.

### 57. AutoPlots

Canonical definition: AutoPlots is the production visualization package that owns chart rendering primitives and should be called through high-level public functions from Analytics Workstation.

Parent concepts: Visualization Layer.

Child concepts: Production Rendering Pipeline, Composite Analytical Views, ImportancePareto.

Dependencies: echarts4r internals, theme helpers, screenshot export.

Origin: Pre-existing package and original app foundation.

Why it appeared: The app needed rich plotting without reinventing plotting.

Problem it solved: Provided reusable, high-level chart APIs.

Implementation: External dependency and separate repo.

Validation: AutoPlots QA and production screenshot tests.

Current state: Stable.

Open research: AutoPlots V2 consumer-aware encodings.

Future evolution: Composite functions and information encoding profiles.

Maturity: Foundational.

### 58. AutoQuant

Canonical definition: AutoQuant is the analytics/modeling engine layer that provides modules and adapters such as EDA, Model Readiness, SHAP, Model Insights, and CatBoost Builder to Analytics Workstation.

Parent concepts: Analytics Engine Layer.

Child concepts: AutoQuant EDA, Model Readiness, SHAP Analysis, Model Insights, CatBoost Builder.

Dependencies: AnalyticsShinyApp adapters, optional AutoNLS, AutoPlots.

Origin: Existing modeling/analytics package and early thread context.

Why it appeared: The workstation needed analytical modules without embedding engine logic directly in UI.

Problem it solved: Separated analytics computation from Shiny orchestration.

Implementation: Integration modules/adapters.

Validation: AutoQuant QA, SHAP backend QA, analysis module integration QA.

Current state: Stable dependency.

Open research: Adapter contracts and cross-repo versioning.

Future evolution: More modules and richer artifact producers.

Maturity: Foundational.

### 59. AutoNLS

Canonical definition: AutoNLS is an optional nonlinear modeling engine used for effect curves and model fitting, intended to accept original-scale data while using internal transformations or scaling when needed for optimizer stability.

Parent concepts: Modeling Engine Layer.

Dependencies: AutoQuant SHAP adapter, optional dependency behavior.

Origin: AutoNLS vNext redesign and validation.

Why it appeared: Need robust nonlinear effect-curve fitting.

Problem it solved: Provided flexible nonlinear modeling for effect curves while preserving user-facing original-scale API.

Implementation: AutoNLS vNext and AutoQuant integration.

Validation: raw vs scaled vs transformed strategy validation, convergence/metric comparison QA.

Current state: Emerging/stable as optional backend.

Open research: When manual transformation is necessary and how diagnostics should prove it.

Future evolution: More robust fitting diagnostics and strategy selection.

Maturity: Emerging.

### 60. SHAP Analysis

Canonical definition: SHAP Analysis is the module family for producing SHAP importance, dependence, interaction, grouped summaries, effect curves, diagnostics, and report artifacts.

Parent concepts: AutoQuant Integration.

Child concepts: SHAP Effect Curves, SHAP Interaction Diagnostics, SHAP Tables.

Dependencies: AutoQuant, optional AutoNLS, table policy, artifact quality.

Origin: AutoQuant SHAP integration into AnalyticsShinyApp.

Why it appeared: Model explanation is a central analytical output.

Problem it solved: Connected model interpretation artifacts to the workstation and collector.

Implementation: SHAP modules, adapters, Rmd sections, controls.

Validation: AutoQuant SHAP backend none/autonls QA, Rmd template QA, app integration QA.

Current state: Stable/emerging.

Open research: Effect curve strategy, interaction handling, context strategies by SHAP artifact type.

Future evolution: SHAP-specific LLM encodings and evidence routing rules.

Maturity: Stable.

### 61. SHAP Interaction Guard

Canonical definition: SHAP Interaction Guard is the validation layer that prevents missing or insufficient interaction inputs from failing an otherwise successful SHAP run, emitting diagnostics and skipped artifacts instead.

Parent concepts: SHAP Analysis.

Dependencies: interaction diagnostics artifact, report behavior, app normalization.

Origin: Error where missing `feature_a_col` and `feature_b_col` caused fatal SHAP failure.

Why it appeared: Interaction analysis is optional.

Problem it solved: Preserved main SHAP generation when optional interaction artifacts cannot be generated.

Implementation: Guard checks and structured diagnostics.

Validation: `qa_shap_interaction_guards()`, regression/binary SHAP QA.

Current state: Stable.

Open research: Candidate pair selection and backend availability.

Future evolution: Better interaction recommendation workflows.

Maturity: Stable.

### 62. Model Readiness

Canonical definition: Model Readiness is the pre-model workflow stage that determines whether data are suitable for modeling, including target analysis, leakage detection, collider diagnostics, drift, class balance, missingness, and recommendations.

Aliases: Target Analysis.

Parent concepts: Workflow Stage.

Dependencies: AutoQuant adapter, workflow registry, module registry.

Origin: Terminology migration from `autoquant_model_assessment`.

Why it appeared: Pre-model suitability analysis needed a name distinct from post-model evaluation.

Problem it solved: Prevented architectural ambiguity before implementing true Model Assessment.

Implementation: `autoquant_model_readiness` canonical module ID with legacy alias.

Validation: `qa_autoquant_model_readiness_integration()`, `qa_module_terminology_consistency()`.

Current state: Stable.

Open research: Expanded readiness diagnostics.

Future evolution: Feeds CatBoost Builder and Mission Control alerts.

Maturity: Stable.

### 63. Model Assessment

Canonical definition: Model Assessment is the future or separate post-model evaluation stage for trained/scored models, including RMSE, MAE, ROC, PR, lift, gains, calibration, residual diagnostics, and holdout performance.

Parent concepts: Workflow Stage.

Dependencies: trained model outputs, predictions, scored holdout data.

Origin: Terminology cleanup clarified it must not mean Model Readiness.

Why it appeared: Needed conceptual space for true post-model evaluation.

Problem it solved: Prevented overloading of assessment terminology.

Implementation: Planned; not implemented as pre-model readiness.

Validation: Terminology consistency QA verifies readiness does not invoke `model_assessment`.

Current state: Planned/emerging.

Open research: Artifact contracts for assessment metrics, lift/gain/calibration, residual diagnostics.

Future evolution: True post-model evaluator module.

Maturity: Emerging.

### 64. CatBoost Builder

Canonical definition: CatBoost Builder is the modeling workflow stage that trains/builds CatBoost models after model readiness and before assessment/insights/SHAP.

Parent concepts: Workflow Stage.

Dependencies: model-ready data, AutoQuant/CatBoost integration.

Origin: Workflow architecture.

Why it appeared: Modeling workflow needed a build stage.

Problem it solved: Connected readiness to model outputs.

Implementation: Existing module architecture.

Validation: Workflow/module QA.

Current state: Stable.

Open research: Artifact producer semantics and collector integration depth.

Future evolution: More model build artifacts and diagnostics.

Maturity: Stable.

### 65. Model Insights

Canonical definition: Model Insights is the post-model interpretability and diagnostics stage for explaining trained model behavior beyond assessment metrics.

Parent concepts: Workflow Stage.

Dependencies: model outputs, predictions, AutoPlots, collector.

Origin: Analysis modules integration.

Why it appeared: Users need model interpretation beyond fit metrics.

Problem it solved: Created space for binary/regression insights and visual diagnostics.

Implementation: Binary and regression model insights modules.

Validation: Module QA; blocking defect fixed for unused AutoPlots args.

Current state: Stable.

Open research: Better artifact policies and context strategy rules.

Future evolution: Evidence routing for model insight artifacts.

Maturity: Stable.

### 66. Workflow Registry

Canonical definition: Workflow Registry is the canonical mapping of workflow stages, module IDs, routes, labels, statuses, and launch behavior.

Parent concepts: Workflow Architecture.

Dependencies: module registry, routing, QA.

Origin: Workflow UX and terminology migration.

Why it appeared: Workflow page, Analysis Modules page, registry, routing, and module launcher needed consistency.

Problem it solved: Prevented mismatches between labels and internal IDs.

Implementation: Registry and terminology QA.

Validation: workflow stage registry QA, module registry QA, module terminology consistency QA.

Current state: Stable.

Open research: Dynamic workflow graphs.

Future evolution: Workflow graph mode and command palette integration.

Maturity: Stable.

### 67. Service Result

Canonical definition: Service Result is the standardized result object pattern for operations to report success, errors, warnings, data, and diagnostics without uncontrolled exceptions.

Parent concepts: Service Architecture.

Dependencies: module services, export services, GenAI errors, collector operations.

Origin: Early extraction and export service refactoring to prevent edge-case sprawl.

Why it appeared: Operations needed consistent success/failure reporting.

Problem it solved: Reduced ad hoc error handling.

Implementation: `R/service_result.R` and related service patterns.

Validation: export service smoke tests and module QA.

Current state: Stable.

Open research: Cross-repo standardization.

Future evolution: Service-result style should be used for GenAI, collector, and module adapters.

Maturity: Stable.

### 68. QA Contract

Canonical definition: QA Contract is a named test or validation routine that protects an architectural expectation, module integration, artifact contract, rendering path, or terminology rule.

Parent concepts: Quality System.

Dependencies: sourceable app, QA routines, module registries.

Origin: Repeated tasks added QA for each architectural layer.

Why it appeared: The system accumulated many contracts that ordinary unit tests would not capture.

Problem it solved: Prevented architecture regressions.

Implementation: Many `qa_*()` routines.

Validation: Aggregate QA and targeted QA.

Current state: Stable.

Open research: QA orchestration and reporting UX.

Future evolution: QA mode in workstation and command palette.

Maturity: Stable.

### 69. Book Compiler

Canonical definition: Book Compiler is the future pipeline that converts conversations, architecture docs, experiments, QA, git history, and source packs into manuscript render targets and knowledge products.

Parent concepts: Knowledge Product System.

Child concepts: Source Pack, Chapter Mapping, Architecture Synthesis, Concept Ontology.

Dependencies: corpus extraction, ontology, source packs.

Origin: Need to turn large conversations and architecture history into a serious book.

Why it appeared: Direct book writing was premature without source organization.

Problem it solved: Separated raw source, synthesis, and final narrative.

Implementation: book compiler plan, source packs, corpus dump, first manuscript drafts.

Validation: Documentation only.

Current state: Emerging.

Open research: compiler automation, chapter generation, audience-specific render targets.

Future evolution: Book, website, GPT knowledge base, white papers, talks.

Maturity: Emerging.

### 70. Source Pack

Canonical definition: A Source Pack is a structured collection of source material, excerpts, decisions, empirical findings, examples, and open questions for one concept or chapter.

Parent concepts: Book Compiler.

Dependencies: corpus, docs, git history, QA, experiments.

Origin: Book compiler plan.

Why it appeared: The book needs traceable raw material before narrative condensation.

Problem it solved: Prevented premature polishing and source loss.

Implementation: thread corpus source packs and topic dossiers.

Validation: Corpus extraction counts and file generation.

Current state: Emerging.

Open research: Automated source pack creation by ontology concept.

Future evolution: Source packs should feed chapter drafts mechanically.

Maturity: Emerging.

### 71. Concept Ontology

Canonical definition: Concept Ontology is the canonical knowledge model of Analytics Workstation concepts, relationships, maturity, evolution, overlaps, and future research paths.

Parent concepts: Book Compiler, Architecture Synthesis.

Dependencies: corpus, architecture docs, research docs, source packs.

Origin: Current task after raw corpus extraction.

Why it appeared: The book and future GPT knowledge system need concept architecture before narrative.

Problem it solved: Reorganized chronology into conceptual structure.

Implementation: This document and companion graph/cluster/mapping documents.

Validation: Documentation and future review.

Current state: First canonical draft.

Open research: Missing concepts and refinement through reading.

Future evolution: Should become the backbone for docs, book, GPT knowledge, talks, and software architecture.

Maturity: Emerging/foundational.

### 72. Knowledge State

Canonical definition: Knowledge State is the project-level representation of what is currently known, believed, assumed, unknown, contradicted, decision-ready, and still requiring evidence.

Parent concepts: Knowledge System.

Child concepts: Knowledge, Unknown, Assumption, Hypothesis, Validated Finding, Open Question, Decision Readiness, Knowledge Gap, Contradiction, Future Evidence.

Dependencies: Artifact, Evidence, Project Artifact Collector, Artifact Quality, Producer Semantics, Evidence Sufficiency, Marginal Information Gain, Observability.

Origin: Introduced after the artifact/evidence architecture matured enough to expose a missing layer above Evidence Routing.

Why it appeared: The system could understand evidence inventory, but not yet what the project knew or still needed to learn.

Problem it solved: It separated evidence existence from interpreted project understanding.

Alternative ideas: Let Evidence Routing infer needs directly, treat collector manifest as knowledge, or let GenAI synthesize knowledge ad hoc.

Implementation: Architecture-only in `docs/knowledge_state_architecture.md` and `book/source/knowledge_state.md`.

Validation: Not implemented; conceptual architecture accepted for future work.

Current state: Emerging.

Open research: Knowledge graph representation, confidence scoring, contradiction handling, decision readiness calibration, update rules.

Future evolution: Knowledge State should guide evidence acquisition, context optimization, next-question recommendation, and future learning.

Maturity: Emerging/foundational.

### 73. Knowledge

Canonical definition: Knowledge is a project-level conclusion, belief, or understanding supported by evidence and accompanied by confidence, assumptions, provenance, and limitations.

Parent concepts: Knowledge State.

Child concepts: Validated Finding, Decision, Confidence.

Dependencies: Evidence, reasoning, artifacts, diagnostics, observations.

Origin: Named explicitly in the Knowledge State Architecture.

Why it appeared: Evidence alone is not enough; the system needs to know what follows from evidence.

Problem it solved: Distinguished artifact inventory from interpreted understanding.

Alternative ideas: Treat evidence as knowledge directly.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: How knowledge should be updated, challenged, versioned, and explained.

Future evolution: Knowledge claims should become graph nodes with supporting and contradicting evidence.

Maturity: Emerging.

### 74. Unknown

Canonical definition: An Unknown is a question, relationship, risk, condition, or variable state whose truth is not currently established by available evidence.

Parent concepts: Knowledge State.

Child concepts: Open Question, Knowledge Gap, Missing Evidence.

Dependencies: current knowledge, evidence inventory, decision context.

Origin: Knowledge State Architecture.

Why it appeared: Intelligent analytical systems need to represent absence of knowledge, not only available artifacts.

Problem it solved: Made uncertainty addressable and routable.

Alternative ideas: Leave unknowns implicit in recommendations.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Unknown detection from artifacts, diagnostics, and user questions.

Future evolution: Unknowns should drive next-question and future-evidence recommendations.

Maturity: Emerging.

### 75. Assumption

Canonical definition: An Assumption is a statement currently treated as true or acceptable for reasoning despite incomplete validation.

Parent concepts: Knowledge State.

Child concepts: Assumption Risk, Assumption Test.

Dependencies: findings, decisions, diagnostics, user context.

Origin: Knowledge State Architecture.

Why it appeared: Decisions often depend on unvalidated conditions that should remain visible.

Problem it solved: Prevented hidden premises from being mistaken for validated findings.

Alternative ideas: Embed assumptions inside narrative only.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Assumption extraction, testing, and expiration.

Future evolution: Assumptions should connect to evidence and decision readiness.

Maturity: Emerging.

### 76. Hypothesis

Canonical definition: A Hypothesis is a plausible but unvalidated claim that requires evidence.

Parent concepts: Knowledge State.

Child concepts: Test, Future Evidence, Validated Finding.

Dependencies: user questions, artifacts, recommendations, domain context.

Origin: Knowledge State Architecture.

Why it appeared: The system needs to distinguish claims being tested from claims already supported.

Problem it solved: Prevented speculative ideas from being promoted to findings.

Alternative ideas: Treat all generated suggestions as recommendations.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Hypothesis generation and test planning.

Future evolution: Hypotheses should connect to experiments and future evidence.

Maturity: Emerging.

### 77. Validated Finding

Canonical definition: A Validated Finding is a claim supported by sufficient evidence for the current decision context.

Parent concepts: Knowledge.

Child concepts: Finding Confidence, Supporting Evidence, Contradicting Evidence.

Dependencies: Evidence Sufficiency, decision context, quality, trustworthiness.

Origin: Knowledge State Architecture.

Why it appeared: The system needs a concept for findings that have crossed a contextual evidence threshold.

Problem it solved: Separated findings from hypotheses and recommendations.

Alternative ideas: Treat every narrative conclusion as validated.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Validation thresholds by decision criticality.

Future evolution: Validated findings should become reportable and routable project knowledge.

Maturity: Emerging.

### 78. Open Question

Canonical definition: An Open Question is an explicit unresolved analytical question that should guide future evidence acquisition.

Parent concepts: Unknown.

Child concepts: Next Highest-Value Question, Future Evidence.

Dependencies: Knowledge Gap, decision readiness, user goals.

Origin: Knowledge State Architecture.

Why it appeared: Unknowns need operational form.

Problem it solved: Converted uncertainty into actionable inquiry.

Alternative ideas: Leave gaps as generic recommendations.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Ranking open questions by expected information value.

Future evolution: Open questions should feed Mission Control, Agentic Lab, and context optimization.

Maturity: Emerging.

### 79. Decision Readiness

Canonical definition: Decision Readiness is the degree to which available knowledge and evidence are sufficient to support a decision under the current stakes and constraints.

Parent concepts: Knowledge State.

Child concepts: Insufficient Evidence, Preliminary, Reasonable, High Confidence, Critical Decision Ready.

Dependencies: confidence, evidence sufficiency, contradictions, assumptions, decision criticality.

Origin: Knowledge State Architecture.

Why it appeared: The system needed to distinguish model confidence from evidence confidence for action.

Problem it solved: Provided a bridge between analytical findings and decisions.

Alternative ideas: Use model metrics or LLM confidence as decision confidence.

Implementation: Architecture-only with proposed levels.

Validation: Future work.

Current state: Emerging.

Open research: Calibration of readiness levels and UI presentation.

Future evolution: Decision Readiness should be surfaced in Mission Control and reports.

Maturity: Emerging/foundational.

### 80. Knowledge Gap

Canonical definition: A Knowledge Gap is the difference between what is currently known and what must be known to reach the desired decision readiness.

Parent concepts: Knowledge State.

Child concepts: Missing Evidence, Future Evidence.

Dependencies: current knowledge, decision readiness target, open questions.

Origin: Knowledge State Architecture.

Why it appeared: Evidence routing needs to know what is missing, not only what exists.

Problem it solved: Made evidence acquisition goal-directed.

Alternative ideas: Generic "more analysis needed" recommendations.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Gap detection and prioritization.

Future evolution: Knowledge gaps should drive next highest-value questions.

Maturity: Emerging.

### 81. Contradiction

Canonical definition: A Contradiction is evidence or a finding that conflicts with another finding, assumption, hypothesis, or recommendation.

Parent concepts: Knowledge State.

Child concepts: Contradicting Evidence, Resolution Evidence.

Dependencies: evidence graph, findings, assumptions.

Origin: Knowledge State Architecture.

Why it appeared: Analytical systems must preserve conflicting evidence rather than averaging it away.

Problem it solved: Made conflict explicit and actionable.

Alternative ideas: Hide contradictions inside narratives or confidence scores.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Contradiction detection and severity.

Future evolution: Contradictions should lower confidence and drive future evidence requests.

Maturity: Emerging.

### 82. Future Evidence

Canonical definition: Future Evidence is evidence that could be generated, collected, or requested to reduce uncertainty or increase decision readiness.

Parent concepts: Knowledge State.

Child concepts: Recommended Next Analysis, Evidence Acquisition.

Dependencies: Knowledge Gap, Missing Evidence, Marginal Information Gain, Context Optimization.

Origin: Knowledge State Architecture.

Why it appeared: The system needed a concept for evidence that does not yet exist but would improve knowledge.

Problem it solved: Connected open questions to concrete analytical next steps.

Alternative ideas: Recommendations without evidence linkage.

Implementation: Architecture-only.

Validation: Future work.

Current state: Emerging.

Open research: Ranking future evidence by marginal information gain.

Future evolution: Future Evidence should feed Mission Control and Agentic Lab planning.

Maturity: Emerging.

## Missing Or Newly Named Concepts

The corpus contains repeated ideas that were not always named consistently. The following are recommended canonical additions.

Evidence Sufficiency: Named in this ontology and MIG framework. It captures the stopping condition for evidence gathering.

Knowledge Compression: Named here as the cross-cutting idea behind artifacts, table previews, screenshots, summaries, and LLM DOCX.

Analytical Information Transfer: Use Information Transfer as canonical. It captures the empirical study of how well representations communicate to consumers.

Decision Criticality: Keep as a feature of Evidence Strategy, MIG, and Context Optimization. It should not be a standalone subsystem yet.

Consumer Encoding: Keep as canonical parent for Human/LLM/Thumbnail/Executive/Developer encodings.

Sequential Evidence Acquisition: Treat as future research under Evidence Routing and MIG. It describes acquiring evidence in stages until sufficiency is reached.

Evidence Frontier: Treat as a supporting concept under Evidence Strategy UX and MIG. It describes the cost/value frontier of available context strategies.

Project Memory: Treat as an explanatory alias for Project Artifact Collector plus manifests and run history.

Delivery Studio: Keep as speculative future mode replacing scattered export thinking.

Trustworthiness: Keep separate from Artifact Quality.

Knowledge State: Now canonical. It sits above Evidence Routing and represents what the project knows, assumes, does not know, and still needs to learn.

Decision Readiness: Now canonical. It represents evidence confidence for action, not model confidence.

Future Evidence: Now canonical. It represents evidence that does not yet exist but would reduce uncertainty or increase readiness.

## Foundational Chain

The highest-level conceptual hierarchy is:

Project

-> Artifacts

-> Evidence

-> Knowledge State

-> Information Encoding

-> Render Targets

-> Evidence Routing

-> Context Optimization

-> Marginal Information Gain

-> GenAI

-> Observability

-> Learning

This chain should guide future book structure, documentation, and software development.
