# Workstream Ledger: Incremental Steps, Decisions, and Empirical Findings

This ledger is not the final narrative. It is the base material Adrian asked for: the closest practical reconstruction of the thought process, action sequence, architecture decisions, implementation steps, empirical observations, and remaining gaps across the accessible Codex threads.

It should be read alongside:

- `combined_user_request_sequence.md` for the request stream.
- `combined_chronology_actions_findings.md` for the detailed action stream.
- `empirical_findings_validation_signals.md` for raw QA/failure/fix signals.
- the topic dossiers for source excerpts by workstream.

## 1. Original Product Impulse: Build Around AutoPlots Without Damaging AutoPlots

The work began in the AutoQuant/AutoPlots orbit with a very practical product question: how to create a local-first Shiny/Electron visualization builder powered by AutoPlots without turning AutoPlots itself into an application framework.

The core doctrine was established early:

- Analytics Shiny App should be a product shell around AutoPlots.
- AutoPlots public APIs should not be redesigned from inside the app.
- Generated chart code should call high-level AutoPlots functions such as `AutoPlots::Area()`, `AutoPlots::Line()`, `AutoPlots::Bar()`, etc.
- The app should not call `echarts4r` directly for plots.
- The app should remain local-first.
- Export targets should include HTML, PNG, R code, and later richer project bundles.

This early doctrine mattered because it created the first architectural separation:

- AutoPlots owns rendering primitives.
- AnalyticsShinyApp owns workflow, state, project UI, artifact management, and orchestration.
- AutoQuant owns modeling/analytics engines and adapters.

Empirical/implementation result:

- The first skeleton centered on data loading, plot configuration, preview, generated code, and export.
- Multi-plot layout, sections, save/load, and project bundles followed.
- Service-result style helpers emerged to prevent ad hoc edge-case handling.

## 2. Extraction Into AnalyticsShinyApp

The app was then extracted into its own repository: `C:\Users\Bizon\Documents\GitHub\AnalyticsShinyApp`.

The handoff from the AutoQuant-origin thread preserved several facts:

- The app should depend on AutoPlots externally via `library(AutoPlots)`.
- The old AutoPlots copy should not be deleted without explicit direction.
- R source should remain flat under `R/`.
- Nested directories such as `R/services`, `R/registries`, `R/project`, and `R/utils` were discouraged.
- `app.R` existed at repo root.
- `R/service_result.R` and `R/service_export.R` were created/kept as flat helpers.
- Export service smoke tests had passed.

Empirical/implementation result:

- The app became a separate product surface rather than a feature inside AutoPlots or AutoQuant.
- This separation made later workstation concepts possible because the app could evolve independently while respecting AutoPlots and AutoQuant contracts.

## 3. Artifact Library: First Move Toward Artifact-Centered Thinking

The Artifact Library request introduced a central place to view, preview, organize, edit metadata, hide/show, export, and remove report artifacts.

The important conceptual move was this:

Artifacts were no longer just transient UI outputs. They became managed objects.

Expected artifact types included:

- plots
- text blocks
- tables

Required metadata included:

- `artifact_id`
- `artifact_type`
- `label`
- `source_module`
- `section`
- `order`
- `visible`
- `status`

The requested behavior established several future principles:

- All artifacts should be summarized through one combined artifact summary.
- Selection should use artifact IDs.
- Preview should dispatch through existing artifact renderers.
- Visibility should affect layouts without deleting artifacts.
- Table export should use full backing data, not only displayed pages.
- Project state should persist artifact metadata.

Empirical/implementation result:

- The Artifact Library became a precursor to Artifact Studio.
- The system learned that artifacts needed identity, metadata, preview, visibility, and export behavior.

## 4. AutoNLS vNext: Modeling Engine Reliability and Internal Transformations

A large segment of work focused on AutoNLS vNext and its integration path through AutoQuant and AnalyticsShinyApp.

