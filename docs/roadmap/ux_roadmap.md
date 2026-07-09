# Analytics Workstation UX Roadmap

## Purpose

This roadmap converts the UI/UX Research Sprint into actionable product milestones.

It should evolve over time. It is not a fixed delivery contract. It is a planning document that keeps long-term product direction connected to the codebase.

## Strategic Direction

Analytics Workstation should evolve as one project-centered analytical operating environment with multiple Workstation Modes:

- Mission Control
- Artifact Studio
- Agentic Lab
- Model Landscape
- Report and Evidence Storytelling

These are not ordinary pages. They are operational modes inside one project, similar to Lightroom modules or IDE workspaces.

## Roadmap Summary

| Phase | Theme | Priority | Outcome |
| --- | --- | --- | --- |
| 1 | Shell and Workstation Foundation | P0 | Stable project shell, command/status surface, dark-first controls and tables |
| 2 | Artifact Studio | P0 | Artifacts become tangible, searchable, inspectable evidence |
| 3 | Mission Control | P0 | Project health, workflow state, collector state, QA, warnings, and readiness are visible |
| 4 | Report and Evidence Storytelling | P1 | Artifacts become claims, storylines, reports, and LLM evidence bundles |
| 5 | Agentic Lab | P1 | AI plans, explains, and executes over project evidence with preview-before-commit |
| 6 | Spatial Model Landscape | P2 | Workflow, lineage, model behavior, and risks become spatially navigable |
| 7 | Advanced Workspace Personalization | P2 | Power users can customize layouts, command workflows, and mode presets |

## Phase 1: Shell and Workstation Foundation

### Milestone 1.1: Project Shell

Purpose: establish a stable shell that makes the project feel persistent across modes.

Dependencies:

- Workstation Design System
- existing Project Workspace
- current app routing
- dark-first token system

Expected UX benefit:

- Users remain oriented across the product.
- Project, run, collector, render target, and status are always visible.

Estimated complexity: Medium

Priority: P0

Candidate deliverables:

- top project status bar
- durable left rail
- consistent page/mode headers
- current project/run indicator
- collector status indicator
- AI readiness indicator

### Milestone 1.2: Command Palette

Purpose: provide keyboard-first navigation and action execution.

Dependencies:

- action registry
- module registry
- workflow registry
- artifact registry
- project state accessors

Expected UX benefit:

- Expert users move quickly.
- Beginners can search for capabilities without knowing where they live.
- Every major action starts becoming command-addressable.

Estimated complexity: High

Priority: P0

Candidate deliverables:

- command palette overlay
- commands for navigation, module launch, artifact search, report actions, QA, collector actions
- command history
- keyboard shortcut help

### Milestone 1.3: Bottom Command and Status Strip

Purpose: bring terminal/Bloomberg/IDE-style state and command feedback into the workstation.

Dependencies:

- project shell
- command palette
- project status summary
- run status summary

Expected UX benefit:

- Users can see current state without opening a panel.
- The app feels operational and alive.

Estimated complexity: Medium

Priority: P0

Candidate deliverables:

```text
[Project] [Run] [Data] [Collector] [AI Ready] > command/search
```

### Milestone 1.4: Dark Control and Table Contract

Purpose: prevent stock/light controls and tables from breaking the dark-first workstation.

Dependencies:

- existing CSS tokens
- shared table rendering
- `qa_ui_consistency()`

Expected UX benefit:

- Inputs, buttons, tables, and dropdowns feel native to the workstation.

Estimated complexity: Low

Priority: P0

Status: Implemented foundation. Continue visual QA as new components are added.

## Phase 2: Artifact Studio

### Milestone 2.1: Artifact Gallery

Purpose: make artifacts searchable, filterable, and visually scannable.

Dependencies:

- Artifact Model
- Artifact Quality Policy
- Table Artifact Architecture
- artifact library state
- render target metadata

Expected UX benefit:

- Users can quickly find and understand generated evidence.

Estimated complexity: Medium

Priority: P0

Candidate deliverables:

- artifact cards
- filters by module, run, type, intent, importance, render target, quality
- search by caption, feature, module, artifact id
- empty states and failure states

### Milestone 2.2: Artifact Inspector

Purpose: provide a persistent selected-object inspector for artifacts.

Dependencies:

- Artifact Gallery
- Artifact Quality Policy
- table preview sidecars
- screenshot metadata
- JSON metadata

Expected UX benefit:

- Users can inspect an artifact without losing context.
- Artifacts feel like durable analytical objects.

Estimated complexity: Medium

Priority: P0

Candidate deliverables:

- screenshot preview
- caption
- source module
- run id
- render target
- completeness score
- diagnostics
- recommendations
- backing table preview
- CSV/JSON sidecar links
- actions: explain, compare, add to story, open source run

### Milestone 2.3: Artifact Filmstrip

Purpose: create Lightroom-style persistent access to recent and important artifacts.

Dependencies:

- Artifact Gallery
- Artifact Inspector
- current project artifact summary

Expected UX benefit:

- Generated evidence is always visible and easy to revisit.
- Users can move through artifacts rapidly.

Estimated complexity: Medium

Priority: P0

Candidate deliverables:

- bottom filmstrip
- recent artifacts
- pinned artifacts
- warning badges
- quality badges
- click-to-inspect behavior

### Milestone 2.4: Artifact Compare

Purpose: compare equivalent artifacts across runs, modules, or model versions.

Dependencies:

- artifact lineage metadata
- run ids
- artifact intent/type metadata
- screenshot/table rendering

Expected UX benefit:

- Users can understand what changed between iterations.

Estimated complexity: High

Priority: P1

Candidate deliverables:

- side-by-side artifact comparison
- metric deltas
- table diffs
- run A vs run B selector

## Phase 3: Mission Control

Status: Phase 1 implemented as the operational awareness mode. The current implementation provides project health tiles, workflow/system status, collector and AI readiness, an alert/open-decision queue, and a recent run timeline. Future iterations should replace reconstructed timeline signals with durable run-history events and make alert resolution interactive.

### Milestone 3.1: Project Health Center

Purpose: surface the state of the entire project in one operational mode.

Dependencies:

- project state summary
- workflow registry
- collector summary
- artifact quality summary
- QA summaries

Expected UX benefit:

- Users immediately know what is complete, failing, skipped, or waiting.

Estimated complexity: Medium

Priority: P0

Candidate deliverables:

- data health
- workflow health
- artifact health
- collector health
- report readiness
- AI readiness
- warnings and failures

Implemented foundation:

- health tiles for project, collector, AI readiness, artifact quality, workflow coverage, reports, warnings, and QA
- workflow-derived system status board
- collector and manifest readiness indicators

### Milestone 3.2: Run Timeline

Purpose: show project activity over time.

Dependencies:

- run ids
- module result records
- collector manifest
- artifact timestamps

Expected UX benefit:

- Users can reconstruct what happened and when.

Estimated complexity: Medium

Priority: P0

Candidate deliverables:

- timeline entries for uploads, module runs, artifact additions, collector writes, exports
- run status badges
- warning/error annotations
- click-to-open related artifacts

Implemented foundation:

- compact timeline reconstructed from current data state, artifact timestamps, and collector availability
- empty state for projects without activity
- visual timeline component ready for permanent run history

### Milestone 3.3: Alert and Decision Queue

Purpose: separate unresolved analytical decisions from passive diagnostics.

Dependencies:

- Artifact Quality Policy
- readiness diagnostics
- model insights diagnostics
- SHAP diagnostics
- QA outputs

Expected UX benefit:

- Users know what still requires judgment.

Estimated complexity: Medium

Priority: P1

Candidate deliverables:

- leakage warnings
- missingness warnings
- sparse segment warnings
- failed screenshot warnings
- incomplete artifact warnings
- open decisions
- dismissed/accepted states

Implemented foundation:

- prioritized queue for missing evidence, collector gaps, manifest gaps, and artifact quality warnings
- healthy empty state when no open decisions are detected
- alert cards designed for future resolution/dismissal behavior

## Phase 4: Report and Evidence Storytelling

### Milestone 4.1: Evidence Storyline Builder

Purpose: let users organize artifacts into narrative sections.

Dependencies:

- Artifact Studio
- report plan architecture
- Artifact Quality Policy
- render targets

Expected UX benefit:

- Reports become curated evidence narratives rather than raw output dumps.

Estimated complexity: High

Priority: P1

Candidate deliverables:

- drag artifacts into sections
- claim/evidence structure
- caveat callouts
- human vs LLM render target preview

### Milestone 4.2: Evidence Bundles

Purpose: group artifacts around analytical questions or claims.

Dependencies:

- artifact tags/intents
- report plan architecture
- Project Artifact Collector

Expected UX benefit:

- Users can build focused bundles such as “production risk,” “feature effects,” or “data quality.”

Estimated complexity: Medium

Priority: P1

Candidate deliverables:

- named evidence bundles
- bundle quality score
- bundle export to report/collector
- AI explain bundle action

### Milestone 4.3: Render Target Preview

Purpose: make human report vs LLM DOCX differences visible before export.

Dependencies:

- Render Target Architecture
- Project Artifact Collector
- report plan architecture

Expected UX benefit:

- Users understand what each audience will receive.

Estimated complexity: Medium

Priority: P1

Candidate deliverables:

- human report preview
- LLM DOCX preview summary
- artifact completeness warnings
- missing screenshot/table/JSON indicators

## Phase 5: Agentic Lab

### Milestone 5.1: AI Plan Panel

Purpose: allow AI to propose grounded analytical plans before execution.

Dependencies:

- artifact search/indexing
- project summary
- module registry
- command/action registry
- AI policy/permissions

Expected UX benefit:

- AI becomes controlled and inspectable instead of a free-floating chat box.

Estimated complexity: High

Priority: P1

Candidate deliverables:

- proposed plan steps
- required data/artifacts
- expected outputs
- editable plan
- run step/run all controls

### Milestone 5.2: Evidence Grounding Panel

Purpose: show which artifacts, diagnostics, tables, and metadata AI used.

Dependencies:

- Artifact Studio
- Project Artifact Collector
- JSON/table sidecars
- AI response metadata

Expected UX benefit:

- Users can trust and audit AI outputs.

Estimated complexity: High

Priority: P1

Candidate deliverables:

- cited artifacts
- cited tables
- cited diagnostics
- confidence/status badges
- missing evidence notices

### Milestone 5.3: Agent Trace and Preview-Before-Commit

Purpose: make AI actions transparent and reversible.

Dependencies:

- Code Runner policy
- action registry
- service_result contracts
- artifact acceptance flow

Expected UX benefit:

- Users keep control while AI accelerates work.

Estimated complexity: High

Priority: P1

Candidate deliverables:

- agent trace
- proposed artifacts
- accept/reject outputs
- run isolation
- generated memo preview

## Phase 6: Spatial Model Landscape

### Milestone 6.1: Workflow Graph

Purpose: visualize lifecycle progress and dependencies.

Dependencies:

- workflow registry
- module registry
- artifact summaries
- collector manifest

Expected UX benefit:

- Users see the analytical lifecycle as a navigable system.

Estimated complexity: High

Priority: P2

Candidate deliverables:

- nodes for stages
- status by stage
- artifact counts
- warnings by stage
- click-to-open mode/action

### Milestone 6.2: Artifact Lineage Graph

Purpose: show how data, modules, artifacts, reports, and collector outputs relate.

Dependencies:

- artifact lineage metadata
- Project Artifact Collector manifest
- producer semantics

Expected UX benefit:

- Users can audit where evidence came from.

Estimated complexity: High

Priority: P2

Candidate deliverables:

- data -> module -> artifact -> collector -> report lineage
- selected artifact neighborhood
- run diff overlay

### Milestone 6.3: Model Landscape Map

Purpose: create a high-level spatial view of model behavior, risks, and evidence.

Dependencies:

- model assessment artifacts
- SHAP artifacts
- effect curves
- readiness diagnostics
- artifact intents and importance

Expected UX benefit:

- Users can navigate from whole-project understanding to feature-level evidence.

Estimated complexity: Very High

Priority: P2

Candidate deliverables:

- feature/risk/performance/effect regions
- heat/status encoding
- zoom/drilldown
- inspector integration

## Phase 7: Advanced Workspace Personalization

### Milestone 7.1: Workspace Layout Presets

Purpose: support different working styles without fragmenting the product.

Dependencies:

- shell
- modes
- panel system
- local/user settings

Expected UX benefit:

- Analysts, developers, QA users, and executives can each start from useful layouts.

Estimated complexity: Medium

Priority: P2

Candidate deliverables:

- Analyst layout
- Builder layout
- QA layout
- AI Review layout
- Executive Review layout

### Milestone 7.2: Saved Commands and Macros

Purpose: let users preserve repeated workflows.

Dependencies:

- command palette
- action registry
- workflow registry
- project state serialization

Expected UX benefit:

- Repeated analyses become faster and more reproducible.

Estimated complexity: High

Priority: P2

Candidate deliverables:

- saved command sequences
- parameterized commands
- replay with preview
- export as R code

## Implementation Guardrails

- Do not implement mode-specific logic that bypasses the Artifact Model.
- Do not make AI outputs ungrounded or unauditable.
- Do not create duplicate artifact or table rendering paths.
- Do not regress human report or LLM DOCX render targets.
- Do not use stock Shiny defaults where they visibly break the workstation design system.
- Do not treat Mission Control, Artifact Studio, or Agentic Lab as isolated pages with disconnected state.

## Roadmap Maintenance

Update this roadmap when:

- new UX research changes product direction
- architecture creates or removes constraints
- a milestone is implemented
- QA reveals a recurring UX regression
- a new workstation mode becomes necessary
