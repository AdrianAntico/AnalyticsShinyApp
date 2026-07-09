# Concept Dependency Graph

This graph records conceptual dependencies. It is intentionally textual so it can be reviewed, edited, and later rendered into diagrams.

## Primary Architecture Graph

```text
Analytics Workstation
  depends on -> Project
  depends on -> Workstation Modes
  depends on -> Artifact System
  depends on -> Workflow Architecture
  depends on -> GenAI Architecture
  depends on -> QA Contracts

Project
  contains -> Project Runs
  contains -> Project Artifact Collector
  contains -> Collector Manifest
  contains -> Artifact Directory
  contains -> Project State
  feeds -> Mission Control
  feeds -> Artifact Studio
  feeds -> GenAI Briefing

Project Run
  contains -> Module Runs
  produces -> Artifact Bundles
  appends to -> Project Artifact Collector
  records in -> Collector Manifest

Module Producer
  emits -> Service Result
  emits -> Artifact Bundle
  declares -> Producer Semantics
  declares -> Artifact Importance
  declares -> Analytical Intent
  may declare -> Explicit Table Policy

Artifact Bundle
  contains -> Artifact
  contains -> Project Metadata
  contains -> Run Metadata
  contains -> Module Metadata
  submitted to -> Project Artifact Collector

Artifact
  may contain -> Screenshot
  may contain -> Table
  may contain -> Narrative
  may contain -> Diagnostics
  may contain -> Recommendations
  may contain -> JSON Payload
  always should contain -> Caption
  always should contain -> Metadata
  evaluated by -> Artifact Quality Policy
  interpreted as -> Evidence

Artifact Quality Policy
  evaluates -> Completeness
  records -> Missing Components
  records -> Screenshot Status
  records -> Table Status
  records -> JSON Status
  feeds -> Evidence Routing
  feeds -> Artifact Studio
  feeds -> Collector

Table Artifact
  depends on -> Canonical Table
  depends on -> Table Policy
  produces -> Preview Views
  produces -> CSV Sidecar
  produces -> JSON Sidecar
  feeds -> LLM DOCX
  feeds -> GenAI Context Strategy

Evidence
  derived from -> Artifact
  scored by -> Artifact Quality
  scored by -> Trustworthiness
  selected by -> Evidence Routing
  encoded by -> Information Encoding
  packaged into -> Evidence Plan

Information Encoding
  transforms -> Artifact Representation
  specializes into -> Human Encoding
  specializes into -> LLM Encoding
  specializes into -> Thumbnail Encoding
  specializes into -> Executive Encoding
  specializes into -> Developer Encoding
  informs -> Context Strategy
  informs -> AutoPlots V2

Render Target
  delivers -> Encoded Artifact
  includes -> Human Report
  includes -> LLM DOCX
  includes -> Artifact Studio Preview
  includes -> Collector DOCX
  differs from -> Information Encoding

Evidence Routing
  consumes -> Artifact Inventory
  consumes -> Producer Semantics
  consumes -> Artifact Quality
  consumes -> Table Policy
  consumes -> Information Encoding Options
  emits -> Evidence Plan
  precedes -> GenAI Reasoning

Context Optimization
  consumes -> Evidence Plan
  consumes -> Provider Capabilities
  consumes -> Optimization Profile
  consumes -> Decision Criticality
  chooses -> Context Strategy
  governed by -> Marginal Information Gain

Context Strategy
  includes -> Screenshot
  includes -> Caption
  includes -> Metadata
  includes -> Diagnostics
  includes -> Recommendations
  includes -> Table Preview
  includes -> Full Table when safe
  includes -> JSON Summary
  includes -> Sidecar Reference
  records -> Included Components
  records -> Token Estimates
  records -> Latency

Marginal Information Gain
  evaluates -> Additional Evidence Value
  evaluates -> Context Cost
  evaluates -> Redundancy
  evaluates -> Uncertainty Reduction
  evaluates -> Decision Impact
  defines -> Evidence Sufficiency
  defines -> Stopping Criterion

GenAI Service
  abstracts -> Provider Adapters
  exposes -> genai_chat
  exposes -> genai_generate
  exposes -> genai_summarize_artifact
  exposes -> genai_brief_project
  records -> GenAI Telemetry
  depends on -> Context Strategy

Provider Adapter
  declares -> Provider Capabilities
  handles -> Availability Check
  handles -> List Models
  handles -> Chat
  handles -> Generate
  handles -> Response Normalization
  handles -> Timeout/Error Behavior

Observability
  records -> Collector Manifest
  records -> QA Results
  records -> GenAI Telemetry
  records -> Evidence Routing Decisions
  records -> Context Strategy Results
  enables -> Learning

Learning
  consumes -> Observability
  refines -> Evidence Routing
  refines -> Context Optimization
  refines -> Information Encoding Choices
  refines -> Strategy Recommendations
```

