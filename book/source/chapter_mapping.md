# Chapter Mapping From Concept Ontology

This document maps ontology concepts to future book chapters. It is not the manuscript. It is a mechanical planning layer for future chapter generation.

Estimated pages are intentionally broad and assume an overcomplete draft before pruning.

## Proposed Book Spine

Working title: AI-Native Analytical Systems: Designing Software That Reasons Over Evidence

### Part I: Why Analytical Software Must Change

#### Chapter 1: From Dashboards To Evidence-Centered Operating Environments

Purpose: Establish why dashboards, notebooks, and reports are insufficient as the primary architecture for AI-native analytics.

Concepts:

- Analytics Workstation
- Project
- Workstation Mode
- Evidence-centered analytical operating environment
- Human Report
- LLM DOCX

Prerequisites: None.

Examples: dashboard sprawl, notebook fragility, static reports, project-level evidence memory.

Experiments: none required; conceptual and historical.

Code/architecture docs: `docs/vision/product_vision.md`, `docs/architecture_synthesis.md`.

Estimated pages: 20-35.

#### Chapter 2: Deterministic Knowledge Before Probabilistic Reasoning

Purpose: Establish the governing principle that deterministic facts should be computed deterministically and LLM reasoning reserved for ambiguity and synthesis.

Concepts:

- Deterministic Knowledge
- Probabilistic Reasoning
- GenAI Service
- Evidence Routing
- Observability

Prerequisites: Chapter 1.

Examples: artifact counts, available columns, model metrics, warnings, project metadata.

Experiments: future comparison of deterministic extraction vs LLM extraction.

Docs: `docs/context_optimization_policy.md`, `docs/genai_service_architecture.md`.

Estimated pages: 20-30.

### Part II: Artifacts As Evidence

#### Chapter 3: The Artifact As The Core Unit Of Analytical Knowledge

Purpose: Define artifacts and explain why raw data is usually the wrong unit of AI context.

Concepts:

- Artifact
- Evidence
- Artifact Model
- Artifact Bundle
- Producer Semantics
- Analytical Intent
- Artifact Importance

Prerequisites: Chapters 1-2.

Examples: SHAP importance, target distribution, EDA summaries, model diagnostics.

Experiments: information transfer examples showing artifact compression.

Docs: `docs/artifact_quality_policy.md`, `docs/architecture_synthesis.md`.

Estimated pages: 30-45.

#### Chapter 4: Artifact Quality, Completeness, And Trust

Purpose: Separate completeness from trustworthiness and explain graceful degradation.

Concepts:

- Artifact Quality Policy
- Artifact Completeness
- Trustworthiness
- Diagnostics
- Recommendations
- Graceful Degradation

Prerequisites: Chapter 3.

Examples: screenshot failure with caption/table fallback, missing JSON, optional diagnostics.

Experiments: QA examples and collector behavior.

Docs: `docs/artifact_quality_policy.md`.

Estimated pages: 20-30.

#### Chapter 5: Tables Are Analytical Artifacts

Purpose: Explain table artifacts, policies, previews, sidecars, and alternate analytical views.

Concepts:

- Table Artifact
- Table Policy
- Explicit Table Policy
- Sort Policy
- Preview View
- CSV Sidecar
- JSON Sidecar

Prerequisites: Chapter 3.

Examples: SHAP importance, lift/gain, calibration, confusion matrix, missingness.

Experiments: table preview vs full table information transfer.

Docs: `docs/table_artifact_architecture.md`.

Estimated pages: 25-40.

### Part III: Project Memory

#### Chapter 6: The Project Artifact Collector

Purpose: Explain why the project owns artifact collection and modules become producers.

Concepts:

- Project Artifact Collector
- Collector Manifest
- Project Run
- Artifact Bundle
- Project Memory
- Duplicate Append Protection

Prerequisites: Chapters 3-5.

Examples: EDA plus SHAP across multiple runs, skipped modules, manifest reconstruction.

Experiments: collector QA and DOCX integrity checks.

Docs: `docs/project_artifact_collector.md`.

Estimated pages: 30-45.

#### Chapter 7: Render Targets And Delivery

Purpose: Separate project memory from report delivery and explain human reports vs LLM DOCX.

Concepts:

- Render Target
- Human Report
- LLM DOCX
- Collector DOCX
- Report Plan
- Delivery Studio

Prerequisites: Chapter 6.

Examples: Rmd report, collector document, LLM evidence dump.

Experiments: plot sizing gallery, DOCX readability.

Docs: `docs/render_target_architecture.md`, `docs/report_plan_architecture.md`.

Estimated pages: 25-35.

### Part IV: Encoding And Information Transfer

#### Chapter 8: Information Encoding Is Not Rendering

Purpose: Establish consumer-specific encoding.