One important empirical question was explicitly raised:

Can AutoNLS reliably fit models on raw/original-scale data, or are internal transformations/scaling still required?

Validation dimensions requested:

- raw original-scale x/y fitting
- scaled x/y fitting
- log/log1p transformed starts where appropriate
- family-specific transformed initialization only

The user-facing API principle was clear:

- Users should provide original-scale data.
- Internal scaling/transformations may be used for optimizer stability.
- Outputs, predictions, derivatives, and elasticities should remain on original scale.
- Users should not be forced to pre-transform unless diagnostics prove it necessary.

QA outputs requested:

- convergence rate by strategy
- objective/metric comparison by strategy
- selected model by strategy
- warnings/failure reasons
- whether final predictions return on original scale

Empirical/implementation result:

- AutoNLS was treated as an internal modeling/fit engine whose stability strategy should be measured, not assumed.
- The project established a recurring pattern: user-facing API remains simple/original-scale while internal implementation can use stabilizing transformations as long as outputs are returned in user terms.

## 5. AutoQuant SHAP and Effect Curves

AutoNLS then moved into AutoQuant SHAP workflows as an optional effect-curve backend.

Key architectural rules:

- AutoNLS should remain optional.
- AnalyticsShinyApp should not call AutoNLS directly.
- AnalyticsShinyApp should expose controls and pass them into AutoQuant adapters.
- AutoQuant should own the SHAP/effect-curve adapter behavior.

Controls requested in AnalyticsShinyApp:

- `effect_curve_backend`
- max features
- sample size
- validation fraction

Artifacts/contracts requested:

- `shap_effect_curve_*` artifacts
- Rmd template sections
- docs alignment
- app integration QA

Empirical/implementation result:

- The integration chain became explicit:

  AutoNLS -> AutoQuant SHAP -> AnalyticsShinyApp controls

- The app gained a pattern for optional advanced backends: expose controls, route to adapter, preserve optional dependency behavior, do not call low-level engine directly.

## 6. SHAP Interaction Guarding

A broad/default SHAP run with interactions enabled could fail when interaction columns were missing, producing errors such as:

`feature_a_col and feature_b_col must exist in data.`

The requested philosophical correction:

- Interaction analysis is optional.
- Missing interaction inputs should produce diagnostics and skipped artifacts.
- SHAP generation should not fail because optional interaction artifacts cannot be created.

Required diagnostics included:

- status
- reason_code
- reason
- severity
- feature_a
- feature_b
- required_columns
- available_columns
- recommendation

Example reason codes:

- `missing_columns`
- `insufficient_rows`
- `insufficient_unique_values`
- `interaction_not_requested`
- `interaction_backend_unavailable`
- `unsupported_problem_type`
- `no_candidate_pairs`

Empirical/implementation result:

- This established a graceful-degradation rule that later generalized into Artifact Quality Policy and collector failure policy.
- Optional analytical outputs should fail locally and diagnostically, not collapse the broader run.

## 7. Workflow Terminology: Model Readiness vs Model Assessment

A critical terminology cleanup happened after Workflow UX v1.

Problem:

- The internal adapter/module ID `autoquant_model_assessment` actually represented pre-model Target Analysis / Model Readiness.
- But true Model Assessment should mean post-model evaluation.

Architecture rule established:

Pre-model Model Readiness:

- target analysis
- leakage detection
- collider diagnostics
- drift
- class balance
- missingness
- readiness recommendations

Post-model Model Assessment:

- RMSE
- MAE
- ROC
- PR
- lift
- gains
- calibration
- residual diagnostics
- holdout performance

New canonical pre-model module:

- `autoquant_model_readiness`
- `module_autoquant_model_readiness`
- `qa_autoquant_model_readiness_integration()`

Compatibility rule:

- `autoquant_model_assessment` could remain only as a legacy alias.
- It should not be the preferred identifier.

Empirical/implementation result:

- The workflow could naturally read:

  EDA -> Feature Engineering -> Model Prep -> Model Readiness -> CatBoost Builder -> Model Assessment -> Model Insights -> SHAP Insights -> Report / Export

- A later QA routine, `qa_module_terminology_consistency()`, was requested to prevent regression.

## 8. Plot Sizing QA and Production Rendering Discipline

Before DOCX artifact export, a plot sizing gallery was requested.

Initial objective:

- Generate representative plots for manual review of static sizing.
- Cover bar plots, variable importance, heatmaps, correlation matrices, scatter plots, box plots, line/area charts, and SHAP-style plots.
- Generate both HTML and DOCX outputs.

Important correction from user:

- The gallery must use production AutoPlots rendering, not alternate plotting libraries.
- It must reuse the same screenshot/export helper used by production artifact generators.
- It must not implement custom HTML-to-PNG logic.

Specific empirical failures discovered:

- `selfcontained = TRUE` caused Pandoc failures in widget saving.
- Existing EDA artifact export worked because it used a different production path/argument pattern.
- Some screenshots showed browser `ERR_INVALID_URL` pages.
- Some DOCX plots looked wrong, empty, or missing axis labels.
- `Theme = "light"` was invalid for AutoPlots; default dark theme should be respected unless explicitly supported.
- Bar plots with many x-axis labels needed rotation or coordinate flipping.
- 45-degree label rotation was insufficient for large label counts; 90 degrees was more viable, but too many labels may require flipped coordinates and larger height.
- Label length also matters, not just label count.
- Font-size reduction through axis parameters could help.

Key product insight:

- Human Rmd reports are for humans.
- LLM DOCX artifacts are information-dense evidence dumps for later custom GPT training or reasoning.
- The goal is not necessarily visual beauty; it is readable compressed information.

Empirical/implementation result:

- Production rendering became a strict QA requirement.
- Static artifact generation exposed the need to distinguish human-readable reports from LLM evidence documents.
- This directly led to render targets and information encoding concepts.

## 9. Project Artifact Collector

The Project Artifact Collector was introduced as a major architecture change.

Core realization:

The project, not each individual module, should own artifact collection.

Old framing:

- Each module generates its own DOCX.

New framing:

- Modules generate standardized artifact bundles.
- The Project Artifact Collector aggregates those bundles into project memory and project documents.

Standard artifact bundle fields included:

- project id
- run id
- module id
- section title
- subsection
- artifact type
- ordering index
- plot/screenshot/table/narrative/recommendation/diagnostics/JSON/metadata payloads

Failure policy:

Expected non-failures:

- module not requested
- module skipped
- no artifacts generated
- empty section

Unexpected failures:

- artifact generation failure
- screenshot failure
- DOCX write failure
- corrupted bundle
- collector append failure

Manifest fields included:

- project_id
- project_name
- run_id
- timestamp
- module
- status
- artifacts_added
- warnings
- errors
- collector_docx
- artifact_directory

Empirical/implementation result:

- Collector architecture, bundle contract, manifest generation, DOCX generation, duplicate append protection, and QA were implemented and validated.
- Later workflow integration made the collector automatic for project runs.
- The collector became the canonical destination for generated artifacts.

## 10. Blocking Integration Defects

During collector/workflow integration, aggregate QA surfaced two blocking defects.

AutoQuant EDA failure:

- Error: `subscript out of bounds`
- Requirement: investigate and fix root cause, not suppress.

Binary Model Insights failure:

- Error: unused AutoPlots arguments
- Requirement: update integration to call current AutoPlots API correctly, not ignore unsupported arguments.

Empirical/implementation result:

- Aggregate QA was improved so collector success would not be masked by unrelated module failures.
- Module failures remained independently visible.
- This reinforced the principle that project-level infrastructure and module-level failures should be separable.

## 11. Render Targets: Human vs LLM Artifact Rendering

The system then separated render targets.

