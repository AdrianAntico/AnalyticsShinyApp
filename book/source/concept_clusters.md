# Concept Clusters

This document groups ontology concepts into future book, documentation, GPT knowledge, and software architecture sections. Clusters are not chronology. They are conceptual neighborhoods.

## Cluster 1: Product Identity And Operating Model

Canonical purpose: Define what Analytics Workstation is and what it is not.

Concepts:

- Analytics Workstation
- Evidence-centered analytical operating environment
- Project
- Project Run
- Workstation Mode
- Project Workspace
- Mission Control
- Artifact Studio
- Delivery Studio
- Agentic Lab
- Model Landscape
- Command Palette

Why this cluster exists: The product identity shifted from a Shiny application to an operating environment. This cluster prevents future writing and development from collapsing back into dashboard/page thinking.

Book role: Opens the product narrative after the foundational AI-native thesis.

Maturity: Mixed. Analytics Workstation and Project are foundational; Artifact Studio and Command Palette are stable first versions; Delivery Studio, Agentic Lab, and Model Landscape are speculative.

## Cluster 2: Artifact System

Canonical purpose: Define artifacts as the central unit of analytical evidence.

Concepts:

- Artifact
- Artifact Model
- Artifact Bundle
- Plot Artifact
- Table Artifact
- Narrative Artifact
- Diagnostic Artifact
- Recommendation Artifact
- JSON Artifact
- Artifact Quality Policy
- Artifact Completeness
- Artifact Importance
- Producer Semantics
- Analytical Intent
- Artifact Studio
- Evidence Inspector
- Artifact Filmstrip

Why this cluster exists: The architecture moved from outputs to artifacts. Artifacts became durable, inspectable, collectible, and reasonable.

Book role: Central section after the critique of dashboards, reports, notebooks, and raw data.

Maturity: Strong. Artifact and Collector concepts are foundational; Producer Semantics and Analytical Intent are emerging.

## Cluster 3: Project Memory And Collector

Canonical purpose: Explain how the project owns analytical memory.

Concepts:

- Project Artifact Collector
- Collector Manifest
- Collector DOCX
- Artifact Directory
- Collector Append
- Duplicate Append Protection
- Project Memory
- Module Producer
- Artifact Bundle
- Project Run

Why this cluster exists: Module-specific exports created fragmentation. The collector made the project the owner of accumulated evidence.

Book role: Explains why AI-native analytical systems need memory before they need chat.

Maturity: Stable/foundational.

## Cluster 4: Tables As Analytical Artifacts

Canonical purpose: Treat tables as structured evidence, not visual leftovers.

Concepts:

- Table Artifact
- Table Policy
- Explicit Table Policy
- Inferred Table Policy
- Sort Policy
- Preview View
- CSV Sidecar
- JSON Sidecar
- Table Preview
- Full Table Safety

Why this cluster exists: Tables often carry more precise evidence than plots, but require policies to become useful for LLMs and future renderers.

Book role: A concrete example of turning UI output into evidence architecture.

Maturity: Stable, with research questions around optimal previews.

## Cluster 5: Rendering And Encoding

Canonical purpose: Separate delivery from representation.

Concepts:

- Render Target
- Human Report
- LLM DOCX
- Artifact Studio Preview
- Collector DOCX
- Information Encoding
- Consumer Encoding
- Human Encoding
- LLM Encoding
- Thumbnail Encoding
- Executive Encoding
- Developer Encoding
- Information Density
- Composite Analytical View

Why this cluster exists: The same artifact should be encoded differently for different consumers. Render targets deliver; encodings represent.

Book role: One of the most important conceptual contributions.

Maturity: Render Target is stable; Information Encoding is emerging/research.

## Cluster 6: Evidence And Reasoning

Canonical purpose: Explain how artifacts become evidence for humans and GenAI.

Concepts:

- Evidence
- Evidence Plan
- Evidence Sufficiency
- Evidence Strategy
- Evidence Routing
- Evidence Frontier
- Trustworthiness
- Decision Criticality
- Deterministic Knowledge
- Probabilistic Reasoning

Why this cluster exists: AI-native analytics needs a disciplined bridge between deterministic software and probabilistic reasoning.

Book role: Core theoretical middle section.

Maturity: Evidence and deterministic/probabilistic boundary are foundational; sufficiency/frontier are research.

## Cluster 7: Context Optimization And MIG

Canonical purpose: Define the optimization logic for choosing what to send to GenAI.

Concepts:

- Context Optimization
- Context Strategy
- Optimization Profile
- Marginal Information Gain
- Knowledge Compression
- Information Transfer
- Context Cost
- Redundancy
- Uncertainty Reduction
- Stopping Criterion

Why this cluster exists: Sending everything is wasteful; minimizing tokens alone is naive. The objective is useful marginal information per cost.