Concepts:

- Information Encoding
- Consumer Encoding
- Human Encoding
- LLM Encoding
- Thumbnail Encoding
- Executive Encoding
- Developer Encoding
- Information Density

Prerequisites: Chapter 7.

Examples: dense LLM plot, human report plot, thumbnail card, executive summary.

Experiments: human vs LLM encoding studies.

Docs: `docs/information_encoding_policy.md`.

Estimated pages: 30-45.

#### Chapter 9: Visual Evidence And Composite Analytical Views

Purpose: Explain AutoPlots, production rendering discipline, static sizing, and composite views.

Concepts:

- AutoPlots
- Production Rendering Pipeline
- Plot Sizing Gallery
- Composite Analytical View
- ImportancePareto
- Information Density

Prerequisites: Chapter 8.

Examples: importance Pareto, histogram density, SHAP dependence plus binned mean, bar label rotation.

Experiments: static sizing QA, information transfer by plot family.

Docs: `docs/autoplots_composite_view_audit.md`, `docs/information_encoding_policy.md`.

Estimated pages: 25-40.

#### Chapter 10: Measuring Information Transfer

Purpose: Define information transfer experiments across screenshots, captions, tables, JSON, and hybrids.

Concepts:

- Information Transfer
- Context Strategy
- GenAI Telemetry
- Image-vs-Data Experiment
- Plot-Type-Aware Strategy Study
- Manual Scoring

Prerequisites: Chapters 8-9.

Examples: screenshot_caption vs table_preview_only, structured_json_summary.

Experiments: Ollama smoke test, targeted plot-type-aware study.

Docs: `docs/genai_context_strategy_research.md`, `docs/genai_service_architecture.md`.

Estimated pages: 30-50.

### Part V: Evidence Routing And Optimization

#### Chapter 11: Evidence Routing Before GenAI

Purpose: Explain why routing should happen before probabilistic reasoning.

Concepts:

- Evidence Routing
- Evidence Plan
- Evidence Strategy
- Evidence Frontier
- Deterministic Knowledge
- Trustworthiness

Prerequisites: Chapters 3, 8, 10.

Examples: choose SHAP importance, metrics, diagnostics, calibration for executive question.

Experiments: evidence routing calibration.

Docs: `docs/evidence_routing_policy.md`, `docs/evidence_strategy_ux.md`.

Estimated pages: 30-45.

#### Chapter 12: Context Optimization

Purpose: Explain profiles, constraints, provider capabilities, and context strategy selection.

Concepts:

- Context Optimization
- Context Strategy
- Provider Capability
- Optimization Profile
- Full Table Safety

Prerequisites: Chapter 11.

Examples: minimize tokens, maximize accuracy, local/private, fastest response.

Experiments: context strategy harness.

Docs: `docs/context_optimization_policy.md`.

Estimated pages: 25-40.

#### Chapter 13: Marginal Information Gain

Purpose: Present MIG as the governing optimization principle.

Concepts:

- Marginal Information Gain
- Evidence Sufficiency
- Decision Criticality
- Knowledge Compression
- Stopping Criterion
- Redundancy
- Uncertainty Reduction

Prerequisites: Chapters 10-12.

Examples: critical decision evidence explosion, cheap/local token-saving mode, MMM marginal utility analogy.

Experiments: future MIG scoring/calibration studies.

Docs: `docs/marginal_information_gain_framework.md`.

Estimated pages: 35-60.

### Part VI: GenAI Service And Local-First Intelligence

#### Chapter 14: Provider-Agnostic GenAI

Purpose: Explain local-first provider abstraction and why Agentic Lab should wait.

Concepts:

- GenAI Service
- Provider Adapter
- Provider Capability
- Ollama Adapter
- LM Studio Adapter
- llama.cpp Adapter
- OpenAI-Compatible Endpoint
- Read-only GenAI Use Case

Prerequisites: Chapters 2 and 11.

Examples: summarize artifact, brief project, explain alerts, suggest next action.

Experiments: Ollama smoke test.

Docs: `docs/genai_service_architecture.md`.

Estimated pages: 25-35.

#### Chapter 15: Observability Before Learning

Purpose: Explain why routing decisions, context strategies, provider behavior, and outcomes must be recorded.

Concepts:

- Observability
- Learning
- GenAI Telemetry
- Routing Observability
- QA Signals
- Policy Refinement

Prerequisites: Chapters 10-14.

Examples: telemetry table, response JSON, manual scoring placeholders.

Experiments: manual scoring and future learned routing.

Docs: `docs/evidence_routing_policy.md`, `docs/genai_context_strategy_research.md`.

Estimated pages: 25-40.

### Part VII: Workflow And Modules

#### Chapter 16: Workflow As Product Spine

Purpose: Explain the analytical workflow stages and terminology.