Important distinction:

- Human Report and LLM DOCX have different purposes.
- A human report should optimize readability, layout, narrative, progressive disclosure, and presentation quality.
- An LLM DOCX should optimize completeness, interpretability, evidence density, and supporting artifacts.

Empirical/implementation result:

- Render targets became explicit architecture rather than accidental output formats.
- This prepared the ground for Artifact Quality Policy, Table Artifact Architecture, and Information Encoding Policy.

## 12. Artifact Quality Policy

The Artifact Quality Policy standardized what artifacts should contain and how missing components should be handled.

Components:

- screenshot
- caption
- narrative
- diagnostics
- recommendations
- backing tables
- JSON payload
- metadata

Core rules:

- Every artifact should have a concise caption.
- Graphical artifacts should have screenshots for LLM DOCX when possible.
- Missing optional components should not fail the collector.
- Screenshot failure should be recorded and rendering should continue.
- Completeness score should be informational, not a hard failure.

Empirical/implementation result:

- Missing optional content became visible rather than fatal.
- Artifacts could degrade gracefully.
- Future modules could inherit a centralized quality framework.

## 13. Table Artifact Architecture

The Table Artifact Architecture generalized tables into first-class analytical artifacts.

Core requirements:

- canonical table artifacts
- table policy
- human vs LLM render targets
- preview generation
- sorting policy
- CSV/JSON backing sidecars
- Artifact Quality Policy integration
- Project Artifact Collector integration

Important user clarification:

Explicit `table_policy` should be supplied when:

- there are multiple meaningful orderings
- the table is SHAP, importance, risk, or diagnostic
- top and bottom slices tell different stories
- the default human sort is not the best LLM sort

Empirical/implementation result:

- Inference remained available for backward compatibility.
- Explicit producer policies became preferred when the producer knows analytical intent.
- SHAP, metrics, lift/gain, calibration, confusion matrices, missingness, risk, correlation pairs, and grouped summaries were identified as candidates for explicit table policies.

## 14. Explicit Artifact Producer Adoption

After Artifact Model, Render Targets, Collector, Quality Policy, Table Architecture, and Producer Semantics were implemented, the next step was to make producers explicitly declare intent rather than relying on inference.

New metadata concepts:

- artifact importance: critical, recommended, supplementary
- analytical intent: ranking, comparison, relationship, distribution, diagnostic, forecast, optimization, segmentation, time series, prediction, importance, interaction
- plot purpose
- expected interpretation
- recommended caption
- quality expectations
- render target expectations
- narrative audience and priority

Empirical/implementation result:

- Architecture shifted from infer-meaning-later toward producer-supplied semantics.
- Inference became compatibility fallback rather than the preferred semantic path.

## 15. UX Philosophy Shift: Premium Analytical Workstation

A major product identity shift occurred.

The goal stopped being:

- build a nice Shiny application

The goal became:

- build a premium analytics workstation that happens to use Shiny as its reactive engine

Shiny responsibilities were narrowed to:

- reactivity
- state management
- module orchestration
- server communication
- routing

Everything else became replaceable by better HTML/CSS/JS interaction design.

Design system primitives requested:

- cards
- metric tiles
- status badges
- progress indicators
- artifact preview cards
- collector status panels
- timeline components
- workflow progress components
- section headers
- callouts
- warning/success panels
- empty/loading states
- notification toasts
- action bars
- split panels
- resizable panels
- dockable side panels
- search panels
- command palette
- artifact gallery
- project dashboard

Product identity:

- evidence-centered analytical operating environment
- not dashboard
- not Shiny app

Empirical/implementation result:

- A reusable dark-first workstation layer was introduced.
- Initial pass upgraded Project Workspace, then broader pages were updated.
- Later QA revealed dark theme regressions in tables and Shiny controls, leading to reusable dark-first table/control styling.

## 16. UI/UX Research Sprint and Roadmap

