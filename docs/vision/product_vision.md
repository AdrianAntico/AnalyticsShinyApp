# Analytics Workstation Product Vision

## Product Identity

Analytics Workstation is an evidence-centered analytical operating environment.

It is not primarily a dashboard.

It is not primarily a Shiny app.

Shiny is the reactive engine: state, orchestration, server communication, and routing. The product identity is larger than the implementation substrate. Analytics Workstation exists to help users create, inspect, preserve, explain, and communicate analytical understanding across an entire project lifecycle.

## Core Thesis

The project is the world.

Modules are producers.

Artifacts are evidence.

The Project Artifact Collector is memory.

AI reasons over evidence.

Human reports and LLM artifacts are different render targets.

The workstation exists to create understanding rather than dashboards.

## Operating Model

Analytics work should feel like moving through one durable project environment:

```text
Project
-> Data
-> Workflow
-> Analysis
-> Artifacts
-> Collector
-> Reports
-> AI
```

Users should not feel like they are jumping between disconnected pages. They should feel like they are switching operational modes inside one analytical environment.

## Workstation Modes

Mission Control, Artifact Studio, and Agentic Lab are Workstation Modes, not standalone pages.

- Mission Control surfaces project health, workflow state, run status, warnings, collector status, QA, and AI readiness.
- Artifact Studio treats artifacts as tangible analytical evidence: searchable, inspectable, comparable, composable, and reportable.
- Agentic Lab allows AI to plan, inspect, explain, and execute over project evidence with preview-before-commit controls.

This mode model is closer to Lightroom modules, IDE workspaces, or professional trading terminals than a traditional web dashboard.

## Architectural Alignment

The product vision reinforces the implemented architecture:

- Artifact Model: all analytical outputs should become standardized artifacts wherever practical.
- Render Targets: human report rendering and LLM DOCX rendering are separate target decisions, not separate analytical truths.
- Project Artifact Collector: project-level evidence aggregation belongs to the project, not individual modules.
- Artifact Quality Policy: every artifact should be evaluated consistently for completeness, metadata, captions, screenshots, tables, diagnostics, recommendations, and JSON where available.
- Table Artifact Architecture: analytical tables are canonical artifacts with policy, preview, sorting metadata, CSV/JSON sidecars, and quality metadata.
- Producer Semantics: artifact producers should declare analytical intent, importance, and policies when they know them.
- Workstation Design System: reusable UI primitives, tokens, dark-first controls, and shared layouts should define UX instead of stock Shiny defaults.
- QA: architectural and UX expectations should be enforced through repeatable QA routines.

## Product Principles

1. Project-first, not page-first.
2. Evidence-first, not chart-first.
3. Artifacts are durable analytical objects, not temporary output.
4. The collector is the canonical project memory.
5. AI must be grounded in artifacts, diagnostics, metadata, and sidecars.
6. Human and LLM render targets optimize for different readers.
7. Defaults should be excellent, but power should remain discoverable.
8. Every important action should be inspectable, replayable, and reversible where practical.
9. Failures should become diagnostics, not dead ends.
10. The system should help users understand the modeling landscape.

## Non-Goals

Analytics Workstation should not evolve into:

- a generic dashboard builder
- a collection of unrelated Shiny tabs
- a report exporter with controls attached
- a chat interface beside static outputs
- a visual skin over unstructured module behavior

## North Star

The user should be able to open a project and immediately understand:

- where they are
- what data and runs exist
- which modules have produced evidence
- which artifacts matter
- what the collector knows
- what warnings remain
- what reports and LLM artifacts are ready
- what the AI can explain or do next

The workstation should make analytical state visible, navigable, and explainable.

