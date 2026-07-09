# Analytics Workstation Guide Architecture

## Purpose

The Analytics Workstation Guide is the human-facing mentor layer of Analytics Workstation.

It helps users understand:

- where they are
- what they have accomplished
- what the project currently knows
- what remains unknown
- what evidence exists
- what evidence is missing
- why a next step is recommended
- how to use the workstation effectively

The Guide is not another GenAI chat. It is an intelligent system guide grounded in the product architecture, ontology, project state, evidence, and workflow.

## Philosophy

The Guide should feel like a senior analytical mentor.

It teaches. It recommends. It explains. It orients. It helps users think.

It does not simply answer arbitrary questions. It does not replace Mission Control. It does not replace Artifact Studio. It does not execute actions. It does not become Agentic Lab.

The Guide embodies the core philosophy of Analytics Workstation:

```text
The project is the world.
Artifacts are evidence.
The Collector is memory.
Knowledge State records what is known and unknown.
Investigation Planning turns questions into plans.
Evidence Routing grounds reasoning.
Context Optimization protects attention and cost.
Execution Mode controls delegation.
GenAI enhances explanation but does not define intelligence.
```

## Core Job

The Guide answers questions that are architectural, contextual, and workflow-oriented:

- What should I do next?
- Why is this module recommended?
- What does this page do?
- What evidence do I already have?
- What evidence is still missing?
- How confident am I?
- Why can't I make a recommendation yet?
- Why is the app suggesting SHAP?
- Why isn't this artifact being routed?
- What does Decision Readiness mean?
- How should I use Analytics Workstation?

The Guide should keep answers grounded in current context. It should not talk as if every project is identical.

## Relationship To The Workstation

The Guide is not a new primary mode like Artifact Studio or Mission Control.

It is a cross-cutting guidance layer available across modes.

It should understand:

- current project
- current page or workstation mode
- current module
- current dataset status
- current artifacts
- collector state
- Knowledge State
- open questions
- decision readiness
- evidence strategy
- execution mode
- running async jobs
- GenAI provider status
- current alerts
- current report/export readiness

The Guide is allowed to recommend transitions between modes, but it should explain why.

Example:

```text
You have generated EDA artifacts but no Model Readiness evidence yet.
The next useful step is Model Readiness because it checks whether the target
and features are suitable before modeling. Expected benefit: identify leakage,
missingness, class imbalance, and readiness blockers. Expected cost: low.
Alternative: inspect EDA artifacts in Artifact Studio first.
```

## Relationship To The Knowledge Library

The Knowledge Library is the authoritative reference surface.

The Guide teaches in context. The Knowledge Library preserves and explains the underlying architecture.

When the Guide introduces a concept, it should be able to link to the Library rather than expanding every explanation inline.

Example:

```text
Guide: Artifacts become evidence when they have provenance, quality, intent,
diagnostics, and relationships.

Actions:
- Open Concept: Artifact
- Read Chapter: Artifacts As Evidence
- Open Architecture: Artifact Model
- Open Related Research
```

This keeps Guide responses concise while preserving depth. The Guide should not try to become the Knowledge Library. The Library should not try to become the contextual mentor.

## Relationship To Mission Control

Mission Control is the operational state center.

The Guide explains that state.

Mission Control answers:

```text
What is happening?
What is healthy?
What is failing?
What needs attention?
```

The Guide answers:

```text
Why does this matter?
What should I do with this state?
What should I inspect next?
What does this imply for the decision?
```

The Guide may appear in Mission Control as a contextual mentor widget, but it should not duplicate every Mission Control tile.

## Relationship To Artifact Studio

Artifact Studio is the evidence browser.

The Guide explains how to interpret and use evidence.

In Artifact Studio, the Guide should help users understand:

- what the selected artifact represents
- why it matters
- whether it is strong or weak evidence
- what caveats apply
- what related artifacts to inspect
- what evidence is missing
- whether the artifact should feed a report, evidence bundle, or decision

The Guide should avoid overwhelming the Evidence Inspector. The inspector remains the artifact dossier; the Guide provides interpretation, orientation, and next-step reasoning.

## Relationship To Project Workspace

Project Workspace is the setup and project-management surface.

The Guide helps users start well.

It should orient users around decision intent rather than software mechanics.

Instead of:

```text
Welcome.
```

It should ask:

```text
What decision are you trying to make?
```

First-run entry paths:

- I have data.
- I have a model.
- I have a business question.
- I have an existing project.
- I want to explore.

Each path should map to a recommended initial workflow.

## Relationship To Knowledge State

Knowledge State answers:

```text
What do we know?
What do we believe?
What are we assuming?
What remains unknown?
What evidence supports each conclusion?
How confident are we?
```

The Guide translates Knowledge State into user-facing explanation.

Example:

```text
We currently know the target distribution and missingness profile.
We do not yet know whether the model drivers are stable or whether SHAP
patterns differ by segment. Decision readiness is preliminary because
post-model evidence has not been generated.
```

The Guide should not invent Knowledge State. It should read from available deterministic state first, then use GenAI only for synthesis when configured.