A broad UI/UX research sprint studied patterns from:

- command line and terminals
- IDEs
- creative tools
- trading terminals
- BI tools
- notebooks
- analytics dashboards
- design tools
- AI-native tools
- control rooms
- storytelling/reporting interfaces

Reference products included:

- Bloomberg Terminal
- VS Code
- Cursor
- JetBrains IDEs
- Figma
- Linear
- Notion
- Power BI Desktop
- Tableau
- JupyterLab
- Observable
- Databricks
- Adobe Lightroom
- NASA/industrial control-room dashboards
- AI agent workspaces

Research outputs requested:

- historical evolution
- pattern library
- candidate UI ideas
- signature memorable moments
- radically different workspace concepts

Empirical/implementation result:

- Research was integrated into repository documentation.
- Product Vision, UI/UX Research, and UX Roadmap were separated.
- Mission Control, Artifact Studio, and Agentic Lab were reframed as workstation modes, not pages.

## 17. Artifact Studio

Artifact Studio was the first major workstation mode.

Initial layout:

- left: artifact filters, project collections, artifact types, runs, modules, quality
- center: artifact gallery with cards, thumbnails, metadata
- right: artifact inspector
- bottom: persistent artifact filmstrip

Artifact cards were expected to show:

- title
- module
- run
- quality
- importance
- analytical intent
- render targets
- hover actions
- open/inspect/compare/add-to-story placeholders

Artifact Inspector evolved into Evidence Inspector.

Hierarchy:

- hero preview
- executive summary
- quality panel
- diagnostics
- recommendations
- metadata
- backing assets

Empirical/implementation result:

- Artifact Studio gained populated demo seed projects.
- Real plot thumbnails were wired from existing artifact/collector screenshot paths.
- Inspector became more dossier-like.
- Selection, hover, filmstrip, transitions, active highlighting, and empty states were polished.
- Project load path normalization was added for Windows paths.

Key product insight:

- Artifact Studio should feel like Lightroom Library meets analytical evidence browser.
- Users should naturally spend most analytical time there.

## 18. Mission Control

Mission Control was introduced as another workstation mode.

Purpose:

- become the place users open first
- summarize project state, workflow progress, collector health, alerts, and next actions
- help users understand what remains to be done

Empirical/implementation result:

- Mission Control became part of the premium workstation layer.
- Later visual QA/polish focused on whether it felt operational rather than dashboard-like.

## 19. Command Palette

The Global Command Palette was built as Phase 1 of keyboard-first navigation.

Purpose:

- make the workstation feel like professional software
- provide fast mode switching and action discovery
- reduce reliance on page scanning

Empirical/implementation result:

- Command Palette became a key part of the ?workstation, not Shiny page? interaction model.
- Dogfooding later identified future commands that should exist but should not yet be implemented unless trivial.

## 20. Dogfooding and Workflow Friction

A dogfooding sprint was requested after Mission Control, Artifact Studio, Command Palette, Collector, Render Targets, Artifact Quality Policy, Table Architecture, Producer Semantics, and dark-first design were in place.

The test workflow:

- create/open project
- load data
- EDA
- Model Readiness
- Model Build
- Model Assessment
- Model Insights
- SHAP
- Collector
- Reports
- Artifact Studio
- Mission Control
- Export

Evaluation questions:

- how many clicks?
- how much scrolling?
- was the next action obvious?
- did the user know where to go?
- was anything confusing?
- did it feel fast/enjoyable?
- would a first-time user know what to do?
- does it feel like an evidence-centered analytical operating environment or still like Shiny pages?

Empirical/implementation result:

- The work emphasized low-risk, high-impact workflow improvements only.
- No new modes, AI, Agentic Lab, Workflow Graph, Story Builder, Compare, or backend redesign were allowed.

## 21. GenAI Service Contract

A provider-agnostic GenAI service layer was requested before Agentic Lab.