Concepts:

- Workflow Registry
- Module Registry
- EDA
- Feature Engineering
- Model Prep
- Model Readiness
- CatBoost Builder
- Model Assessment
- Model Insights
- SHAP Insights

Prerequisites: Chapters 1 and 3.

Examples: readiness vs assessment terminology migration.

Experiments: module terminology consistency QA.

Docs: `docs/workflow_architecture.md`, `docs/analysis_module_architecture.md`.

Estimated pages: 25-40.

#### Chapter 17: AutoQuant, AutoNLS, And SHAP As Artifact Producers

Purpose: Explain how modeling engines become artifact producers without owning the workstation.

Concepts:

- AutoQuant
- AutoNLS
- SHAP Analysis
- SHAP Interaction Guard
- Effect Curves
- Model Insights
- Service Result

Prerequisites: Chapters 3, 6, 16.

Examples: AutoNLS original-scale API, SHAP interaction diagnostics, effect curve backend controls.

Experiments: AutoNLS raw vs scaled validation, SHAP backend QA.

Docs: `docs/shap_analysis_architecture.md`, corpus workstream ledger.

Estimated pages: 35-55.

### Part VIII: Workstation UX

#### Chapter 18: Why This Is Not A Shiny App

Purpose: Explain the premium workstation philosophy and design system.

Concepts:

- Analytics Workstation
- Workstation Mode
- Dark-first Design System
- Reusable UI Primitives
- Progressive Disclosure
- Command Palette

Prerequisites: Chapter 1.

Examples: VS Code, Lightroom, Figma, Bloomberg, control rooms.

Experiments: UI/UX research sprint and visual QA.

Docs: `docs/ui_ux_architecture.md`, `docs/research/ui_ux_research_sprint.md`.

Estimated pages: 35-55.

#### Chapter 19: Artifact Studio

Purpose: Explain artifacts as browsable evidence and the Evidence Inspector.

Concepts:

- Artifact Studio
- Artifact Gallery
- Artifact Card
- Evidence Inspector
- Artifact Filmstrip
- Artifact Thumbnail

Prerequisites: Chapters 3-6 and 18.

Examples: seeded demo project, real thumbnails, inspector hierarchy.

Experiments: visual QA and demo seed QA.

Docs: Artifact Studio QA/corpus topic UX.

Estimated pages: 25-40.

#### Chapter 20: Mission Control And Command

Purpose: Explain operational project awareness and keyboard-first navigation.

Concepts:

- Mission Control
- Command Palette
- Project Health
- Alert Queue
- Run Timeline
- Workflow Friction

Prerequisites: Chapters 16 and 18.

Examples: dogfooding session, next action clarity.

Experiments: dogfooding and command palette QA.

Docs: `docs/command_palette_architecture.md`, `docs/roadmap/ux_roadmap.md`.

Estimated pages: 25-40.

### Part IX: Engineering The System

#### Chapter 21: Architecture Contracts And QA

Purpose: Explain service results, QA contracts, terminology QA, collector QA, and regression protection.

Concepts:

- Service Result
- QA Contract
- Module Terminology Consistency QA
- Collector QA
- Table Artifact QA
- GenAI QA
- Plot Sizing QA

Prerequisites: All prior architecture chapters.

Examples: interaction guard QA, model readiness alias QA, screenshot path QA.

Experiments: aggregate QA.

Docs: QA functions and docs.

Estimated pages: 30-45.

#### Chapter 22: Book Compiler And Knowledge Products

Purpose: Explain how the project turns its own history into knowledge.

Concepts:

- Codex Corpus
- Source Pack
- Concept Ontology
- Architecture Synthesis
- Book Compiler
- Chapter Mapping

Prerequisites: Entire book.

Examples: raw corpus extraction, topic dossiers, workstream ledger.

Experiments: none; meta-process.

Docs: `docs/book_compiler_plan.md`, corpus files.

Estimated pages: 20-35.

## Appendix Candidates

### Appendix A: Canonical Glossary

Source: `book/source/concept_ontology.md`.

Estimated pages: 20-40.

### Appendix B: Architecture Causality Chains

Source: `book/source/architecture_causality.md`.

Estimated pages: 15-25.

### Appendix C: Experiment Schemas

Source: GenAI experiment harness and telemetry docs.

Estimated pages: 15-25.

### Appendix D: QA Contract Index

Source: QA routines and architecture docs.

Estimated pages: 15-25.

## Concepts Requiring More Source Material Before Chapter Drafting

- Delivery Studio
- Agentic Lab
- Model Landscape
- Learned Routing
- Evidence Sufficiency metrics
- Information Density metrics
- Trustworthiness scoring
- AutoPlots V2 consumer-aware encoding API
- Manual scoring results from GenAI experiments