## Workstation Mode Dependencies

```text
Workstation Mode
  includes -> Project Workspace
  includes -> Mission Control
  includes -> Artifact Studio
  future includes -> Delivery Studio
  future includes -> Agentic Lab
  future includes -> Model Landscape

Project Workspace
  depends on -> Project State
  depends on -> Data Loading
  depends on -> Collector Status
  launches -> Workflow Modules

Mission Control
  depends on -> Project
  depends on -> Workflow Registry
  depends on -> Collector Manifest
  depends on -> QA/Alert Signals
  optionally displays -> GenAI Provider Status
  future displays -> Evidence Strategy Summary

Artifact Studio
  depends on -> Artifact Inventory
  depends on -> Collector
  depends on -> Artifact Quality Policy
  depends on -> Screenshots
  depends on -> Table Previews
  contains -> Artifact Gallery
  contains -> Evidence Inspector
  contains -> Artifact Filmstrip

Evidence Inspector
  depends on -> Artifact Preview
  depends on -> Caption
  depends on -> Quality Metadata
  depends on -> Diagnostics
  depends on -> Recommendations
  depends on -> Backing Assets

Command Palette
  depends on -> Command Registry
  depends on -> Routing
  launches -> Workstation Modes
  future launches -> Contextual Actions

Delivery Studio
  depends on -> Collector
  depends on -> Render Targets
  depends on -> Information Encoding
  depends on -> Report Plans

Agentic Lab
  depends on -> GenAI Service
  depends on -> Evidence Routing
  depends on -> Context Optimization
  depends on -> Observability
  requires -> Preview Before Commit
```

## Analytics Module Dependencies

```text
Workflow
  includes -> EDA
  includes -> Feature Engineering
  includes -> Model Prep
  includes -> Model Readiness
  includes -> CatBoost Builder
  includes -> Model Assessment
  includes -> Model Insights
  includes -> SHAP Insights
  includes -> Report / Export

Model Readiness
  precedes -> CatBoost Builder
  distinct from -> Model Assessment
  produces -> Readiness Artifacts
  produces -> Recommendations

CatBoost Builder
  depends on -> Model Readiness
  produces -> Model Artifacts
  feeds -> Model Assessment
  feeds -> Model Insights
  feeds -> SHAP Analysis

Model Assessment
  depends on -> Trained/Scored Model
  produces -> Metrics
  produces -> Confusion Matrix
  produces -> Lift/Gain
  produces -> Calibration
  produces -> Residual Diagnostics

Model Insights
  depends on -> Trained Model
  depends on -> AutoPlots API
  produces -> Diagnostic Plots
  produces -> Insight Tables

SHAP Analysis
  depends on -> AutoQuant SHAP
  optionally depends on -> AutoNLS
  produces -> SHAP Importance
  produces -> SHAP Dependence
  produces -> SHAP Interaction Diagnostics
  produces -> Effect Curves

SHAP Interaction Guard
  protects -> SHAP Pipeline
  emits -> Interaction Diagnostics
  prevents -> Optional Interaction Failure From Failing Run
```

## Rendering Dependencies

```text
AutoPlots
  owns -> Production Plot Rendering
  owns -> Theme Defaults
  owns -> Public Plot APIs
  future owns -> Composite Analytical Views

Analytics Workstation
  must call -> AutoPlots Public Functions
  must not call -> echarts4r Directly For Production Plots
  uses -> Production Screenshot Helper

Plot Sizing Gallery
  depends on -> AutoPlots Public Functions
  depends on -> Production Screenshot Helper
  validates -> Static Plot Sizing
  informs -> Information Encoding

ImportancePareto
  depends on -> AutoPlots Composite View Audit
  combines -> Ranked Importance Bars
  combines -> Cumulative Contribution Line
  supports -> Future LLM Encoding
```

## Knowledge Product Dependencies

```text
Codex Corpus
  feeds -> Workstream Ledger
  feeds -> Topic Dossiers
  feeds -> Architecture Synthesis
  feeds -> Concept Ontology

Concept Ontology
  feeds -> Concept Clusters
  feeds -> Chapter Mapping
  feeds -> Duplicate Concepts Review
  feeds -> Architecture Causality
  feeds -> Book Compiler

Book Compiler
  consumes -> Source Packs
  consumes -> Concept Ontology
  consumes -> Architecture Docs
  consumes -> Experiments
  emits -> Manuscript
  emits -> Website
  emits -> GPT Knowledge Base
  emits -> White Papers
  emits -> Talks
```