Supported/prepared providers:

- Ollama
- LM Studio
- llama.cpp server
- OpenAI-compatible local endpoints

Core app-level calls:

- `genai_chat()`
- `genai_generate()`
- `genai_summarize_artifact()`
- `genai_brief_project()`

Provider contract:

- provider id
- display name
- base URL
- model
- capabilities
- availability check
- list models
- chat
- generate
- structured output
- timeout/error handling
- response normalization

Capabilities:

- chat
- generate
- structured_json
- embeddings
- vision
- streaming
- tool_calling
- local
- remote
- free
- paid
- offline
- privacy_preserving

Context policy:

Do not dump full datasets or huge tables by default. Prefer:

- project metadata
- collector manifest summary
- artifact captions
- quality metadata
- diagnostics
- recommendations
- preview tables
- sidecar references

Empirical/implementation result:

- Local provider absence should not crash the app.
- Initial use cases were read-only: summarize artifact, brief project, explain alerts, suggest next action.
- No autonomous actions were allowed.

## 22. Information Transfer Experiments

A framework was requested to test which artifact representations communicate useful information to an LLM at lowest cost.

Telemetry fields:

- context_strategy
- included components
- estimated/reported input tokens
- latency
- provider/model
- output_quality_score placeholder
- accuracy_score placeholder
- user_rating placeholder

Context strategies included:

- screenshot only
- caption + metadata only
- screenshot + caption
- table preview only
- full table
- screenshot + caption + preview table
- structured JSON summary

Core goal:

Learn the tradeoff frontier between:

- token cost
- latency
- output quality
- factual accuracy
- user usefulness

Empirical/implementation result:

- Ollama smoke tests and reusable experiment harness were requested.
- Later vision-model support enabled image-vs-data experiments.
- Plot-type-aware strategy research framework followed.

## 23. Evidence Routing, Context Optimization, and MIG

The GenAI work led to a layered reasoning architecture.

Evidence Routing:

- decide which evidence should be sent before invoking GenAI
- deterministic routing should precede probabilistic reasoning
- record routing decisions for later learning

Context Optimization:

- choose context strategy according to constraints such as minimize tokens, maximize accuracy, balanced, local/private, fastest response
- do not automatically optimize yet; instrument first

Marginal Information Gain:

- govern evidence inclusion by asking what additional value each context component contributes relative to cost
- optimize marginal information gain, not token count alone
- include decision criticality, uncertainty reduction, and diminishing returns

Foundational principle:

Deterministic knowledge should be computed deterministically. Probabilistic reasoning should be reserved for ambiguity, synthesis, judgment, and uncertain prioritization. When used, record why and learn from outcomes.

Empirical/implementation result:

- Evidence routing and context optimization became policy/research layers rather than ad hoc prompt engineering.
- Observability became necessary before learning.

## 24. Information Encoding Policy

A new distinction emerged:

Render target and information encoding are not the same concept.

Hierarchy:

Analytical Artifact -> Information Encoding -> Render Target

Consumer types:

- Human
- LLM
- Thumbnail
- Presentation
- Executive
- Developer

LLM encoding optimizes for:

- information density
- annotation density
- compact legends
- smaller but readable fonts
- more labels
- reference lines
- combined analytical views
- higher data-to-pixel ratio
- less decorative whitespace

Human encoding optimizes for:

- readability
- visual hierarchy
- spacing
- interaction
- presentation quality
- progressive disclosure

Empirical/implementation result:

- The plot sizing conversation evolved into a formal architecture policy.
- Future AutoPlots work can support consumer-aware encodings without ad hoc LLM-specific hacks.

## 25. AutoPlots Composite Views

AutoPlots was audited for future composite analytical views.

Candidate composites:

- bar + line
- importance + cumulative line
- histogram + density
- scatter + smoother
- scatter + marginals
- SHAP dependence + binned mean
- boxplot + mean/reference
- trend + anomaly/reference bands