Book role: Decision-theory and optimization section.

Maturity: Research, but conceptually central.

## Cluster 8: GenAI Service And Experiments

Canonical purpose: Provide provider abstraction and empirical evaluation of context strategies.

Concepts:

- GenAI Service
- Provider Adapter
- Provider Capability
- Ollama Adapter
- LM Studio Adapter
- llama.cpp Adapter
- OpenAI-Compatible Endpoint
- GenAI Telemetry
- Information Transfer Experiment
- Image-vs-Data Experiment
- Plot-Type-Aware Strategy Study
- Manual Scoring

Why this cluster exists: Local and remote LLM providers should be swappable, and representation choices should be tested empirically.

Book role: Implementation and research infrastructure section.

Maturity: GenAI service is stable; experiments are experimental/research.

## Cluster 9: Observability And Learning

Canonical purpose: Record enough structure for future improvement.

Concepts:

- Observability
- Learning
- Routing Observability
- Experiment Telemetry
- QA Signals
- Policy Refinement
- Strategy Recommendation
- Calibration

Why this cluster exists: The system cannot learn which evidence strategies work unless it records decisions and outcomes.

Book role: Future-facing section connecting software instrumentation to learning systems.

Maturity: Emerging to speculative.

## Cluster 10: AutoPlots And Visualization

Canonical purpose: Preserve production rendering discipline and future visual evolution.

Concepts:

- AutoPlots
- Production Rendering Pipeline
- Production Screenshot Helper
- Plot Sizing Gallery
- Static Plot Sizing
- Composite Analytical View
- ImportancePareto
- AutoPlots V2
- Information Density
- LLM Encoding

Why this cluster exists: Visualizations are key evidence compressors, but QA must use actual production rendering.

Book role: Case study in respecting existing APIs while evolving information transfer.

Maturity: AutoPlots and production rendering are stable; composite/encoding work is emerging.

## Cluster 11: AutoQuant And Modeling Modules

Canonical purpose: Define analytical module producers and workflow semantics.

Concepts:

- AutoQuant
- AutoNLS
- AutoQuant EDA
- Model Readiness
- Model Assessment
- CatBoost Builder
- Model Insights
- SHAP Analysis
- SHAP Interaction Guard
- Effect Curves
- Module Registry
- Workflow Registry

Why this cluster exists: The workstation gets analytical depth from AutoQuant modules and must integrate them through clean adapters and artifact contracts.

Book role: Practical analytics system case study.

Maturity: Mixed. Workflow and readiness are stable; some assessment/AutoNLS directions are emerging.

## Cluster 12: Workflow Architecture

Canonical purpose: Explain the staged analytical lifecycle.

Concepts:

- EDA
- Feature Engineering
- Model Prep
- Model Readiness
- CatBoost Builder
- Model Assessment
- Model Insights
- SHAP Insights
- Report / Export
- Workflow Registry
- Module Registry
- Service Result

Why this cluster exists: The workflow provides the product spine while modes provide operational surfaces.

Book role: Grounds abstract artifact/evidence concepts in actual analytical sequence.

Maturity: Stable.

## Cluster 13: UX And Interaction System

Canonical purpose: Explain how the product should feel and operate.

Concepts:

- Premium Workstation
- Dark-first Design System
- Reusable UI Primitives
- Progressive Disclosure
- Artifact Cards
- Evidence Inspector
- Filmstrip
- Command Palette
- Mission Control
- Dogfooding
- Workflow Friction

Why this cluster exists: The UX philosophy is not decorative; it expresses the product architecture.

Book role: Product design chapter cluster.

Maturity: Emerging/stable.

## Cluster 14: QA And Contracts

Canonical purpose: Protect architecture through named validation routines.

Concepts:

- QA Contract
- Module Terminology Consistency QA
- Artifact Studio QA
- Collector QA
- GenAI Service QA
- GenAI Experiment Harness QA
- Plot Sizing Gallery QA
- Table Artifact Policy QA
- Artifact Quality Policy QA
- SHAP Interaction Guard QA

Why this cluster exists: The system is architecture-heavy; regressions are often conceptual, not only functional.

Book role: Engineering practice section.

Maturity: Stable.

## Cluster 15: Knowledge Products And Book Compiler

Canonical purpose: Turn the work itself into durable knowledge.

Concepts:

- Codex Corpus
- Source Pack
- Concept Ontology
- Architecture Synthesis
- Book Compiler
- Chapter Mapping
- Raw Conversations
- Workstream Ledger
- Topic Dossiers
- Manuscript Render Target
- GPT Knowledge Base

Why this cluster exists: The project generated more architecture than any single thread could hold. Knowledge compilation became part of the system.

Book role: Meta-section or appendix explaining the methodology.

Maturity: Emerging.