## Relationship To Investigation Planning

Investigation Planning turns business questions into analytical plans.

The Guide is the natural user-facing surface for explaining those plans.

When a user asks a business question, the Guide should eventually help construct:

- known facts
- unknowns
- hypotheses
- evidence requirements
- required analyses
- required artifacts
- stopping criteria
- decision criteria
- risks
- alternative paths

The Guide should present this progressively. A business user should not be handed an ontology dump. A technical user should be able to open the full reasoning.

## Relationship To Evidence Routing And Context Optimization

Evidence Routing selects relevant evidence.

Context Optimization determines how much and what representation should be used.

The Guide explains both.

It should answer:

- Why was this artifact included?
- Why was this artifact excluded?
- Why was this context strategy chosen?
- Why is a full table not included?
- Why is a screenshot helpful here?
- Why is the system asking for more evidence?

The Guide should follow the principle:

```text
Do not spend probabilistic intelligence on deterministic facts.
```

It should use deterministic metadata and architecture rules whenever possible.

## Relationship To Evidence Strategy

Evidence Strategy controls how much evidence to gather:

- Efficient
- Balanced
- Thorough
- Critical Decision
- Cost Is Irrelevant

The Guide should explain the tradeoff in plain language.

Example:

```text
Balanced is appropriate for routine analysis. It gathers enough evidence
for a defensible recommendation without flooding the context with redundant
artifacts. If this is an executive or high-stakes decision, Critical Decision
may be more appropriate.
```

The Guide should help users choose a strategy based on stakes, cost, time, and uncertainty.

## Relationship To Execution Mode

Execution Mode controls who advances the loop:

- Manual
- Guided
- Assisted
- Autonomous
- Research / Step-by-Step

The Guide adapts its behavior:

| Execution Mode | Guide Behavior |
| --- | --- |
| Manual | Teach and explain options. The user chooses every step. |
| Guided | Recommend the next step and explain why. |
| Assisted | Summarize what the system did and where approval is needed. |
| Autonomous | Provide an audit trail, caveats, and decision-readiness explanation. |
| Research / Step-by-Step | Expose intermediate reasoning, uncertainty, routing, and assumptions. |

This keeps the Guide consistent without changing the underlying product personality.

## Relationship To GenAI

The Guide must work with:

- no GenAI provider
- local GenAI
- paid GenAI
- hybrid future providers

GenAI enhances the Guide. It does not define it.

Without GenAI, the Guide can still:

- explain pages
- explain workflow stage purpose
- summarize deterministic project state
- surface missing evidence
- recommend next modules from deterministic rules
- explain evidence strategy and execution mode
- show links to architecture docs or tooltips

With GenAI, the Guide can additionally:

- synthesize project state into natural language
- explain alerts more fluidly
- summarize selected artifacts
- translate technical diagnostics into business language
- generate a draft investigation plan

The Guide should always disclose when an answer is deterministic versus GenAI-assisted.

## Internal Knowledge Base

The Guide may reason over:

- Manifesto
- Concept Ontology
- Architecture Synthesis
- Knowledge State Architecture
- Investigation Planning Architecture
- Execution Mode / Delegation Policy
- Evidence Routing Policy
- Context Optimization Policy
- Evidence Strategy UX
- GenAI Service Architecture
- current project state
- current artifacts
- collector manifest
- current route/page/module
- current async jobs
- current GenAI provider status

This is not ordinary RAG over random docs. The Guide's internal knowledge should be curated and mapped to the ontology.

## Recommendation Contract

Every Guide recommendation should include:

- recommendation
- reason
- expected benefit
- expected cost
- confidence
- evidence basis
- missing evidence
- alternative paths
- execution implication

Example:

```text
Recommendation: Run Model Readiness.
Reason: You have loaded data and generated EDA, but no readiness evidence exists.
Expected benefit: detect leakage, target issues, missingness, and modeling blockers.
Expected cost: low.
Confidence: high.
Alternative: inspect EDA artifacts first in Artifact Studio.
Execution implication: In Guided mode, ask for approval before running.
```

The Guide should never appear magical.

## First-Run Orientation

First-run orientation should start with user intent, not product features.

Opening prompt:

```text
What decision are you trying to make?
```

Suggested paths:

### I Have Data

Recommended flow:

```text
Data Workspace
-> EDA
-> Model Readiness
-> Artifact Studio
-> Mission Control
```

### I Have A Model

Recommended flow:

```text
Project Workspace
-> Model Assessment
-> Model Insights
-> SHAP
-> Artifact Studio
-> Delivery
```

### I Have A Business Question

Recommended flow:

```text
Guide
-> Investigation Plan
-> Required Evidence
-> Analysis Modules
-> Artifact Studio
-> Decision Readiness
```

### I Have An Existing Project

Recommended flow:

```text
Project Workspace
-> Load Project
-> Mission Control
-> Artifact Studio
-> Delivery
```

### I Want To Explore

Recommended flow:

```text
Data Workspace
-> EDA
-> Artifact Studio
-> Command Palette
```

## UI Placement Options

### Docked Panel

Pros:

- persistent across modes
- feels like a mentor beside the work
- can show context-aware guidance

Cons:

- consumes horizontal space
- may compete with the Evidence Inspector

Best use:

- desktop workstation layout
- collapsible right or left rail

### Collapsible Assistant

Pros:

- low clutter
- available when needed
- works across pages

Cons:

- less visible for first-time users
- may be ignored

Best use:

- experienced users
- keyboard shortcut or command palette integration

### Mission Control Widget

Pros:

- strong connection to project health
- makes Mission Control more actionable
- good for next-step recommendations

Cons:

- less available during artifact inspection
- can make the Guide feel like a status summary only

Best use:

- project start
- daily review
- workflow triage

### Home / First-Run Guide

Pros:

- ideal for onboarding
- frames the product around decisions
- helps prevent blank-page anxiety

Cons:

- not sufficient for ongoing guidance

Best use:

- first project
- empty project
- no data loaded

### Persistent Bottom Guide

Pros:

- aligned with command/status strip patterns
- unobtrusive
- can surface short next-step hints

Cons:

- limited space
- not enough for teaching

Best use:

- lightweight nudges
- execution status
- quick explanations

## Recommended UX Direction

Use a layered Guide:

1. First-run orientation in Project Workspace.
2. Persistent compact Guide cue in the shell or status strip.
3. Collapsible docked Guide panel for deeper explanations.
4. Mission Control Guide widget for next-step recommendations.
5. Contextual Guide hooks in Artifact Studio and Analysis Modules.

This avoids forcing all guidance into one chat box.

## Phase 1 Implementation

Phase 1 implements the first real Guide page and makes it the default landing experience.

Included:

- default `Guide` tab before Mission Control
- welcome and orientation section
- "What are you trying to accomplish today?" framing
- business-question to knowledge to evidence to decision loop
- current workspace summary
- deterministic current recommendation
- primary action cards
- current investigation summary
- workspace health summary
- persistent right-hand Guide panel
- no-GenAI graceful behavior
- future Knowledge Library placeholder
- command palette entry for opening the Guide
- `qa_guide_page()`

Phase 1 deliberately does not implement:

- conversational chat
- Agentic Lab
- autonomous execution
- Knowledge Library UI
- search
- book rendering
- GenAI-dependent reasoning

The deterministic recommendation logic currently uses available project state:

- no project -> start with data or existing project
- data loaded without artifacts -> run EDA
- artifacts without Model Readiness -> run Model Readiness
- model insights without SHAP -> generate SHAP Analysis
- artifacts without collector readiness -> preserve evidence in the Collector
- collector-ready artifacts -> review Artifact Studio
- otherwise -> review Mission Control

This is intentionally conservative. The Guide should earn user trust by explaining simple, deterministic next steps before adding probabilistic reasoning.

## Future Phases

Phase 2 should add contextual Guide hooks in Mission Control, Artifact Studio, Project Workspace, and Analysis Modules. These should explain the current page, selected artifact, current warning, or module recommendation without becoming a chat window.

Phase 3 should integrate the Knowledge Library. Guide explanations should offer stable links such as Open Concept, Read Chapter, Open Architecture, Open Research, and Open Related QA.

Phase 4 should introduce optional GenAI-assisted explanation. GenAI may summarize or rephrase deterministic state, but it should not become the source of truth and should not execute actions.

Phase 5 should connect to Investigation Planning and Knowledge State more deeply. At that point, the Guide can explain business-question plans, hypotheses, knowledge gaps, evidence requirements, and decision readiness.

Phase 6 may support execution-mode-specific guidance:

- Manual: teach and explain
- Guided: recommend and wait for user action
- Assisted: summarize and prepare suggested steps
- Autonomous: audit, preview, and report
- Research: expose detailed reasoning and uncertainty

## Guide Response Levels

The Guide should use progressive disclosure:

### Simple

One sentence:

```text
Run Model Readiness next because you have data but no evidence that the target is safe to model.
```

### Common

Short explanation:

```text
Model Readiness checks leakage, target balance, missingness, and suitability.
It is usually the next step after EDA.
```

### Advanced

Evidence basis:

```text
EDA exists, but readiness artifacts are missing. Collector has no leakage
diagnostics or readiness recommendations. Decision readiness is preliminary.
```

### Developer / Research

Trace:

```text
Recommendation derived from workflow registry, artifact inventory,
collector manifest, and missing readiness module artifacts.
```

## Non-Goals

The Guide does not:

- execute modules
- mutate project state
- replace Mission Control
- replace Artifact Studio
- replace Agentic Lab
- operate as a generic chat bot
- silently promote GenAI output to Knowledge State
- bypass Evidence Routing
- bypass Execution Mode gates
- hide uncertainty

## Success Criteria

The Guide succeeds when:

- first-time users know what to do next
- experienced users understand why the system recommends a step
- project status feels interpretable rather than overwhelming
- artifacts feel connected to decisions
- missing evidence is visible
- Decision Readiness becomes understandable
- users learn the architecture gradually
- GenAI is helpful but not required

The Guide should make Analytics Workstation feel approachable without making it shallow.

It should help users think.