Recommended architecture:

- named public composite functions
- shared internal helper where useful
- reuse existing helpers and theme defaults where possible
- raw echarts4r only where necessary
- avoid overlay flags that cause parameter explosion

First prototype:

- `ImportancePareto()`

Purpose:

- ranked importance bars
- cumulative contribution line
- optional cutoff/reference
- simple API defaults
- future-ready for LLM information encoding

Empirical/implementation result:

- Composite plots were framed as information-transfer tools, not decoration.
- `ImportancePareto()` became the first proof of concept.

## 26. Architecture Synthesis and Book Compiler

As documentation grew, architecture synthesis was requested.

Mental model:

Project -> Artifacts -> Information Encoding -> Render Targets -> Evidence Routing -> Context Optimization -> GenAI -> Observability -> Learning

Concepts to align:

- Artifact
- Evidence
- Collector
- Render Target
- Information Encoding
- Context Strategy
- Evidence Plan
- Marginal Information Gain
- Context Optimization
- GenAI Provider
- Observability
- Delivery

Book compiler plan:

- preserve conversations, docs, commits, experiments, and architecture decisions
- distinguish source material from manuscript
- eventually render to book, website, GPT knowledge base, white papers, talks

Empirical/implementation result:

- A first manuscript section and overcomplete book v0 were created, but the user correctly clarified that the missing base was not polished narrative but a complete source dump.
- This corpus dump is the correction.

## 27. Cross-Cutting Principles That Emerged

These principles recurred across the work:

1. Do not spend probabilistic intelligence on deterministic facts.
2. Artifacts are evidence, not outputs.
3. The project owns memory; modules produce evidence.
4. Optional analysis should degrade into diagnostics, not fatal errors.
5. Human and LLM renderings require different optimization goals.
6. Render target is delivery; information encoding is representation.
7. Producer semantics are higher fidelity than inference.
8. Inference remains a compatibility fallback.
9. Local-first and privacy-preserving GenAI should work without paid providers.
10. Observability must precede learning.
11. The app should feel like a premium analytical workstation, not a Shiny dashboard.
12. AutoPlots remains the production rendering path for plots.
13. QA should protect architecture contracts, not just function outputs.
14. The right primitive for AI-native analytics is not raw data; it is evidence.

## 28. Empirical Findings Worth Carrying Forward

The following findings are especially important for the eventual narrative:

- Raw/original-scale APIs are important for usability, but internal scaling/transformation may be needed for optimizer stability.
- Optional SHAP interaction analysis must never fail an otherwise successful SHAP run.
- Static DOCX plot export exposes sizing failures that dynamic HTML hides.
- Production screenshot path reuse is essential; visually similar plots are invalid QA.
- `selfcontained = TRUE` can trigger Pandoc failure; production widget screenshot staging may need `selfcontained = FALSE` patterns.
- Axis label count, label length, rotation, font size, coordinate flipping, and plot height all affect LLM-readable screenshots.
- For LLM artifacts, visual beauty is secondary to information density and legibility.
- Tables need analytical policies because top/bottom/alternate orderings can tell different stories.
- The Collector architecture helps prevent module-specific DOCX sprawl.
- Artifact Quality Policy makes missing content visible without making incompleteness fatal.
- Evidence routing and context optimization should be instrumented before automated.
- Vision models must record whether real image payloads were used or only image references.
- Context strategy results should not be overclaimed without manual scoring.

## 29. Remaining Source Gaps

Important gaps remain, and they are now explicit:

- Regular ChatGPT web-interface conversations are not fully present unless pasted into Codex.
- Some large pasted attachment contents may be represented by wrapper messages if not preserved in the local JSONL text.
- Some historical tool outputs are truncated to keep extracted documents usable.
- Some compacted context may be present only as summaries or encrypted payloads.

These gaps do not invalidate the corpus. They define what must be added in a future source-ingestion pass.
